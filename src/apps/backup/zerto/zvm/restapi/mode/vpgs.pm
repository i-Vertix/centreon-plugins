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

package apps::backup::zerto::zvm::restapi::mode::vpgs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(change_seconds is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_vpg_status $map_vpg_substatus $map_vpg_priority);

sub human_seconds {
    my (%options) = @_;

    return $options{value} == 0 ? '0s' : change_seconds(value => $options{value});
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s, substatus: %s",
        $self->{result_values}->{status},
        $self->{result_values}->{substatus}
    );
}

sub custom_rpo_output {
    my ($self, %options) = @_;

    my $msg = 'actual RPO: ' . human_seconds(value => $self->{result_values}->{actual_rpo});
    $msg .= ' (configured: ' . human_seconds(value => $self->{result_values}->{configured_rpo}) . ')'
        if $self->{result_values}->{configured_rpo} >= 0;

    return $msg;
}

sub custom_history_output {
    my ($self, %options) = @_;

    my $msg = 'actual history: ' . human_seconds(value => $self->{result_values}->{actual_history});
    $msg .= ' (configured: ' . human_seconds(value => $self->{result_values}->{configured_history}) . ')'
        if $self->{result_values}->{configured_history} >= 0;

    return $msg;
}

sub custom_failover_test_output {
    my ($self, %options) = @_;

    return 'last failover test: ' . human_seconds(value => $self->{result_values}->{last_failover_test}) . ' ago';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'VPGs ';
}

sub prefix_vpg_output {
    my ($self, %options) = @_;

    return "VPG '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'vpgs',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_vpg_output',
            message_multiple => 'All VPGs are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vpgs-total', nlabel => 'vpgs.total.count', display_ok => 0, set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vpgs-meeting-sla', nlabel => 'vpgs.sla.meeting.count', set => {
                key_values      => [ { name => 'meeting_sla' }, { name => 'total' } ],
                output_template => 'meeting SLA: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'vpgs-not-meeting-sla', nlabel => 'vpgs.sla.notmeeting.count', set => {
                key_values      => [ { name => 'not_meeting_sla' }, { name => 'total' } ],
                output_template => 'not meeting SLA: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'vpgs-initializing', nlabel => 'vpgs.initializing.count', set => {
                key_values      => [ { name => 'initializing' }, { name => 'total' } ],
                output_template => 'initializing: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vpgs} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{status} =~ /RpoNotMeetingSLA|HistoryNotMeetingSLA/i || %{substatus} =~ /Paused|DisconnectedFromPeer|BeforeCommit/i',
            critical_default => '%{status} eq "NotMeetingSLA" || %{substatus} =~ /Error|NeedsConfiguration/i',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'id' }, { name => 'status' }, { name => 'substatus' }, { name => 'priority' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'actual-rpo', nlabel => 'vpg.rpo.actual.seconds', set => {
                key_values            => [ { name => 'actual_rpo' }, { name => 'configured_rpo' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_rpo_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'actual-history', nlabel => 'vpg.history.actual.seconds', set => {
                key_values            => [ { name => 'actual_history' }, { name => 'configured_history' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_history_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'last-failover-test', nlabel => 'vpg.failovertest.last.seconds', set => {
                key_values            => [ { name => 'last_failover_test' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_failover_test_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'progress', nlabel => 'vpg.operation.progress.percentage', display_ok => 0, set => {
                key_values      => [ { name => 'progress' }, { name => 'name' } ],
                output_template => 'operation progress: %.2f%%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'iops', nlabel => 'vpg.io.operations.persecond', display_ok => 0, set => {
                key_values      => [ { name => 'iops' }, { name => 'name' } ],
                output_template => 'IOPS: %s',
                perfdatas       => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'throughput', nlabel => 'vpg.throughput.bytespersecond', display_ok => 0, set => {
                key_values          => [ { name => 'throughput' }, { name => 'name' } ],
                output_template     => 'throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'storage-used', nlabel => 'vpg.storage.used.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'storage_used' }, { name => 'name' } ],
                output_template     => 'recovery storage used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'protected-vms', nlabel => 'vpg.vms.protected.count', display_ok => 0, set => {
                key_values      => [ { name => 'protected_vms' }, { name => 'name' } ],
                output_template => 'protected VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'include-id:s'   => { name => 'include_id', default => '' },
        'exclude-id:s'   => { name => 'exclude_id', default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vpgs = $options{custom}->get_vpgs();

    $self->{global} = { total => 0, meeting_sla => 0, not_meeting_sla => 0, initializing => 0 };
    $self->{vpgs} = {};

    foreach my $vpg (@$vpgs) {
        my $id = $vpg->{VpgIdentifier} // '';
        my $name = $vpg->{VpgName} || $id;

        next if is_excluded($id, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        my $status = enum_name(value => $vpg->{Status}, map => $map_vpg_status);
        $self->{global}->{total}++;
        $self->{global}->{meeting_sla}++ if $status eq 'MeetingSLA';
        $self->{global}->{not_meeting_sla}++ if $status =~ /NotMeetingSLA/;
        $self->{global}->{initializing}++ if $status eq 'Initializing';

        my $history = $vpg->{HistoryStatusApi} // {};
        # -1 means the RPO has not been calculated yet
        my $entry = {
            id                 => $id,
            name               => $name,
            status             => $status,
            substatus          => enum_name(value => $vpg->{SubStatus}, map => $map_vpg_substatus),
            priority           => enum_name(value => $vpg->{Priority}, map => $map_vpg_priority),
            actual_rpo         => defined($vpg->{ActualRPO}) && $vpg->{ActualRPO} >= 0 ? $vpg->{ActualRPO} : undef,
            configured_rpo     => $vpg->{ConfiguredRpoSeconds} // -1,
            actual_history     => defined($history->{ActualHistoryInMinutes}) ? $history->{ActualHistoryInMinutes} * 60 : undef,
            configured_history => defined($history->{ConfiguredHistoryInMinutes}) ? $history->{ConfiguredHistoryInMinutes} * 60 : -1,
            progress           => $vpg->{ProgressPercentage},
            iops               => $vpg->{IOPS},
            throughput         => defined($vpg->{ThroughputInMB}) ? $vpg->{ThroughputInMB} * 1024 * 1024 : undef,
            storage_used       => defined($vpg->{UsedStorageInMB}) ? $vpg->{UsedStorageInMB} * 1024 * 1024 : undef,
            protected_vms      => $vpg->{VmsCount}
        };

        my $last_test = $options{custom}->date_to_epoch(value => $vpg->{LastTest});
        $entry->{last_failover_test} = time() - $last_test if defined($last_test) && $last_test > 0;

        $self->{vpgs}->{$id} = $entry;
    }

    $self->{output}->option_exit(short_msg => 'No VPG found.')
        if $self->{global}->{total} == 0;
}

1;

__END__

=head1 MODE

Check Zerto virtual protection groups (VPGs): status, SLA (RPO and journal history), failover tests and replication statistics.

=over 8

=item B<--include-id>

Filter VPGs by ID (can be a regexp).

=item B<--exclude-id>

Exclude VPGs by ID (can be a regexp).

=item B<--include-name>

Filter VPGs by name (can be a regexp).

=item B<--exclude-name>

Exclude VPGs by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{id}>, C<%{status}>, C<%{substatus}>, C<%{priority}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /RpoNotMeetingSLA|HistoryNotMeetingSLA/i || %{substatus} =~ /Paused|DisconnectedFromPeer|BeforeCommit/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{status}>, C<%{substatus}>, C<%{priority}>.
C<%{status}> can be: C<Initializing>, C<MeetingSLA>, C<NotMeetingSLA>, C<RpoNotMeetingSLA>, C<HistoryNotMeetingSLA>, C<FailingOver>, C<Moving>, C<Deleting>, C<Recovered>.
C<%{substatus}> can be for example: C<None>, C<InitialSync>, C<DeltaSync>, C<BitmapSync>, C<NeedsConfiguration>, C<Error>,
C<ReplicationPausedUserInitiated>, C<ReplicationPausedSystemInitiated>, C<DisconnectedFromPeer>, C<FailingOverBeforeCommit>,
C<JournalStorageError>, C<RecoveryStorageError>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} eq "NotMeetingSLA" || %{substatus} =~ /Error|NeedsConfiguration/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{status}>, C<%{substatus}>, C<%{priority}>.

=item B<--warning-vpgs-total>

Threshold for the total number of VPGs.

=item B<--critical-vpgs-total>

Threshold for the total number of VPGs.

=item B<--warning-vpgs-meeting-sla>

Threshold for the number of VPGs meeting the SLA.

=item B<--critical-vpgs-meeting-sla>

Threshold for the number of VPGs meeting the SLA.

=item B<--warning-vpgs-not-meeting-sla>

Threshold for the number of VPGs not meeting the SLA.

=item B<--critical-vpgs-not-meeting-sla>

Threshold for the number of VPGs not meeting the SLA.

=item B<--warning-vpgs-initializing>

Threshold for the number of initializing VPGs.

=item B<--critical-vpgs-initializing>

Threshold for the number of initializing VPGs.

=item B<--warning-actual-rpo>

Threshold for the actual RPO (in seconds).

=item B<--critical-actual-rpo>

Threshold for the actual RPO (in seconds).

=item B<--warning-actual-history>

Threshold for the actual journal history (in seconds).

=item B<--critical-actual-history>

Threshold for the actual journal history (in seconds).

=item B<--warning-last-failover-test>

Threshold for the time since the last failover test (in seconds).

=item B<--critical-last-failover-test>

Threshold for the time since the last failover test (in seconds).

=item B<--warning-progress>

Threshold for the progress of the current operation, such as a synchronization (in %).

=item B<--critical-progress>

Threshold for the progress of the current operation, such as a synchronization (in %).

=item B<--warning-iops>

Threshold for the IO operations per second.

=item B<--critical-iops>

Threshold for the IO operations per second.

=item B<--warning-throughput>

Threshold for the replication throughput (in B/s).

=item B<--critical-throughput>

Threshold for the replication throughput (in B/s).

=item B<--warning-storage-used>

Threshold for the storage used at the recovery site (in B).

=item B<--critical-storage-used>

Threshold for the storage used at the recovery site (in B).

=item B<--warning-protected-vms>

Threshold for the number of VMs protected by the VPG.

=item B<--critical-protected-vms>

Threshold for the number of VMs protected by the VPG.

=back

=cut
