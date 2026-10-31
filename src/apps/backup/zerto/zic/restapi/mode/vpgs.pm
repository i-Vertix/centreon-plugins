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

package apps::backup::zerto::zic::restapi::mode::vpgs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(change_seconds is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub human_seconds {
    my (%options) = @_;

    return $options{value} == 0 ? '0s' : change_seconds(value => $options{value});
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "state: %s, protection status: %s",
        $self->{result_values}->{state},
        $self->{result_values}->{protection_status}
    );
}

sub custom_rpo_output {
    my ($self, %options) = @_;

    my $msg = 'actual RPO: ' . human_seconds(value => $self->{result_values}->{actual_rpo});
    $msg .= ' (configured: ' . human_seconds(value => $self->{result_values}->{configured_rpo}) . ')'
        if ($self->{result_values}->{configured_rpo} >= 0);

    return $msg;
}

sub custom_history_output {
    my ($self, %options) = @_;

    my $msg = 'actual history: ' . human_seconds(value => $self->{result_values}->{actual_history});
    $msg .= ' (configured: ' . human_seconds(value => $self->{result_values}->{configured_history}) . ')'
        if ($self->{result_values}->{configured_history} >= 0);

    return $msg;
}

sub custom_checkpoint_output {
    my ($self, %options) = @_;

    return 'last checkpoint: ' . human_seconds(value => $self->{result_values}->{last_checkpoint}) . ' ago';
}

sub custom_failover_test_output {
    my ($self, %options) = @_;

    return 'last successful failover test: ' . human_seconds(value => $self->{result_values}->{last_failover_test}) . ' ago';
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
            name               => 'vpgs',
            type               => COUNTER_TYPE_INSTANCE,
            cb_prefix_output   => 'prefix_vpg_output',
            message_multiple   => 'All VPGs are ok',
            skipped_code       => { NO_VALUE() => 1 }
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
        },
        { label => 'vpgs-without-data', nlabel => 'vpgs.withoutdata.count', set => {
                key_values      => [ { name => 'without_data' } ],
                output_template => 'without data: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vpgs} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{state} =~ /FailoverBeforeCommit|FailoverTest|Recovered/i',
            critical_default => '%{state} =~ /NeedsConfiguration/i || %{protection_status} =~ /NotMeetingSLA/i',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'id' }, { name => 'state' }, { name => 'protection_status' }
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
        { label => 'last-checkpoint', nlabel => 'vpg.checkpoint.last.seconds', set => {
                key_values            => [ { name => 'last_checkpoint' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_checkpoint_output'),
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
        { label => 'sync-progress', nlabel => 'vpg.sync.progress.percentage', display_ok => 0, set => {
                key_values      => [ { name => 'progress' }, { name => 'name' } ],
                output_template => 'initial sync progress: %s%%',
                perfdatas       => [
                    { template => '%d', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'replication-issues', nlabel => 'vpg.replication.issues.count', set => {
                key_values      => [ { name => 'replication_issues' }, { name => 'name' } ],
                output_template => 'replication issues: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'filter-id:s'                 => { redirect => 'include_id' },
        'filter-name:s'               => { redirect => 'include_name' },
        'include-id:s'                => { name => 'include_id', default => '' },
        'exclude-id:s'                => { name => 'exclude_id', default => '' },
        'include-name:s'              => { name => 'include_name', default => '' },
        'exclude-name:s'              => { name => 'exclude_name', default => '' },
        'include-protected-region:s'  => { name => 'include_protected_region', default => '' },
        'exclude-protected-region:s'  => { name => 'exclude_protected_region', default => '' },
        'include-protected-account:s' => { name => 'include_protected_account', default => '' },
        'exclude-protected-account:s' => { name => 'exclude_protected_account', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->get_vpgs();

    $self->{global} = { total => 0, meeting_sla => 0, not_meeting_sla => 0, initializing => 0, without_data => 0 };
    $self->{vpgs} = {};

    foreach my $vpg (@{$response->{vpgs} // []}) {
        my $general = $vpg->{vpgInfo}->{general} // {};
        my $sla = $vpg->{vpgInfo}->{replication}->{sla} // {};
        my $statistics = $vpg->{replicationInfo}->{replicationStatistics} // {};
        my $replication_data = $statistics->{replicationData} // {};
        my $name = $general->{name} || $vpg->{vpgId};
        my $protected_region = $general->{protectedRegion}->{name} // '';
        my $protected_account = $general->{protectedAccount}->{accountId} // '';

        next if is_excluded($vpg->{vpgId}, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($protected_region, $self->{option_results}->{include_protected_region}, $self->{option_results}->{exclude_protected_region}, output => $self->{output});
        next if is_excluded($protected_account, $self->{option_results}->{include_protected_account}, $self->{option_results}->{exclude_protected_account}, output => $self->{output});

        my $protection_status = $statistics->{protectionStatus} // 'Na';
        # vpgState can be a list of states ("A VPG can be in multiple states")
        my $state = ref($vpg->{vpgState}) eq 'ARRAY' ? join(',', @{$vpg->{vpgState}}) : ($vpg->{vpgState} // 'unknown');

        $self->{global}->{total}++;
        $self->{global}->{meeting_sla}++ if ($protection_status eq 'MeetingSLA');
        $self->{global}->{not_meeting_sla}++ if ($protection_status =~ /NotMeetingSLA/);
        $self->{global}->{initializing}++ if ($protection_status eq 'Initializing');

        my $configured_rpo = $options{custom}->timespan_to_seconds(value => $sla->{rpo});
        my $configured_history = $options{custom}->timespan_to_seconds(value => $sla->{history});
        my $entry = {
            id                 => $vpg->{vpgId},
            name               => $name,
            state              => $state,
            protection_status  => $protection_status,
            actual_rpo         => $options{custom}->timespan_to_seconds(value => $statistics->{actualRpo}),
            configured_rpo     => $configured_rpo // -1,
            actual_history     => $options{custom}->timespan_to_seconds(value => $statistics->{actualHistory}),
            configured_history => $configured_history // -1,
            progress           => $replication_data->{progress},
            replication_issues => ref($vpg->{replicationInfo}->{replicationIssues}) eq 'ARRAY'
                ? scalar(@{$vpg->{replicationInfo}->{replicationIssues}}) : 0,
            protected_vms      => ref($vpg->{vpgInfo}->{protectedResources}->{vms}) eq 'ARRAY'
                ? scalar(@{$vpg->{vpgInfo}->{protectedResources}->{vms}}) : undef
        };

        my $checkpoint_time = $options{custom}->date_to_epoch(value => $replication_data->{latestCheckpoint}->{timeStamp});
        $entry->{last_checkpoint} = time() - $checkpoint_time if defined($checkpoint_time);
        my $failover_test_time = $options{custom}->date_to_epoch(value => $vpg->{recoveryInfo}->{failoverTestResult}->{lastSucceeded});
        $entry->{last_failover_test} = time() - $failover_test_time if defined($failover_test_time);

        $self->{vpgs}->{$vpg->{vpgId}} = $entry;

        foreach my $issue (@{$vpg->{replicationInfo}->{replicationIssues} // []}) {
            $self->{output}->output_add(long_msg => "VPG '" . $name . "' replication issue: " . $issue);
        }
    }

    foreach my $vpg_id (sort @{$response->{vpgsWithoutData} // []}) {
        next if is_excluded($vpg_id, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});

        $self->{global}->{without_data}++;
        $self->{output}->output_add(long_msg => "VPG '" . $vpg_id . "' has no data");
    }

    $self->{output}->option_exit(short_msg => 'No VPG found.')
        if $self->{global}->{total} == 0 && $self->{global}->{without_data} == 0;
}

1;

__END__

=head1 MODE

Check Zerto In-Cloud virtual protection groups (VPGs): state, SLA (RPO and history), checkpoints and failover tests.

=over 8

=item B<--include-id>

Filter VPGs by ID (can be a regexp).

=item B<--exclude-id>

Exclude VPGs by ID (can be a regexp).

=item B<--include-name>

Filter VPGs by name (can be a regexp).

=item B<--exclude-name>

Exclude VPGs by name (can be a regexp).

=item B<--include-protected-region>

Filter VPGs by the name of the protected region (can be a regexp).

=item B<--exclude-protected-region>

Exclude VPGs by the name of the protected region (can be a regexp).

=item B<--include-protected-account>

Filter VPGs by the ID of the protected member account (can be a regexp).

=item B<--exclude-protected-account>

Exclude VPGs by the ID of the protected member account (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{id}>, C<%{state}>, C<%{protection_status}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{state} =~ /FailoverBeforeCommit|FailoverTest|Recovered/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{state}>, C<%{protection_status}>.
C<%{state}> can be: C<Protecting>, C<FailoverBeforeCommit>, C<Recovered>, C<FailoverTest>, C<NeedsConfiguration>.
C<%{protection_status}> can be: C<Na>, C<Initializing>, C<MeetingSLA>, C<NotMeetingSLA>, C<RpoNotMeetingSLA>, C<HistoryNotMeetingSLA>, C<Recovered>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{state} =~ /NeedsConfiguration/i || %{protection_status} =~ /NotMeetingSLA/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{state}>, C<%{protection_status}>.

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

Threshold for the number of VPGs in initial sync.

=item B<--critical-vpgs-initializing>

Threshold for the number of VPGs in initial sync.

=item B<--warning-vpgs-without-data>

Threshold for the number of VPGs without data.

=item B<--critical-vpgs-without-data>

Threshold for the number of VPGs without data.

=item B<--warning-actual-rpo>

Threshold for the actual RPO (in seconds).

=item B<--critical-actual-rpo>

Threshold for the actual RPO (in seconds).

=item B<--warning-actual-history>

Threshold for the actual history (in seconds).

=item B<--critical-actual-history>

Threshold for the actual history (in seconds).

=item B<--warning-last-checkpoint>

Threshold for the time since the latest checkpoint (in seconds).

=item B<--critical-last-checkpoint>

Threshold for the time since the latest checkpoint (in seconds).

=item B<--warning-last-failover-test>

Threshold for the time since the last successful failover test (in seconds).

=item B<--critical-last-failover-test>

Threshold for the time since the last successful failover test (in seconds).

=item B<--warning-sync-progress>

Threshold for the initial sync progress (in %).

=item B<--critical-sync-progress>

Threshold for the initial sync progress (in %).

=item B<--warning-replication-issues>

Threshold for the number of replication issues.

=item B<--critical-replication-issues>

Threshold for the number of replication issues.

=item B<--warning-protected-vms>

Threshold for the number of VMs protected by the VPG.

=item B<--critical-protected-vms>

Threshold for the number of VMs protected by the VPG.

=back

=cut
