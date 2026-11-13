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

package apps::proxmox::bs::restapi::mode::snapshots;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded change_seconds);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::proxmox::bs::restapi::mode::resources qw(maintenance_type);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'last snapshot verification: ' . $self->{result_values}->{last_verify_state};
}

sub custom_age_output {
    my ($self, %options) = @_;

    return 'last snapshot: ' . ($self->{result_values}->{last_age} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{last_age})) . ' ago';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Backup groups ';
}

sub prefix_group_output {
    my ($self, %options) = @_;

    my $msg = "Backup group '" . $options{instance_value}->{type} . '/' . $options{instance_value}->{id} . "' [datastore: " . $options{instance_value}->{datastore} . ']';
    $msg .= ' [comment: ' . $options{instance_value}->{comment} . ']' if $options{instance_value}->{comment} ne '';

    return $msg . ' ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'groups',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_group_output',
            message_multiple => 'All backup groups are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'groups-total', nlabel => 'backupgroups.total.count', set => {
                key_values      => [ { name => 'groups' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'snapshots-total', nlabel => 'snapshots.total.count', set => {
                key_values      => [ { name => 'snapshots' } ],
                output_template => 'snapshots: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{groups} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{last_verify_state} eq "failed"',
            set              => {
                key_values                     => [
                    { name => 'datastore' }, { name => 'type' }, { name => 'id' }, { name => 'comment' },
                    { name => 'last_verify_state' }, { name => 'owner' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'last-age', nlabel => 'backupgroup.snapshot.last.age.seconds', set => {
                key_values            => [ { name => 'last_age' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_age_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'last-size', nlabel => 'backupgroup.snapshot.last.size.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'last_size' }, { name => 'display' } ],
                output_template     => 'last snapshot size: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'snapshots', nlabel => 'backupgroup.snapshots.count', display_ok => 0, set => {
                key_values      => [ { name => 'snapshots' }, { name => 'display' } ],
                output_template => 'snapshots: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'verify-failed', nlabel => 'backupgroup.snapshots.verify.failed.count', display_ok => 0, set => {
                key_values      => [ { name => 'verify_failed' }, { name => 'display' } ],
                output_template => 'snapshots with failed verification: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
        'include-datastore:s' => { name => 'include_datastore', default => '' },
        'exclude-datastore:s' => { name => 'exclude_datastore', default => '' },
        'include-type:s'      => { name => 'include_type', default => '' },
        'exclude-type:s'      => { name => 'exclude_type', default => '' },
        'include-id:s'        => { name => 'include_id', default => '' },
        'exclude-id:s'        => { name => 'exclude_id', default => '' },
        'include-comment:s'   => { name => 'include_comment', default => '' },
        'exclude-comment:s'   => { name => 'exclude_comment', default => '' },
        'namespace:s'         => { name => 'namespace', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $datastores = $options{custom}->get_datastores();

    my $current_time = time();
    my $datastores_found = 0;
    $self->{global} = { groups => 0, snapshots => 0 };
    $self->{groups} = {};
    foreach my $datastore (sort { ($a->{store} // '') cmp ($b->{store} // '') } @$datastores) {
        my $store = $datastore->{store} // next;
        next if is_excluded($store, $self->{option_results}->{include_datastore}, $self->{option_results}->{exclude_datastore}, output => $self->{output});
        $datastores_found++;

        # the snapshots of an unmounted or offline datastore cannot be read
        my $maintenance = maintenance_type(value => $datastore->{maintenance});
        if (($datastore->{'mount-status'} // '') eq 'notmounted' || $maintenance =~ /^(?:offline|unmount|delete)$/) {
            $self->{output}->output_add(long_msg => "skipping datastore '$store': not mounted or in maintenance", debug => 1);
            next;
        }

        # a broken datastore (reported by the datastore-usage mode) must not hide the other ones
        my $snapshots = $options{custom}->get_snapshots(store => $store, namespace => $self->{option_results}->{namespace}, ignore_error => 1);
        unless (defined($snapshots)) {
            $self->{output}->output_add(long_msg => "skipping datastore '$store': cannot read its snapshots");
            next;
        }
        foreach my $snapshot (@$snapshots) {
            my ($type, $id, $time) = ($snapshot->{'backup-type'} // '', $snapshot->{'backup-id'} // '', $snapshot->{'backup-time'} // 0);
            my $comment = $snapshot->{comment} // '';

            next if is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});
            next if is_excluded($id, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
            next if is_excluded($comment, $self->{option_results}->{include_comment}, $self->{option_results}->{exclude_comment}, output => $self->{output});

            my $verify_state = ref($snapshot->{verification}) eq 'HASH' ? $snapshot->{verification}->{state} // 'none' : 'none';
            my $key = $store . '~' . $type . '/' . $id;
            my $group = $self->{groups}->{$key} //= {
                display       => $key,
                datastore     => $store,
                type          => $type,
                id            => $id,
                owner         => $snapshot->{owner} // '',
                snapshots     => 0,
                verify_failed => 0,
                last_time     => -1
            };

            $group->{snapshots}++;
            $group->{verify_failed}++ if $verify_state eq 'failed';
            $self->{global}->{snapshots}++;

            next if $time <= $group->{last_time};
            $group->{last_time} = $time;
            $group->{last_size} = $snapshot->{size};
            $group->{last_verify_state} = $verify_state;
            $group->{comment} = $comment;
        }
    }

    foreach my $group (values %{$self->{groups}}) {
        $group->{last_age} = $current_time > $group->{last_time} ? $current_time - $group->{last_time} : 0;
    }
    $self->{global}->{groups} = scalar(keys %{$self->{groups}});

    # no backup group (empty or unmounted datastore) is not an error: --critical-groups-total=1: alerts on it
    $self->{output}->option_exit(short_msg => 'No datastore found.')
        unless $datastores_found;
}

1;

__END__

=head1 MODE

Check the backup groups (all the snapshots of a VM, a container or a host) of the datastores:
age, size and verification of the last snapshot.
Unmounted datastores, datastores in C<offline>, C<unmount> or C<delete> maintenance
and datastores whose snapshots cannot be read are skipped (use the C<datastore-usage> mode to check them).
No backup group is not an error: use C<--critical-groups-total=1:> to alert on it.

=over 8

=item B<--include-datastore>

Filter datastores by name (can be a regexp).

=item B<--exclude-datastore>

Exclude datastores by name (can be a regexp).

=item B<--include-type>

Filter backup groups by type (can be a regexp): C<vm>, C<ct> or C<host>.

=item B<--exclude-type>

Exclude backup groups by type (can be a regexp).

=item B<--include-id>

Filter backup groups by ID (can be a regexp), e.g. the VM ID C<^157$>.

=item B<--exclude-id>

Exclude backup groups by ID (can be a regexp).

=item B<--include-comment>

Filter snapshots by comment (can be a regexp). The comment is usually the guest name.

=item B<--exclude-comment>

Exclude snapshots by comment (can be a regexp).

=item B<--namespace>

Define the datastore namespace to check (default: the root namespace).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{datastore}>, C<%{type}>, C<%{id}>, C<%{comment}>, C<%{last_verify_state}>, C<%{owner}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{datastore}>, C<%{type}>, C<%{id}>, C<%{comment}>, C<%{last_verify_state}>, C<%{owner}>.
C<%{last_verify_state}> can be: C<ok>, C<failed>, C<none> (not verified yet).

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{last_verify_state} eq "failed"'>).
You can use the following variables: C<%{datastore}>, C<%{type}>, C<%{id}>, C<%{comment}>, C<%{last_verify_state}>, C<%{owner}>.

=item B<--warning-groups-total>

Threshold for the number of backup groups.

=item B<--critical-groups-total>

Threshold for the number of backup groups.

=item B<--warning-snapshots-total>

Threshold for the number of snapshots of all the backup groups.

=item B<--critical-snapshots-total>

Threshold for the number of snapshots of all the backup groups.

=item B<--warning-last-age>

Threshold for the age of the last snapshot in seconds, e.g. C<93600> (26 hours).

=item B<--critical-last-age>

Threshold for the age of the last snapshot in seconds.

=item B<--warning-last-size>

Threshold for the size of the last snapshot in bytes.

=item B<--critical-last-size>

Threshold for the size of the last snapshot in bytes.

=item B<--warning-snapshots>

Threshold for the number of snapshots of a backup group.

=item B<--critical-snapshots>

Threshold for the number of snapshots of a backup group.

=item B<--warning-verify-failed>

Threshold for the number of snapshots of a backup group whose verification failed.

=item B<--critical-verify-failed>

Threshold for the number of snapshots of a backup group whose verification failed.

=back

=cut
