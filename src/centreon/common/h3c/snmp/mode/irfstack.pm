#
# Copyright 2023 Centreon (http://www.centreon.com/)
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
#

package centreon::common::h3c::snmp::mode::irfstack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_member_status_output {
    my ($self, %options) = @_;

    return sprintf('role: %s', $self->{result_values}->{role});
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};

    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub custom_port_status_output {
    my ($self, %options) = @_;

    return sprintf('status: %s [%s]', $self->{result_values}->{port_status}, $self->{result_values}->{port_enabled});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name                 => 'member',
            type               => 3,
            cb_prefix_output   => 'prefix_member_output',
            cb_long_output     => 'member_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All stack members are ok',
            group              =>
                [
                    { name => 'member_global', type => 0, skipped_code => { -10 => 1 } },
                    { name               => 'port',
                        display_long     => 1,
                        cb_prefix_output => 'prefix_port_output',
                        message_multiple => 'All ports are ok',
                        type             => 1,
                        skipped_code     => { -10 => 1 } }
                ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'members-total', nlabel => 'stack.members.total.count', set => {
            key_values      => [ { name => 'members' } ],
            output_template => 'Total members: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{member_global} = [
        { label => 'member-status', threshold => 0, set => {
            key_values                     => [ { name => 'role' }, { name => 'display' } ],
            closure_custom_calc            => $self->can('custom_member_status_calc'),
            closure_custom_output          => $self->can('custom_member_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold,
        }
        },
        { label => 'stack-ports', nlabel => 'stack.ports.count', set => {
            key_values      => [ { name => 'stack_ports' }, { name => 'stack_ports_max' } ],
            output_template => 'Stack ports: %s',
            perfdatas       => [
                { template => '%s', min => 0, max => 'stack_ports_max', label_extra_instance => 1 }
            ]
        }
        },
    ];

    $self->{maps_counters}->{port} = [
        { label => 'port-status', threshold => 0, set => {
            key_values                     =>
                [ { name => 'port_status' }, { name => 'port_enabled' }, { name => 'display' } ],
            closure_custom_calc            => \&catalog_status_calc,
            closure_custom_output          => $self->can('custom_port_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold,
        }
        },
    ];
}

sub member_long_output {
    my ($self, %options) = @_;

    return sprintf(
        'checking stack member: %s [%s]',
        $options{instance_value}->{display},
        $options{instance_value}->{member_global}->{role}
    );
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Stack member '" . $options{instance_value}->{display} . "' ";
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return "port '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-member-status:s'  => { name => 'unknown_member_status', default => '' },
        'warning-member-status:s'  => { name => 'warning_member_status', default => '' },
        'critical-member-status:s' => { name => 'critical_member_status', default => '%{role} ne %{roleLast}' },
        'unknown-port-status:s'    => { name => 'unknown_port_status', default => '' },
        'warning-port-status:s'    => { name => 'warning_port_status', default => '' },
        'critical-port-status:s'   => {
            name    => 'critical_port_status',
            default => '%{port_enabled} eq "enabled" and %{port_status} ne "up"'
        },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_member_status', 'warning_member_status', 'critical_member_status',
            'unknown_port_status', 'warning_port_status', 'critical_port_status'
        ]
    );
}

my $map_port_enabled = {
    1 => 'disabled',
    2 => 'enabled'
};

my $map_port_status = {
    1 => 'up',
    2 => 'down',
    3 => 'silent',
    4 => 'disabled'
};

my $map_board_role = {
    1 => 'slave',
    2 => 'master',
    3 => 'loading',
    4 => 'other'
};

my $mapping_member_table = {
    stackMemberID   => { oid => '.1.3.6.1.4.1.25506.2.91.2.1.1' },# hh3cStackMemberID
    stackPortNum    => { oid => '.1.3.6.1.4.1.25506.2.91.2.1.4' },# hh3cStackPortNum
    stackPortMaxNum => { oid => '.1.3.6.1.4.1.25506.2.91.2.1.5' },# hh3cStackPortMaxNum
};

my $mapping_port_table = {
    stackPortEnabled => { oid => '.1.3.6.1.4.1.25506.2.91.4.1.2', map => $map_port_enabled },# hh3cStackPortEnable
    stackPortStatus  => { oid => '.1.3.6.1.4.1.25506.2.91.4.1.3', map => $map_port_status }# hh3cStackPortStatus
};

my $mapping_board_config_table = {
    stackBoardRole   => { oid => '.1.3.6.1.4.1.25506.2.91.3.1.1', map => $map_board_role },# hh3cStackBoardRole
    stackBoardMember => { oid => '.1.3.6.1.4.1.25506.2.91.3.1.2' }# hh3cStackBoardBelongtoMember
};

my $oid_member_table_entry = '.1.3.6.1.4.1.25506.2.91.2.1';# hh3cStackDeviceConfigEntry
my $oid_port_info_entry = '.1.3.6.1.4.1.25506.2.91.4.1';# hh3cStackPortInfoEntry
my $oid_stack_board_config_entry = '.1.3.6.1.4.1.25506.2.91.3.1';# hh3cStackBoardConfigEntry

sub manage_selection {
    my ($self, %options) = @_;

    $self->{member} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $oid_member_table_entry },
            { oid => $mapping_member_table->{stackMemberID}->{oid} },
            { oid => $mapping_member_table->{stackPortNum}->{oid} },
            ,
            { oid => $oid_port_info_entry },
            { oid => $mapping_port_table->{stackPortEnabled}->{oid} },
            { oid => $mapping_port_table->{stackPortStatus}->{oid} },
            ,
            { oid => $oid_stack_board_config_entry },
            { oid => $mapping_board_config_table->{stackBoardRole}->{oid} },
            { oid => $mapping_board_config_table->{stackBoardMember}->{oid} },
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result->{$oid_member_table_entry}}) {
        next if ($oid !~ /^$mapping_member_table->{stackMemberID}->{oid}\.(.*)$/);
        my $instance_id = $1;
        my $member_result = $options{snmp}->map_instance(
            mapping  => $mapping_member_table,
            results  => $snmp_result->{$oid_member_table_entry},
            instance => $instance_id);

        my $role;
        foreach (keys %{$snmp_result->{$oid_stack_board_config_entry}}) {
            next if (!/^$mapping_board_config_table->{stackBoardMember}->{oid}\.(.*?)$/);
            $instance_id = $1;
            my $board_result = $options{snmp}->map_instance(
                mapping  => $mapping_board_config_table,
                results  => $snmp_result->{$oid_stack_board_config_entry},
                instance => $instance_id);

            if ($member_result->{stackMemberID} eq $board_result->{stackBoardMember}) {
                $role = $board_result->{stackBoardRole};
                last;
            }
        }

        $self->{global}->{members}++;
        $self->{member}->{$member_result->{stackMemberID}} = {
            display       => $member_result->{stackMemberID},
            member_global => {
                display         => $member_result->{stackMemberID},
                stack_ports     => $member_result->{stackPortNum},
                stack_ports_max => $member_result->{stackPortMaxNum},
                role            => $role
            },
            port          => {},
        };

        foreach (keys %{$snmp_result->{$oid_port_info_entry}}) {
            next if (!/^$mapping_port_table->{stackPortStatus}->{oid}\.(.*)$/);

            $instance_id = $1;
            my ($stack_member, $port) = $instance_id =~ /^(\d+)\.(\d+)/;
            next if defined $stack_member && $stack_member != $member_result->{stackMemberID};

            my $port_results = $options{snmp}->map_instance(
                mapping  => $mapping_port_table,
                results  => $snmp_result->{$oid_port_info_entry},
                instance => $instance_id);

            $self->{member}->{$member_result->{stackMemberID}}->{port}->{$instance_id} = {
                display      => $port,
                port_enabled => $port_results->{stackPortEnabled},
                port_status  => $port_results->{stackPortStatus},
            };
        }
    }

    $self->{cache_name} = "h3c_" . $self->{mode} . '_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check stack members.

=over 8

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN (Default: '').
You can use the following variables: %{role}, %{roleLast}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING (Default: '').
You can use the following variables: %{role}, %{roleLast}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{role} ne %{roleLast}').
You can use the following variables: %{role}, %{roleLast}

=item B<--unknown-port-status>

Define the conditions to match for the status to be UNKNOWN (Default: '').
You can use the following variables: %{port_enabled}, %{port_status}, %{display}

=item B<--warning-port-status>

Define the conditions to match for the status to be WARNING (Default: '').
You can use the following variables: %{port_enabled}, %{port_status}, %{display}

=item B<--critical-port-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{port_enabled} eq "enabled" and %{port_status} ne "up"').
You can use the following variables: %{port_enabled}, %{port_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-total'.

=back

=cut
