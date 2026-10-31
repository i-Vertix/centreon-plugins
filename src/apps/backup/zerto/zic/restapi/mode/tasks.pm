#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::backup::zerto::zic::restapi::mode::tasks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(change_seconds is_empty is_excluded);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "task '%s' [operation: %s] [status: %s]",
        $self->{result_values}->{id},
        $self->{result_values}->{operation},
        $self->{result_values}->{status}
    );
    $msg .= ' [result: ' . $self->{result_values}->{completion_status} . ']' if ($self->{result_values}->{completion_status} ne '');
    $msg .= ' [vpg: ' . $self->{result_values}->{vpg_id} . ']' if ($self->{result_values}->{vpg_id} ne '');
    $msg .= ' [progress: ' . $self->{result_values}->{progress} . '%]' if ($self->{result_values}->{status} =~ /Running/);
    $msg .= ' [elapsed: ' . ($self->{result_values}->{elapsed} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{elapsed})) . ']';
    $msg .= ' ' . $self->{result_values}->{failure_reason} if ($self->{result_values}->{failure_reason} ne '');

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
        { label => 'tasks-success', nlabel => 'tasks.success.count', display_ok => 0, set => {
                key_values      => [ { name => 'success' }, { name => 'total' } ],
                output_template => 'success: %s',
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
            warning_default  => '%{completion_status} =~ /PartialSuccess|Cancelled/i',
            critical_default => '%{completion_status} =~ /Failed/i',
            set              => {
                key_values                     => [
                    { name => 'id' }, { name => 'operation' }, { name => 'status' }, { name => 'completion_status' },
                    { name => 'failure_reason' }, { name => 'vpg_id' }, { name => 'member_account_id' },
                    { name => 'progress' }, { name => 'elapsed' }
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
        'include-operation:s' => { name => 'include_operation', default => '' },
        'exclude-operation:s' => { name => 'exclude_operation', default => '' },
        'include-vpg-id:s'    => { name => 'include_vpg_id', default => '' },
        'exclude-vpg-id:s'    => { name => 'exclude_vpg_id', default => '' },
        'timeframe:s'         => { name => 'timeframe', default => 86400, numeric => 1 },
        'top:s'               => { name => 'top', greater_than => 0 },
        'memory'              => { name => 'memory' }
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

    my $tasks = $options{custom}->get_tasks(top => $self->{option_results}->{top});

    my $last_time;
    if ($self->{option_results}->{memory}) {
        $self->{statefile_cache}->read(
            statefile => 'zerto_zic_' . $self->{mode} . '_' . sha256_hex(join('_', $options{custom}->get_connection_info(),
                map { $self->{option_results}->{$_} // '' } qw/include_operation exclude_operation include_vpg_id exclude_vpg_id/))
        );
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my $current_time = time();
    my $since = $last_time
        // (is_empty($self->{option_results}->{timeframe}) ? undef : $current_time - $self->{option_results}->{timeframe});

    $self->{global} = { total => 0, running => 0, success => 0, failed => 0 };
    $self->{tasks} = { global => { task => {} } };
    foreach my $task (@$tasks) {
        my $id = ref($task->{taskId}) eq 'HASH' ? $task->{taskId}->{id} : $task->{taskId};
        my $operation = $task->{operationType} // '';
        my $vpg_id = $task->{vpgId} // '';
        my $status = $task->{status} // '';

        next if is_excluded($operation, $self->{option_results}->{include_operation}, $self->{option_results}->{exclude_operation}, output => $self->{output});
        next if is_excluded($vpg_id, $self->{option_results}->{include_vpg_id}, $self->{option_results}->{exclude_vpg_id}, output => $self->{output});

        my $start_time = $options{custom}->date_to_epoch(value => $task->{startTime});
        my $end_time = $options{custom}->date_to_epoch(value => $task->{endTime});
        # running tasks are always checked, completed tasks only when they ended in the timeframe (or since last check)
        next if $status eq 'Completed' && defined($since) && ($end_time // $start_time // 0) < $since;

        my $completion_status = $task->{taskResult}->{taskCompletionStatus} // '';
        $self->{tasks}->{global}->{task}->{$id} = {
            id                => $id,
            operation         => $operation,
            status            => $status,
            completion_status => $completion_status,
            failure_reason    => $task->{taskResult}->{failureReason} // '',
            vpg_id            => $vpg_id,
            member_account_id => $task->{memberAccountId} // '',
            progress          => $task->{progress} // 0,
            elapsed           => defined($start_time) ? ($end_time // $current_time) - $start_time : 0
        };

        $self->{global}->{total}++;
        $self->{global}->{running}++ if $status =~ /Running|NotStarted/;
        $self->{global}->{success}++ if $completion_status eq 'Success';
        $self->{global}->{failed}++ if $completion_status eq 'Failed';
    }

    $self->{statefile_cache}->write(data => { last_time => $current_time })
        if $self->{option_results}->{memory};
}

1;

__END__

=head1 MODE

Check Zerto In-Cloud tasks (VPG, failover and member account operations).
Running tasks are always checked, completed tasks only if they ended within the timeframe.

=over 8

=item B<--include-operation>

Filter tasks by operation type (can be a regexp), e.g. C<FailoverTest|FailoverLive>.

=item B<--exclude-operation>

Exclude tasks by operation type (can be a regexp).

=item B<--include-vpg-id>

Filter tasks by VPG ID (can be a regexp).

=item B<--exclude-vpg-id>

Exclude tasks by VPG ID (can be a regexp).

=item B<--timeframe>

Only check completed tasks that ended within this number of seconds (default: 86400).
Set it to an empty value to check all returned tasks.

=item B<--top>

Only request the given number of latest tasks from the API.

=item B<--memory>

Only check completed tasks that ended since the last execution (overrides --timeframe after the first run).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{operation}>, C<%{status}>, C<%{completion_status}>,
C<%{failure_reason}>, C<%{vpg_id}>, C<%{member_account_id}>, C<%{progress}>, C<%{elapsed}> (seconds).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{completion_status} =~ /PartialSuccess|Cancelled/i'>).
You can use the same variables as for --unknown-status, e.g. C<'%{status} =~ /Running/ && %{elapsed} E<gt> 7200'>.
C<%{status}> can be: C<NotStarted>, C<Running>, C<RunningCancellationRequested>, C<Completed>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{completion_status} =~ /Failed/i'>).
You can use the same variables as for --unknown-status.
C<%{completion_status}> can be: C<Success>, C<Failed>, C<Cancelled>, C<PartialSuccess>.

=item B<--warning-tasks-total>

Threshold for the number of checked tasks.

=item B<--critical-tasks-total>

Threshold for the number of checked tasks.

=item B<--warning-tasks-running>

Threshold for the number of running or queued tasks.

=item B<--critical-tasks-running>

Threshold for the number of running or queued tasks.

=item B<--warning-tasks-success>

Threshold for the number of successful tasks.

=item B<--critical-tasks-success>

Threshold for the number of successful tasks.

=item B<--warning-tasks-failed>

Threshold for the number of failed tasks.

=item B<--critical-tasks-failed>

Threshold for the number of failed tasks.

=back

=cut
