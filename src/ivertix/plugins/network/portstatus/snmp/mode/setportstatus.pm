#
# Copyright 2022 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Authors : Roman Morandell - i-Vertix
#

package ivertix::plugins::network::portstatus::snmp::mode::setportstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

sub set_oids_status {
    my ($self, %options) = @_;

    $self->{oid_adminstatus} = '.1.3.6.1.2.1.2.2.1.7';
    $self->{oid_adminstatus_mapping} = {
        1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown'
    };
    $self->{adminstatus_value_mapping} = {
        'up' => 1, 'down' => 2
    };
}

sub check_oids_label {
    my ($self, %options) = @_;

    foreach (('oid_filter', 'oid_display')) {
        $self->{option_results}->{$_} = lc($self->{option_results}->{$_}) if (defined($self->{option_results}->{$_}));
        if (!defined($self->{oids_label}->{$self->{option_results}->{$_}})) {
            my $label = $_;
            $label =~ s/_/-/g;
            $self->{output}->add_option_msg(short_msg => "Unsupported oid in --" . $label . " option.");
            $self->{output}->option_exit();
        }
    }
}

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'ifdesc'  => '.1.3.6.1.2.1.2.2.1.2',
        'ifalias' => '.1.3.6.1.2.1.31.1.1.1.18',
        'ifname'  => '.1.3.6.1.2.1.31.1.1.1.1'
    };
}

sub default_oid_filter_name {
    my ($self, %options) = @_;

    return 'ifname';
}

sub default_oid_display_name {
    my ($self, %options) = @_;

    return 'ifname';
}

sub is_admin_status_down {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{use_adminstatus}) && defined($options{admin_status}) &&
        $self->{oid_adminstatus_mapping}->{$options{admin_status}} ne 'up') {
        return 1;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => defined($options{package}) ? $options{package} : __PACKAGE__, %options);
    bless $self, $class;

    $self->{no_speed} = defined($options{no_speed}) && $options{no_speed} =~ /^[01]$/ ? $options{no_speed} : 0;
    $options{options}->add_options(arguments => {
        'name'                  => { name => 'use_name' },
        'interface:s'           => { name => 'interface' },
        'filter-admin-status:s' => { name => 'filter_admin_status' },
        'skip-speed0'           => { name => 'skip_speed0' },
        'oid-filter:s'          => { name => 'oid_filter', default => $self->default_oid_filter_name() },
        'oid-display:s'         => { name => 'oid_display', default => $self->default_oid_display_name() },
        'log-file:s'            => { name => 'log_file' },
        'set-admin-status:s'          => { name => 'set_admin_status' }
    });

    $self->{interface_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->set_oids_label();
    $self->check_oids_label();
    $self->set_oids_status();

    $self->{extra_oids} = {};
    foreach (@{$self->{option_results}->{add_extra_oid}}) {
        next if ($_ eq '');
        my ($name, $oid, $matching) = split /,/;
        $matching = '%{instance}$' if (!defined($matching));
        if (!defined($oid) || $oid !~ /^(\.\d+){1,}$/ || $name eq '') {
            $self->{output}->add_option_msg(short_msg => "Wrong syntax for add-extra-oid '" . $_ . "' option.");
            $self->{output}->option_exit();
        }
        $self->{extra_oids}->{$name} = { oid => $oid, matching => $matching };
    }

    if (!defined($self->{option_results}->{set_admin_status}) || $self->{option_results}->{set_admin_status} eq '') {
        $self->{output}->add_option_msg(short_msg =>
            "Option 'set-status' must be set with value 'up' or 'down'");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{set_admin_status} ne 'up' && $self->{option_results}->{set_admin_status} ne 'down') {
        $self->{output}->add_option_msg(short_msg =>
            "Option 'set-status' can have only value 'up' or 'down'");
        $self->{output}->option_exit();
    }
}


sub get_interfaces {
    my ($self, %options) = @_;

    $self->set_oids_label();
    $self->set_oids_status();

    my $oids = [ { oid => $self->{oids_label}->{$self->{option_results}->{oid_filter}} } ];

    $self->{datas} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids);
    $self->{datas}->{all_ids} = [];

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oids_label}->{$self->{option_results}->{oid_filter}} }})) {
        next if ($key !~ /^$self->{oids_label}->{$self->{option_results}->{oid_filter}}\.(.*)$/);
        $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $1} = $self->{output}->decode($self->{results}->{$self->{oids_label}->{ $self->{option_results}->{oid_filter}} }->{$key});
        push @{$self->{datas}->{all_ids}}, $1;
    }

    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        die("Can't get interfaces...");
    }

    foreach (@{$self->{datas}->{all_ids}}) {
        my $filter_name = $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $_};
        next if (!defined($filter_name));

        if (!defined($self->{option_results}->{interface})) {
            push @{$self->{interface_id_selected}}, $_;
            next;
        }
        if ($filter_name =~ /$self->{option_results}->{interface}/) {
            push @{$self->{interface_id_selected}}, $_;
        }
    }

    if (scalar(@{$self->{interface_id_selected}}) <= 0 && !defined($options{disco})) {
        die('No entry found');
    }

    $oids = [];
    push @$oids, $self->{oid_adminstatus} if (defined($self->{oid_adminstatus}));

    $self->{snmp}->load(oids => $oids, instances => $self->{interface_id_selected});
    my $result = $self->{snmp}->get_leef();

    my $interfaces = [];
    my $log = "";
    foreach my $id (@{$self->{interface_id_selected}}) {
        my $interface = {};
        $interface->{id} = $id;
        $interface->{name} = $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $id};

        if (defined($self->{option_results}->{filter_admin_status}) && defined($result->{$self->{oid_adminstatus} . "." . $id}) &&
            $self->{oid_adminstatus_mapping}->{$result->{$self->{oid_adminstatus} . "." . $id}} !~ /$self->{option_results}->{filter_admin_status}/i) {
            my $msg = "skipping interface '" . $interface->{name} . "': no matching filter admin-status";
            $self->{output}->output_add(long_msg => $msg);
            $log .= strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $msg\n";
            next;
        }

        $interface->{admin_status_oid} = $self->{oid_adminstatus} . ".$id";
        $interface->{admin_status} = $self->{oid_adminstatus_mapping}->{$result->{$interface->{admin_status_oid}}};

        push(@$interfaces, $interface);
    }

    if (defined($self->{option_results}->{log_file}) && $self->{option_results}->{log_file}) {
        open FILE, '>>', $self->{option_results}->{log_file};
        print FILE $log;
        close FILE;
    }

    return $interfaces;
}

sub set_port_status($) {
    my $self = shift;
    my ($interfaces) = @_;
    my $log = "";

    my $new_admin_status = $self->{adminstatus_value_mapping}->{$self->{option_results}->{set_admin_status}};

    foreach my $interface (@{$interfaces}) {
        my $msg = "Trying to set Interface $interface->{name} from admin status $interface->{admin_status} to status $self->{option_results}->{set_admin_status} ($new_admin_status)";

        $self->{output}->output_add(long_msg => $msg);
        $log .= strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $msg\n";

        my $oids2set = {};
        $oids2set->{$interface->{admin_status_oid}} = { value => $new_admin_status, type => 'INTEGER' };
        $self->{snmp}->set(oids => $oids2set, dont_quit => 1);

        if ($self->{snmp}->{error_status} == -1) {
            $self->{output}->output_add(long_msg => $self->{snmp}->{error_msg});
            $log .= strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $self->{snmp}->{error_msg}\n";
            next;
        }

        $msg = "Interface $interface->{name} set successfully to status $self->{option_results}->{set_admin_status} ($new_admin_status)";
        $log .= strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $msg\n";
        $self->{output}->output_add(long_msg => $msg);
    }

    if (defined($self->{option_results}->{log_file}) && $self->{option_results}->{log_file}) {
        open FILE, '>>', $self->{option_results}->{log_file};
        print FILE $log;
        close FILE;
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $interfaces = $self->get_interfaces();
    $self->set_port_status($interfaces);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}


1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--skip-speed0>

Don't display interface with speed 0.

=item B<--filter-admin-status>

Display interfaces matching the filter (example: 'up').

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Choose OID used to display interface in log file (default: ifName) (values: ifDesc, ifAlias, ifName).

=item B<--oid-display>

Log File to write plugin output.

=item B<--set-admin-status>

Sets the new admin-status of all filtered interfaces

=back

=cut
