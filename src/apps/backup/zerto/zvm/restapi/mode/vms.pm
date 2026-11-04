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

package apps::backup::zerto::zvm::restapi::mode::vms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(change_seconds is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_vpg_status $map_vpg_substatus);

# JournalHardLimit.LimitType: 0 unlimited, 1 megabytes, 2 percentage
use constant JOURNAL_LIMIT_MEGABYTES => 1;

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

    return 'actual RPO: ' . ($self->{result_values}->{actual_rpo} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{actual_rpo}));
}

sub custom_journal_prct_output {
    my ($self, %options) = @_;

    my ($limit_value, $limit_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{journal_limit});

    return sprintf('journal used: %.2f%% of hard limit %s', $self->{result_values}->{journal_prct_used}, $limit_value . ' ' . $limit_unit);
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'VMs ';
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{name} . "' [vpg: " . $options{instance_value}->{vpg} . "] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'vms',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_vm_output',
            message_multiple => 'All VMs are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vms-total', nlabel => 'vms.total.count', display_ok => 0, set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vms-meeting-sla', nlabel => 'vms.sla.meeting.count', set => {
                key_values      => [ { name => 'meeting_sla' }, { name => 'total' } ],
                output_template => 'meeting SLA: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'vms-not-meeting-sla', nlabel => 'vms.sla.notmeeting.count', set => {
                key_values      => [ { name => 'not_meeting_sla' }, { name => 'total' } ],
                output_template => 'not meeting SLA: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vms} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{status} =~ /RpoNotMeetingSLA|HistoryNotMeetingSLA/i || %{substatus} =~ /Paused|DisconnectedFromPeer|BeforeCommit/i',
            critical_default => '%{status} =~ /^NotMeetingSLA$/i || %{substatus} =~ /Error|NeedsConfiguration/i',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'id' }, { name => 'vpg' }, { name => 'status' }, { name => 'substatus' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'actual-rpo', nlabel => 'vm.rpo.actual.seconds', set => {
                key_values            => [ { name => 'actual_rpo' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_rpo_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'journal-usage', nlabel => 'vm.journal.usage.bytes', set => {
                key_values          => [ { name => 'journal_used' }, { name => 'name' } ],
                output_template     => 'journal used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'journal-usage-prct', nlabel => 'vm.journal.usage.percentage', display_ok => 0, set => {
                key_values            => [ { name => 'journal_prct_used' }, { name => 'journal_limit' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_journal_prct_output'),
                perfdatas             => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'iops', nlabel => 'vm.io.operations.persecond', display_ok => 0, set => {
                key_values      => [ { name => 'iops' }, { name => 'name' } ],
                output_template => 'IOPS: %s',
                perfdatas       => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'throughput', nlabel => 'vm.throughput.bytespersecond', display_ok => 0, set => {
                key_values          => [ { name => 'throughput' }, { name => 'name' } ],
                output_template     => 'throughput: %s %s/s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'outgoing-bandwidth', nlabel => 'vm.bandwidth.outgoing.bitspersecond', display_ok => 0, set => {
                key_values          => [ { name => 'outgoing_bandwidth' }, { name => 'name' } ],
                output_template     => 'outgoing bandwidth: %s %s/s',
                output_change_bytes => 2,
                perfdatas           => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'storage-used', nlabel => 'vm.storage.used.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'storage_used' }, { name => 'name' } ],
                output_template     => 'recovery storage used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'include-vpg:s'  => { name => 'include_vpg', default => '' },
        'exclude-vpg:s'  => { name => 'exclude_vpg', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vms = $options{custom}->get_vms();

    $self->{global} = { total => 0, meeting_sla => 0, not_meeting_sla => 0 };
    $self->{vms} = {};

    foreach my $vm (@$vms) {
        my $id = $vm->{VmIdentifier} // '';
        my $name = $vm->{VmName} || $id;
        my $vpg = $vm->{VpgName} || $vm->{VpgIdentifier} // '';

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($vpg, $self->{option_results}->{include_vpg}, $self->{option_results}->{exclude_vpg}, output => $self->{output});

        my $status = enum_name(value => $vm->{Status}, map => $map_vpg_status);
        $self->{global}->{total}++;
        $self->{global}->{meeting_sla}++ if $status eq 'MeetingSLA';
        $self->{global}->{not_meeting_sla}++ if $status =~ /NotMeetingSLA/;

        # storage values are in MB, the outgoing bandwidth in Mb/s
        my $entry = {
            id                 => $id,
            name               => $name,
            vpg                => $vpg,
            status             => $status,
            substatus          => enum_name(value => $vm->{SubStatus}, map => $map_vpg_substatus),
            actual_rpo         => defined($vm->{ActualRPO}) && $vm->{ActualRPO} >= 0 ? $vm->{ActualRPO} : undef,
            iops               => $vm->{IOPs} // $vm->{IOPS},
            throughput         => defined($vm->{ThroughputInMB}) ? $vm->{ThroughputInMB} * 1024 * 1024 : undef,
            outgoing_bandwidth => defined($vm->{OutgoingBandWidthInMbps}) ? $vm->{OutgoingBandWidthInMbps} * 1000 * 1000 : undef,
            storage_used       => defined($vm->{UsedStorageInMB}) ? $vm->{UsedStorageInMB} * 1024 * 1024 : undef
        };

        if (defined($vm->{JournalUsedStorageMb})) {
            $entry->{journal_used} = $vm->{JournalUsedStorageMb} * 1024 * 1024;
            # the usage in percent is only known when the hard limit is a size
            my $limit = $vm->{JournalHardLimit} // {};
            if (defined($limit->{LimitType}) && $limit->{LimitType} =~ /^(?:1|Megabytes)$/i
                && defined($limit->{LimitValue}) && $limit->{LimitValue} > 0) {
                $entry->{journal_limit} = $limit->{LimitValue} * 1024 * 1024;
                $entry->{journal_prct_used} = $entry->{journal_used} * 100 / $entry->{journal_limit};
            }
        }

        # a VM can be protected in several VPGs
        $self->{vms}->{$id . '_' . ($vm->{VpgIdentifier} // '')} = $entry;
    }

    $self->{output}->option_exit(short_msg => 'No VM found.')
        if $self->{global}->{total} == 0;
}

1;

__END__

=head1 MODE

Check the virtual machines protected by Zerto: status, RPO, journal usage and replication statistics.

=over 8

=item B<--include-name>

Filter VMs by name (can be a regexp).

=item B<--exclude-name>

Exclude VMs by name (can be a regexp).

=item B<--include-vpg>

Filter VMs by VPG name (can be a regexp).

=item B<--exclude-vpg>

Exclude VMs by VPG name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{id}>, C<%{vpg}>, C<%{status}>, C<%{substatus}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /RpoNotMeetingSLA|HistoryNotMeetingSLA/i || %{substatus} =~ /Paused|DisconnectedFromPeer|BeforeCommit/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{vpg}>, C<%{status}>, C<%{substatus}>.
C<%{status}> and C<%{substatus}> have the same values as in the C<vpgs> mode.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /^NotMeetingSLA$/i || %{substatus} =~ /Error|NeedsConfiguration/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{vpg}>, C<%{status}>, C<%{substatus}>.

=item B<--warning-vms-total>

Threshold for the total number of protected VMs.

=item B<--critical-vms-total>

Threshold for the total number of protected VMs.

=item B<--warning-vms-meeting-sla>

Threshold for the number of VMs meeting the SLA.

=item B<--critical-vms-meeting-sla>

Threshold for the number of VMs meeting the SLA.

=item B<--warning-vms-not-meeting-sla>

Threshold for the number of VMs not meeting the SLA.

=item B<--critical-vms-not-meeting-sla>

Threshold for the number of VMs not meeting the SLA.

=item B<--warning-actual-rpo>

Threshold for the actual RPO (in seconds).

=item B<--critical-actual-rpo>

Threshold for the actual RPO (in seconds).

=item B<--warning-journal-usage>

Threshold for the journal storage used (in B).

=item B<--critical-journal-usage>

Threshold for the journal storage used (in B).

=item B<--warning-journal-usage-prct>

Threshold for the journal storage used against the journal hard limit (in %).
Only available when the hard limit is defined as a size.

=item B<--critical-journal-usage-prct>

Threshold for the journal storage used against the journal hard limit (in %).
Only available when the hard limit is defined as a size.

=item B<--warning-iops>

Threshold for the IO operations per second.

=item B<--critical-iops>

Threshold for the IO operations per second.

=item B<--warning-throughput>

Threshold for the replication throughput (in B/s).

=item B<--critical-throughput>

Threshold for the replication throughput (in B/s).

=item B<--warning-outgoing-bandwidth>

Threshold for the outgoing bandwidth (in b/s).

=item B<--critical-outgoing-bandwidth>

Threshold for the outgoing bandwidth (in b/s).

=item B<--warning-storage-used>

Threshold for the storage used at the recovery site (in B).

=item B<--critical-storage-used>

Threshold for the storage used at the recovery site (in B).

=back

=cut
