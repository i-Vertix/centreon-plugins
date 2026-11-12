#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::zerto::zvm::restapi::mode::listvms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_vpg_status $map_vpg_substatus $map_vpg_priority);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s'   => { name => 'include_name', default => '' },
        'exclude-name:s'   => { name => 'exclude_name', default => '' },
        'include-vpg:s'    => { name => 'include_vpg', default => '' },
        'exclude-vpg:s'    => { name => 'exclude_vpg', default => '' },
        'include-vpg-id:s' => { name => 'include_vpg_id', default => '' },
        'exclude-vpg-id:s' => { name => 'exclude_vpg_id', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my @labels = ('id', 'name', 'vpg_id', 'vpg_name', 'status', 'substatus', 'priority');

sub manage_selection {
    my ($self, %options) = @_;

    my $vms = $options{custom}->get_vms();

    my $results = [];
    foreach my $vm (@$vms) {
        my $id = $vm->{VmIdentifier} // '';
        my $name = $vm->{VmName} || $id;
        my $vpg_id = $vm->{VpgIdentifier} // '';
        my $vpg_name = $vm->{VpgName} || $vpg_id;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($vpg_name, $self->{option_results}->{include_vpg}, $self->{option_results}->{exclude_vpg}, output => $self->{output});
        next if is_excluded($vpg_id, $self->{option_results}->{include_vpg_id}, $self->{option_results}->{exclude_vpg_id}, output => $self->{output});

        # a VM protected in several VPGs is listed once per VPG
        push @$results, {
            id        => $id,
            name      => $name,
            vpg_id    => $vpg_id,
            vpg_name  => $vpg_name,
            status    => enum_name(value => $vm->{Status}, map => $map_vpg_status),
            substatus => enum_name(value => $vm->{SubStatus}, map => $map_vpg_substatus),
            priority  => enum_name(value => $vm->{Priority}, map => $map_vpg_priority)
        };
    }

    return [ sort { $a->{name} cmp $b->{name} || $a->{vpg_name} cmp $b->{vpg_name} } @$results ];
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg =>
            join('', map('[' . $_ . ': ' . $entry->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List VMs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $entry (@$results) {
        $self->{output}->add_disco_entry(%$entry);
    }
}

1;

__END__

=head1 MODE

List the virtual machines protected by Zerto.
A VM protected in several VPGs is listed once per VPG.

=over 8

=item B<--include-name>

Filter VMs by name (can be a regexp).

=item B<--exclude-name>

Exclude VMs by name (can be a regexp).

=item B<--include-vpg>

Filter VMs by VPG name (can be a regexp).

=item B<--exclude-vpg>

Exclude VMs by VPG name (can be a regexp).

=item B<--include-vpg-id>

Filter VMs by VPG ID (can be a regexp).

=item B<--exclude-vpg-id>

Exclude VMs by VPG ID (can be a regexp).

=back

=cut
