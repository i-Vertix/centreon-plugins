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

package cloud::sangfor::scp::management::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded is_not_empty);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my %map_severity = (p1 => 'critical', p2 => 'medium', p3 => 'low');

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "'%s' [severity: %s] [status: %s] [object: %s '%s'] [since: %s] %s",
        $self->{result_values}->{policy_name},
        $self->{result_values}->{severity},
        $self->{result_values}->{status},
        $self->{result_values}->{object_type},
        $self->{result_values}->{object_name},
        $self->{result_values}->{start_time},
        $self->{result_values}->{description}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;
    return 'Alarms ';
}

sub prefix_alarm_output {
    my ($self, %options) = @_;
    return 'Alarm ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        { name => 'alarms', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_alarm_output', message_multiple => 'All alarms are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        map {
            my ($label, $text) = @$_;
            { label => 'alarms-' . $label, nlabel => 'alarms.' . $label . '.count', set => {
                    key_values      => [ { name => $label } ],
                    output_template => $text . ': %s',
                    perfdatas       => [
                        { template => '%s', min => 0 }
                    ]
                }
            }
        } ([ 'total', 'total' ], [ 'critical', 'critical' ], [ 'medium', 'medium' ], [ 'low', 'low' ])
    ];

    $self->{maps_counters}->{alarms} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{status} eq "open" and %{severity} =~ /medium|low/',
            critical_default => '%{status} eq "open" and %{severity} eq "critical"',
            set              => {
                key_values                     => [
                    { name => 'id' }, { name => 'level' }, { name => 'severity' }, { name => 'status' }, { name => 'policy_name' },
                    { name => 'object_type' }, { name => 'object_name' }, { name => 'az_name' }, { name => 'start_time' }, { name => 'description' }
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
        'resource-pool-id:s'    => { name => 'resource_pool_id', default => '' },
        'include-severity:s'    => { name => 'include_severity', default => '' },
        'exclude-severity:s'    => { name => 'exclude_severity', default => '' },
        'include-status:s'      => { name => 'include_status', default => '' },
        'exclude-status:s'      => { name => 'exclude_status', default => '' },
        'include-object-type:s' => { name => 'include_object_type', default => '' },
        'exclude-object-type:s' => { name => 'exclude_object_type', default => '' },
        'include-object-name:s' => { name => 'include_object_name', default => '' },
        'exclude-object-name:s' => { name => 'exclude_object_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $get_param = [];
    push @$get_param, 'az_ids=' . $self->{option_results}->{resource_pool_id}
        if is_not_empty($self->{option_results}->{resource_pool_id});
    my $alarms = $options{custom}->get_alarms(get_param => $get_param);

    $self->{global} = { total => 0, critical => 0, medium => 0, low => 0 };
    $self->{alarms} = {};
    foreach my $alarm (@{$alarms // []}) {
        next unless ref($alarm) eq 'HASH' && defined($alarm->{id});

        my $level = $alarm->{level} // '';
        my $entry = {
            id          => $alarm->{id},
            level       => $level,
            severity    => $map_severity{$level} // $level,
            status      => $alarm->{status} // '',
            policy_name => $alarm->{policy_name} // $alarm->{title} // '',
            object_type => $alarm->{object_type} // '',
            object_name => $alarm->{object_name} // '',
            az_name     => $alarm->{az_name} // '',
            start_time  => $alarm->{start_time} // '',
            description => $alarm->{description} // ''
        };
        $entry->{description} =~ s/[\r\n]+/ /g;

        next if is_excluded($entry->{severity}, $self->{option_results}->{include_severity}, $self->{option_results}->{exclude_severity}, output => $self->{output});
        next if is_excluded($entry->{status}, $self->{option_results}->{include_status}, $self->{option_results}->{exclude_status}, output => $self->{output});
        next if is_excluded($entry->{object_type}, $self->{option_results}->{include_object_type}, $self->{option_results}->{exclude_object_type}, output => $self->{output});
        next if is_excluded($entry->{object_name}, $self->{option_results}->{include_object_name}, $self->{option_results}->{exclude_object_name}, output => $self->{output});

        $self->{global}->{total}++;
        $self->{global}->{$entry->{severity}}++ if defined($self->{global}->{$entry->{severity}});
        $self->{alarms}->{$alarm->{id}} = $entry;
    }
}

1;

__END__

=head1 MODE

Check the realtime alarms of the platform (SCP 6.9.0 and later).

=over 8

=item B<--resource-pool-id>

Only check the alarms of this resource pool ID.

=item B<--include-severity>

Filter alarms by severity (can be a regexp). The severity can be: C<critical> (level C<p1>), C<medium> (level C<p2>), C<low> (level C<p3>).

=item B<--exclude-severity>

Exclude alarms by severity (can be a regexp).

=item B<--include-status>

Filter alarms by status (can be a regexp). The status can be: C<open> (pending), C<ack> (confirmed).

=item B<--exclude-status>

Exclude alarms by status (can be a regexp).

=item B<--include-object-type>

Filter alarms by object type (can be a regexp). For example: C<vm>, C<host>, C<cluster>, C<storage>, C<vnet>.

=item B<--exclude-object-type>

Exclude alarms by object type (can be a regexp).

=item B<--include-object-name>

Filter alarms by object name (can be a regexp).

=item B<--exclude-object-name>

Exclude alarms by object name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{level}>, C<%{severity}>, C<%{status}>, C<%{policy_name}>,
C<%{object_type}>, C<%{object_name}>, C<%{az_name}>, C<%{start_time}>, C<%{description}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} eq "open" and %{severity} =~ /medium|low/'>).
You can use the following variables: C<%{id}>, C<%{level}>, C<%{severity}>, C<%{status}>, C<%{policy_name}>,
C<%{object_type}>, C<%{object_name}>, C<%{az_name}>, C<%{start_time}>, C<%{description}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} eq "open" and %{severity} eq "critical"'>).
You can use the following variables: C<%{id}>, C<%{level}>, C<%{severity}>, C<%{status}>, C<%{policy_name}>,
C<%{object_type}>, C<%{object_name}>, C<%{az_name}>, C<%{start_time}>, C<%{description}>.

=item B<--warning-alarms-total>

Threshold for the total number of alarms.

=item B<--critical-alarms-total>

Threshold for the total number of alarms.

=item B<--warning-alarms-critical>

Threshold for the number of critical alarms.

=item B<--critical-alarms-critical>

Threshold for the number of critical alarms.

=item B<--warning-alarms-medium>

Threshold for the number of medium alarms.

=item B<--critical-alarms-medium>

Threshold for the number of medium alarms.

=item B<--warning-alarms-low>

Threshold for the number of low alarms.

=item B<--critical-alarms-low>

Threshold for the number of low alarms.

=back

=cut
