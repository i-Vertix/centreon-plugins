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

package cloud::sangfor::scp::vm::mode::network;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values :unit_conversion);
use cloud::sangfor::scp::vm::mode::resources qw(get_vms);

sub prefix_vm_output {
    my ($self, %options) = @_;
    return "VM '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All VMs network traffic are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{vms} = [
        { label => 'traffic-in', nlabel => 'vm.network.traffic.in.bitspersecond', set => {
                key_values          => [ { name => 'in' }, { name => 'name' } ],
                output_template     => 'traffic in: %.2f %s/s',
                output_change_bytes => CONVERT_NETWORK,
                perfdatas           => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'vm.network.traffic.out.bitspersecond', set => {
                key_values          => [ { name => 'out' }, { name => 'name' } ],
                output_template     => 'traffic out: %.2f %s/s',
                output_change_bytes => CONVERT_NETWORK,
                perfdatas           => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'id:s'               => { name => 'id', default => '' },
        'resource-pool-id:s' => { name => 'resource_pool_id', default => '' },
        'include-name:s'     => { name => 'include_name', default => '' },
        'exclude-name:s'     => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vms} = {};
    foreach my $entry (@{get_vms(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}) {
        $self->{vms}->{$entry->{id}} = { name => $entry->{name}, %{$entry->{network}} };
    }
}

1;

__END__

=head1 MODE

Check the network traffic of virtual machines (values computed by the platform).

=over 8

=item B<--id>

Define the ID of the virtual machine to check (only one API request is needed).

=item B<--resource-pool-id>

Only check the VMs of this resource pool ID.

=item B<--include-name>

Filter VMs by name (can be a regexp).

=item B<--exclude-name>

Exclude VMs by name (can be a regexp).

=item B<--warning-traffic-in>

Threshold for the inbound traffic (in b/s).

=item B<--critical-traffic-in>

Threshold for the inbound traffic (in b/s).

=item B<--warning-traffic-out>

Threshold for the outbound traffic (in b/s).

=item B<--critical-traffic-out>

Threshold for the outbound traffic (in b/s).

=back

=cut
