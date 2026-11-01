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

package cloud::sangfor::scp::vm::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(change_seconds);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use cloud::sangfor::scp::vm::mode::resources qw(get_vms);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status: %s, power state: %s, alarm: %s',
        $self->{result_values}->{status},
        $self->{result_values}->{power_state},
        $self->{result_values}->{alarm}
    );
    $msg .= ', warning: ' . $self->{result_values}->{warning}
        if $self->{result_values}->{warning} ne 'no';
    return $msg;
}

sub custom_uptime_output {
    my ($self, %options) = @_;

    return 'uptime: ' . ($self->{result_values}->{uptime} > 0 ? change_seconds(value => $self->{result_values}->{uptime}) : '0s');
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    return "VM '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vms', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All VMs are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{vms} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{power_state} ne "on"',
            set              => {
                key_values                     => [ { name => 'id' }, { name => 'name' }, { name => 'status' }, { name => 'power_state' }, { name => 'alarm' }, { name => 'warning' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'uptime', nlabel => 'vm.uptime.seconds', set => {
                key_values            => [ { name => 'uptime' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'name' }
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

    $self->{vms} = {
        map { $_->{id} => $_ } @{get_vms(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}
    };
}

1;

__END__

=head1 MODE

Check the status and the uptime of virtual machines.

=over 8

=item B<--id>

Define the ID of the virtual machine to check (only one API request is needed).

=item B<--resource-pool-id>

Only check the VMs of this resource pool ID.

=item B<--include-name>

Filter VMs by name (can be a regexp).

=item B<--exclude-name>

Exclude VMs by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{power_state}>, C<%{alarm}>, C<%{warning}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{power_state}>, C<%{alarm}>, C<%{warning}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{power_state} ne "on"'>).
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{power_state}>, C<%{alarm}>, C<%{warning}>.
C<%{power_state}> can be C<on> or C<off>, C<%{alarm}> can be C<yes> or C<no>, C<%{warning}> is C<no> or the warning message
(for example when the VM tools are not installed).

=item B<--warning-uptime>

Threshold for the uptime (in seconds).

=item B<--critical-uptime>

Threshold for the uptime (in seconds).

=back

=cut
