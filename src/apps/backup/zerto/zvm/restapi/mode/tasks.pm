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

package apps::backup::zerto::zvm::restapi::mode::tasks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(change_seconds is_empty is_excluded);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_task_state);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "task '%s' [type: %s] [state: %s]",
        $self->{result_values}->{id},
        $self->{result_values}->{type},
        $self->{result_values}->{state}
    );
    $msg .= ' [vpgs: ' . $self->{result_values}->{vpg_ids} . ']' if $self->{result_values}->{vpg_ids} ne '';
    $msg .= ' [progress: ' . $self->{result_values}->{progress} . '%]' if $self->{result_values}->{state} =~ /InProgress|Paused|WaitingForUserInput/;
    $msg .= ' [elapsed: ' . ($self->{result_values}->{elapsed} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{elapsed})) . ']';
    $msg .= ' ' . $self->{result_values}->{complete_reason} if $self->{result_values}->{complete_reason} ne '';

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Tasks ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name                    => 'tasks',
            type                    => COUNTER_TYPE_GROUP,
            message_multiple        => 'All tasks are ok',
            display_counter_problem => { nlabel => 'tasks.problems.current.count', min => 0 },
            group                   => [ { name => 'task', skipped_code => { -11 => 1 } } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'tasks-total', nlabel => 'tasks.total.count', set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'tasks-running', nlabel => 'tasks.running.count', set => {
                key_values      => [ { name => 'running' }, { name => 'total' } ],
                output_template => 'running: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'tasks-completed', nlabel => 'tasks.completed.count', display_ok => 0, set => {
                key_values      => [ { name => 'completed' }, { name => 'total' } ],
                output_template => 'completed: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'tasks-failed', nlabel => 'tasks.failed.count', set => {
                key_values      => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'failed: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{task} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{state} =~ /Stopped|Cancelling/i',
            critical_default => '%{state} =~ /Failed/i',
            set              => {
                key_values                     => [
                    { name => 'id' }, { name => 'type' }, { name => 'state' }, { name => 'complete_reason' },
                    { name => 'initiated_by' }, { name => 'vpg_ids' }, { name => 'progress' }, { name => 'elapsed' }
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
        'include-type:s'   => { name => 'include_type', default => '' },
        'exclude-type:s'   => { name => 'exclude_type', default => '' },
        'include-vpg-id:s' => { name => 'include_vpg_id', default => '' },
        'exclude-vpg-id:s' => { name => 'exclude_vpg_id', default => '' },
        'timeframe:s'      => { name => 'timeframe', default => 86400, numeric => 1 },
        'memory'           => { name => 'memory' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options)
        if $self->{option_results}->{memory};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $tasks = $options{custom}->get_tasks();

    my $last_time;
    if ($self->{option_results}->{memory}) {
        $self->{statefile_cache}->read(
            statefile => 'zerto_zvm_' . $self->{mode} . '_' . sha256_hex(join('_', $options{custom}->get_connection_info(),
                map { $self->{option_results}->{$_} // '' } qw/include_type exclude_type include_vpg_id exclude_vpg_id/))
        );
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my $current_time = time();
    my $since = $last_time
        // (is_empty($self->{option_results}->{timeframe}) ? undef : $current_time - $self->{option_results}->{timeframe});

    $self->{global} = { total => 0, running => 0, completed => 0, failed => 0 };
    $self->{tasks} = { global => { task => {} } };
    foreach my $task (@$tasks) {
        my $id = $task->{TaskIdentifier} // $task->{Link}->{identifier} // '';
        my $type = $task->{Type} // '';
        my $vpg_ids = join(',', sort map { $_->{identifier} // () } @{$task->{RelatedEntities}->{Vpgs} // []});

        next if is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});
        next if is_excluded($vpg_ids, $self->{option_results}->{include_vpg_id}, $self->{option_results}->{exclude_vpg_id}, output => $self->{output});

        my $state = enum_name(value => $task->{Status}->{State}, map => $map_task_state);
        my $running = $state =~ /InProgress|WaitingForUserInput|Paused|Cancelling/ ? 1 : 0;
        my $start_time = $options{custom}->date_to_epoch(value => $task->{Started});
        my $end_time = $options{custom}->date_to_epoch(value => $task->{Completed});
        # a running task has no completion date (null or a date before 1970)
        $start_time = undef if defined($start_time) && $start_time <= 0;
        $end_time = undef if $running || (defined($end_time) && $end_time <= 0);

        # running tasks are always checked, ended tasks only when they ended in the timeframe (or since last check)
        next if !$running && defined($since) && ($end_time // $start_time // 0) < $since;

        $self->{tasks}->{global}->{task}->{$id} = {
            id              => $id,
            type            => $type,
            state           => $state,
            complete_reason => $task->{CompleteReason} // '',
            initiated_by    => $task->{InitiatedBy} // '',
            vpg_ids         => $vpg_ids,
            progress        => $task->{Status}->{Progress} // 0,
            elapsed         => defined($start_time) ? ($end_time // $current_time) - $start_time : 0
        };

        $self->{global}->{total}++;
        $self->{global}->{running}++ if $running;
        $self->{global}->{completed}++ if $state eq 'Completed';
        $self->{global}->{failed}++ if $state eq 'Failed';
    }

    $self->{statefile_cache}->write(data => { last_time => $current_time })
        if $self->{option_results}->{memory};
}

1;

__END__

=head1 MODE

Check Zerto Virtual Manager tasks (VPG, failover, VRA and site operations).
Running tasks are always checked, ended tasks only if they ended within the timeframe.

=over 8

=item B<--include-type>

Filter tasks by type (can be a regexp), e.g. C<FailOverTest|FailOver|Move>.

=item B<--exclude-type>

Exclude tasks by type (can be a regexp).

=item B<--include-vpg-id>

Filter tasks by the ID of a related VPG (can be a regexp).

=item B<--exclude-vpg-id>

Exclude tasks by the ID of a related VPG (can be a regexp).

=item B<--timeframe>

Define the timeframe in seconds to check the ended tasks (default: 86400).
Set it to an empty value to check all the tasks returned by the API.

=item B<--memory>

Only check the tasks that ended since the last execution (running tasks are always checked).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{type}>, C<%{state}>, C<%{complete_reason}>, C<%{initiated_by}>, C<%{vpg_ids}>, C<%{progress}>, C<%{elapsed}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{state} =~ /Stopped|Cancelling/i'>).
You can use the following variables: C<%{id}>, C<%{type}>, C<%{state}>, C<%{complete_reason}>, C<%{initiated_by}>, C<%{vpg_ids}>, C<%{progress}>, C<%{elapsed}>.
C<%{state}> can be: C<InProgress>, C<WaitingForUserInput>, C<Paused>, C<Failed>, C<Stopped>, C<Completed>, C<Cancelling>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{state} =~ /Failed/i'>).
You can use the following variables: C<%{id}>, C<%{type}>, C<%{state}>, C<%{complete_reason}>, C<%{initiated_by}>, C<%{vpg_ids}>, C<%{progress}>, C<%{elapsed}>.

=item B<--warning-tasks-total>

Threshold for the number of tasks.

=item B<--critical-tasks-total>

Threshold for the number of tasks.

=item B<--warning-tasks-running>

Threshold for the number of running tasks.

=item B<--critical-tasks-running>

Threshold for the number of running tasks.

=item B<--warning-tasks-completed>

Threshold for the number of completed tasks.

=item B<--critical-tasks-completed>

Threshold for the number of completed tasks.

=item B<--warning-tasks-failed>

Threshold for the number of failed tasks.

=item B<--critical-tasks-failed>

Threshold for the number of failed tasks.

=back

=cut
