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

package apps::proxmox::bs::restapi::mode::tasks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded is_empty change_seconds);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::proxmox::bs::restapi::mode::resources qw(task_state);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "task '%s' [id: %s] [user: %s] [state: %s]",
        $self->{result_values}->{type},
        $self->{result_values}->{id},
        $self->{result_values}->{user},
        $self->{result_values}->{state}
    );
    $msg .= ' [elapsed: ' . ($self->{result_values}->{elapsed} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{elapsed})) . ']';
    $msg .= ' [status: ' . $self->{result_values}->{status} . ']' if $self->{result_values}->{state} =~ /^(?:warning|error)$/;

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
            group                   => [ { name => 'task', skipped_code => { NO_VALUE() => 1 } } ]
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach (['total', 'total'], ['running', 'running'], ['ok', 'ok'], ['warning', 'with warnings'], ['error', 'failed']) {
        my ($name, $output) = @$_;
        push @{$self->{maps_counters}->{global}}, {
            label => 'tasks-' . $name, nlabel => 'tasks.' . $name . '.count', set => {
                key_values      => [ { name => $name }, { name => 'total' } ],
                output_template => $output . ': %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => $name eq 'total' ? undef : 'total' }
                ]
            }
        };
    }

    $self->{maps_counters}->{task} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{state} eq "warning"',
            critical_default => '%{state} eq "error"',
            set              => {
                key_values                     => [
                    { name => 'upid' }, { name => 'type' }, { name => 'id' }, { name => 'user' },
                    { name => 'state' }, { name => 'status' }, { name => 'elapsed' }
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
        'include-type:s' => { name => 'include_type', default => '' },
        'exclude-type:s' => { name => 'exclude_type', default => '' },
        'include-id:s'   => { name => 'include_id', default => '' },
        'exclude-id:s'   => { name => 'exclude_id', default => '' },
        'include-user:s' => { name => 'include_user', default => '' },
        'exclude-user:s' => { name => 'exclude_user', default => '' },
        'datastore:s'    => { name => 'datastore', default => '' },
        'timeframe:s'    => { name => 'timeframe', default => 86400, numeric => 1 }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $current_time = time();
    my $since = is_empty($self->{option_results}->{timeframe}) ? undef : $current_time - $self->{option_results}->{timeframe};
    my $tasks = $options{custom}->get_tasks(since => $since, store => $self->{option_results}->{datastore});

    $self->{global} = { total => 0, running => 0, ok => 0, warning => 0, error => 0, unknown => 0 };
    $self->{tasks} = { global => { task => {} } };
    foreach my $task (@$tasks) {
        my $upid = $task->{upid} // next;
        my ($type, $id, $user) = ($task->{worker_type} // '', $task->{worker_id} // '', $task->{user} // '');

        next if is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});
        next if is_excluded($id, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
        next if is_excluded($user, $self->{option_results}->{include_user}, $self->{option_results}->{exclude_user}, output => $self->{output});
        # the API filters on the start time: keep the check consistent if it does not
        next if defined($since) && defined($task->{starttime}) && $task->{starttime} < $since && defined($task->{endtime});

        my $state = task_state(endtime => $task->{endtime}, status => $task->{status});
        my $start_time = $task->{starttime};
        my $end_time = $task->{endtime} // $current_time;

        $self->{tasks}->{global}->{task}->{$upid} = {
            upid    => $upid,
            type    => $type,
            id      => $id,
            user    => $user,
            state   => $state,
            status  => $task->{status} // '',
            elapsed => defined($start_time) && $end_time > $start_time ? $end_time - $start_time : 0
        };

        $self->{global}->{total}++;
        $self->{global}->{$state}++;
    }
}

1;

__END__

=head1 MODE

Check the tasks of the node (backup, verification, garbage collection, prune, synchronization, ...)
started within the timeframe.

=over 8

=item B<--include-type>

Filter tasks by type (can be a regexp), e.g. C<^backup$> or C<verificationjob|garbage_collection>.

=item B<--exclude-type>

Exclude tasks by type (can be a regexp).

=item B<--include-id>

Filter tasks by ID (can be a regexp), e.g. C<store01:vm/157> for the backups of a VM.

=item B<--exclude-id>

Exclude tasks by ID (can be a regexp).

=item B<--include-user>

Filter tasks by the user who started them (can be a regexp).

=item B<--exclude-user>

Exclude tasks by the user who started them (can be a regexp).

=item B<--datastore>

Only check the tasks of this datastore (filtered by the API).

=item B<--timeframe>

Define the timeframe in seconds to check the tasks started within it (default: 86400).
Set it to an empty value to check all the tasks returned by the API.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{upid}>, C<%{type}>, C<%{id}>, C<%{user}>, C<%{state}>, C<%{status}>, C<%{elapsed}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{state} eq "warning"'>).
You can use the following variables: C<%{upid}>, C<%{type}>, C<%{id}>, C<%{user}>, C<%{state}>, C<%{status}>, C<%{elapsed}>.
C<%{state}> can be: C<running>, C<ok>, C<warning>, C<error>, C<unknown>. C<%{status}> is the status returned by the API, e.g. the error message.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{state} eq "error"'>).
You can use the following variables: C<%{upid}>, C<%{type}>, C<%{id}>, C<%{user}>, C<%{state}>, C<%{status}>, C<%{elapsed}>.

=item B<--warning-tasks-total>

Threshold for the number of tasks.

=item B<--critical-tasks-total>

Threshold for the number of tasks.

=item B<--warning-tasks-running>

Threshold for the number of running tasks.

=item B<--critical-tasks-running>

Threshold for the number of running tasks.

=item B<--warning-tasks-ok>

Threshold for the number of tasks ended successfully.

=item B<--critical-tasks-ok>

Threshold for the number of tasks ended successfully.

=item B<--warning-tasks-warning>

Threshold for the number of tasks ended with warnings.

=item B<--critical-tasks-warning>

Threshold for the number of tasks ended with warnings.

=item B<--warning-tasks-error>

Threshold for the number of failed tasks.

=item B<--critical-tasks-error>

Threshold for the number of failed tasks.

=back

=cut
