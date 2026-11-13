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

package apps::proxmox::bs::restapi::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s [unit state: %s]',
        $self->{result_values}->{state},
        $self->{result_values}->{unit_state}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Services ';
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'services',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_service_output',
            message_multiple => 'All services are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'services-running', nlabel => 'services.running.count', set => {
                key_values      => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'services-stopped', nlabel => 'services.stopped.count', set => {
                key_values      => [ { name => 'stopped' }, { name => 'total' } ],
                output_template => 'not running: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{services} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{unit_state} eq "enabled" and %{state} ne "running"',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'description' }, { name => 'state' }, { name => 'unit_state' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $services = $options{custom}->get_services();

    $self->{global} = { total => 0, running => 0, stopped => 0 };
    $self->{services} = {};
    foreach my $service (@$services) {
        my $name = $service->{service} // $service->{name} // next;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        my $state = $service->{state} // 'unknown';
        $self->{services}->{$name} = {
            name        => $name,
            description => $service->{desc} // '',
            state       => $state,
            unit_state  => $service->{'unit-state'} // 'unknown'
        };

        $self->{global}->{total}++;
        $self->{global}->{$state eq 'running' ? 'running' : 'stopped'}++;
    }

    $self->{output}->option_exit(short_msg => 'No service found.')
        unless $self->{global}->{total};
}

1;

__END__

=head1 MODE

Check the system services of the node (C<proxmox-backup>, C<proxmox-backup-proxy>, C<sshd>, ...).

=over 8

=item B<--include-name>

Filter services by name (can be a regexp), e.g. C<^proxmox-backup>.

=item B<--exclude-name>

Exclude services by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{description}>, C<%{state}>, C<%{unit_state}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{name}>, C<%{description}>, C<%{state}>, C<%{unit_state}>.
C<%{state}> is the systemd sub-state, e.g. C<running>, C<dead>, C<failed>.
C<%{unit_state}> is the systemd unit state, e.g. C<enabled>, C<disabled>, C<static>, C<masked>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{unit_state} eq "enabled" and %{state} ne "running"'>).
You can use the following variables: C<%{name}>, C<%{description}>, C<%{state}>, C<%{unit_state}>.

=item B<--warning-services-running>

Threshold for the number of running services.

=item B<--critical-services-running>

Threshold for the number of running services.

=item B<--warning-services-stopped>

Threshold for the number of services not running.

=item B<--critical-services-stopped>

Threshold for the number of services not running.

=back

=cut
