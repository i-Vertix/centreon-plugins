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

package apps::backup::zerto::zvm::restapi::mode::resources;

use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    enum_name
    $map_vpg_status $map_vpg_substatus $map_vra_status $map_alert_status
    $map_pairing_status $map_task_state $map_volume_type $map_vpg_priority
);

# the API returns enumerations as numbers in JSON (the names in XML)
our $map_vpg_status = {
    0 => 'Initializing', 1 => 'MeetingSLA', 2 => 'NotMeetingSLA', 3 => 'RpoNotMeetingSLA',
    4 => 'HistoryNotMeetingSLA', 5 => 'FailingOver', 6 => 'Moving', 7 => 'Deleting', 8 => 'Recovered'
};

our $map_vpg_substatus = {
    0  => 'None', 1 => 'InitialSync', 2 => 'Creating', 3 => 'VolumeInitialSync', 4 => 'Sync',
    5  => 'RecoveryPossible', 6 => 'DeltaSync', 7 => 'NeedsConfiguration', 8 => 'Error',
    9  => 'EmptyProtectionGroup', 10 => 'DisconnectedFromPeerNoRecoveryPoints', 11 => 'FullSync',
    12 => 'VolumeDeltaSync', 13 => 'VolumeFullSync', 14 => 'FailingOverCommitting',
    15 => 'FailingOverBeforeCommit', 16 => 'FailingOverRollingBack', 17 => 'Promoting',
    18 => 'MovingCommitting', 19 => 'MovingBeforeCommit', 20 => 'MovingRollingBack', 21 => 'Deleting',
    22 => 'PendingRemove', 23 => 'BitmapSync', 24 => 'DisconnectedFromPeer',
    25 => 'ReplicationPausedUserInitiated', 26 => 'ReplicationPausedSystemInitiated',
    27 => 'RecoveryStoragePolicyError', 29 => 'RollingBack', 30 => 'RecoveryStorageError',
    31 => 'JournalStorageError', 32 => 'VmNotProtectedError', 33 => 'JournalOrRecoveryMissingError',
    34 => 'AddedVmsInInitialSync', 35 => 'ReplicationPausedForMissingVolume', 36 => 'StoppingForFailure',
    37 => 'RollingBackFailOverLiveFailure', 38 => 'RollingBackMoveFailure', 39 => 'SplittingCommitting',
    40 => 'PreparePreseed'
};

our $map_vpg_priority = { 0 => 'Low', 1 => 'Medium', 2 => 'High' };

our $map_vra_status = {
    0 => 'Installed', 1 => 'UnsupportedEsxVersion', 2 => 'NotInstalled', 3 => 'Installing', 4 => 'Removing',
    5 => 'InstallationError', 6 => 'HostPasswordChanged', 7 => 'UpdatingIpSettings', 8 => 'DuringChangeHost',
    9 => 'HostInMaintenanceMode', 10 => 'HostEnteringMaintenanceMode'
};

our $map_alert_status = { 0 => 'Normal', 1 => 'Warning', 2 => 'Error' };

our $map_pairing_status = { 0 => 'Paired', 1 => 'Pairing', 2 => 'Unpaired' };

our $map_task_state = {
    0 => 'FirstUnusedValue', 1 => 'InProgress', 2 => 'WaitingForUserInput', 3 => 'Paused',
    4 => 'Failed', 5 => 'Stopped', 6 => 'Completed', 7 => 'Cancelling'
};

our $map_volume_type = { 0 => 'Protected', 1 => 'Recovery', 2 => 'Journal', 3 => 'Scratch', 6 => 'Appliances', 10 => 'Unknown' };

# returns the name of an enumeration value, the value is kept when it is already a name
sub enum_name {
    my (%options) = @_;

    return $options{default} // 'unknown' if !defined($options{value}) || $options{value} eq '';
    return $options{value} if $options{value} !~ /^\d+$/;

    return $options{map}->{$options{value}} // 'unknown(' . $options{value} . ')';
}

1;

__END__

=head1 NAME

Enumerations of the Zerto Virtual Manager REST API.

=cut
