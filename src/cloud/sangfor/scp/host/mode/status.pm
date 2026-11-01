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

package cloud::sangfor::scp::host::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use cloud::sangfor::scp::host::mode::resources qw(get_hosts);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        'status: %s [ip: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{ip}
    );
}

sub prefix_host_output {
    my ($self, %options) = @_;
    return "Host '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'hosts', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_host_output', message_multiple => 'All hosts are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{hosts} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /offline/i',
            set              => {
                key_values                     => [ { name => 'id' }, { name => 'name' }, { name => 'ip' }, { name => 'status' }, { name => 'type' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'alarms', nlabel => 'host.alarms.count', set => {
                key_values      => [ { name => 'alarm_count' }, { name => 'name' } ],
                output_template => 'alarms: %s',
                perfdatas       => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'name' }
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

    $self->{hosts} = {
        map { $_->{id} => $_ } @{get_hosts(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}
    };
}

1;

__END__

=head1 MODE

Check the status and the number of alarms of physical hosts (nodes).

=over 8

=item B<--id>

Define the ID of the host to check.

=item B<--resource-pool-id>

Only check the hosts of this resource pool ID.

=item B<--include-name>

Filter hosts by name (can be a regexp).

=item B<--exclude-name>

Exclude hosts by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{ip}>, C<%{status}>, C<%{type}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{ip}>, C<%{status}>, C<%{type}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /offline/i'>).
You can use the following variables: C<%{id}>, C<%{name}>, C<%{ip}>, C<%{status}>, C<%{type}>.
The status can be: C<running>, C<offline>.

=item B<--warning-alarms>

Threshold for the number of alarms of the host.

=item B<--critical-alarms>

Threshold for the number of alarms of the host.

=back

=cut
