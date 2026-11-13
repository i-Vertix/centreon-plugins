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

package apps::proxmox::bs::restapi::mode::datastoreusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded is_not_empty change_seconds);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::proxmox::bs::restapi::mode::resources qw(maintenance_type upid_starttime);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'mount status: ' . $self->{result_values}->{mount_status};
    $msg .= ', maintenance: ' . $self->{result_values}->{maintenance} if $self->{result_values}->{maintenance} ne '';
    $msg .= ', error: ' . $self->{result_values}->{error} if $self->{result_values}->{error} ne '';

    return $msg;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_value . ' ' . $total_unit,
        $used_value . ' ' . $used_unit, $self->{result_values}->{prct_used},
        $free_value . ' ' . $free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_gc_age_output {
    my ($self, %options) = @_;

    return 'last garbage collection: ' . ($self->{result_values}->{gc_age} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{gc_age})) . ' ago';
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "Datastore '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'datastores',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_datastore_output',
            message_multiple => 'All datastores are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    my @usage_keys = ({ name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' });

    $self->{maps_counters}->{datastores} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{mount_status} eq "notmounted" or %{maintenance} ne ""',
            critical_default => '%{error} ne ""',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'backend_type' }, { name => 'mount_status' }, { name => 'maintenance' }, { name => 'error' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'datastore.space.usage.bytes', set => {
                key_values            => [ @usage_keys ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', unit => 'B', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'datastore.space.free.bytes', display_ok => 0, set => {
                key_values            => [ $usage_keys[1], $usage_keys[0], @usage_keys[2..5] ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', unit => 'B', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'datastore.space.usage.percentage', display_ok => 0, set => {
                key_values            => [ $usage_keys[2], @usage_keys[0..1], @usage_keys[3..5] ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'estimated-full', nlabel => 'datastore.space.full.estimated.days', set => {
                key_values      => [ { name => 'full_days' }, { name => 'name' } ],
                output_template => 'estimated full in: %d days',
                perfdatas       => [
                    { template => '%d', unit => 'd', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'deduplication-factor', nlabel => 'datastore.deduplication.factor.count', set => {
                key_values      => [ { name => 'dedup_factor' }, { name => 'name' } ],
                output_template => 'deduplication factor: %.2f',
                perfdatas       => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'gc-pending', nlabel => 'datastore.gc.pending.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'gc_pending' }, { name => 'name' } ],
                output_template     => 'garbage collection pending: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'gc-last-age', nlabel => 'datastore.gc.last.age.seconds', display_ok => 0, set => {
                key_values            => [ { name => 'gc_age' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_gc_age_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'chunks-bad', nlabel => 'datastore.chunks.bad.count', set => {
                key_values      => [ { name => 'chunks_bad' }, { name => 'name' } ],
                output_template => 'bad chunks: %s',
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
        'include-name:s'         => { name => 'include_name', default => '' },
        'exclude-name:s'         => { name => 'exclude_name', default => '' },
        'include-backend-type:s' => { name => 'include_backend_type', default => '' },
        'exclude-backend-type:s' => { name => 'exclude_backend_type', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $usages = $options{custom}->get_datastores_usage();
    # the configuration gives the maintenance mode, missing from the usage
    my %configs = map { ($_->{store} // '') => $_ } @{$options{custom}->get_datastores()};

    my $current_time = time();
    $self->{datastores} = {};
    foreach my $usage (@$usages) {
        my $name = $usage->{store} // next;
        my $config = $configs{$name} // {};
        my $backend_type = $usage->{'backend-type'} // $config->{'backend-type'} // 'filesystem';

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($backend_type, $self->{option_results}->{include_backend_type}, $self->{option_results}->{exclude_backend_type}, output => $self->{output});

        my $datastore = {
            name         => $name,
            backend_type => $backend_type,
            mount_status => $usage->{'mount-status'} // $config->{'mount-status'} // 'nonremovable',
            maintenance  => maintenance_type(value => $config->{maintenance}),
            error        => $usage->{error} // ''
        };

        # avail is -1 if the datastore cannot be read
        my ($total, $used, $avail) = map { $usage->{$_} } qw/total used avail/;
        if (defined($total) && $total > 0 && defined($used) && defined($avail) && $avail >= 0) {
            $datastore->{total} = $total;
            $datastore->{used} = $used;
            $datastore->{free} = $avail;
            $datastore->{prct_used} = $used * 100 / $total;
            $datastore->{prct_free} = $avail * 100 / $total;
        }

        # an estimate in the past means the usage does not grow
        my $full_date = $usage->{'estimated-full-date'};
        $datastore->{full_days} = ($full_date - $current_time) / 86400
            if defined($full_date) && $full_date > $current_time;

        my $gc = ref($usage->{'gc-status'}) eq 'HASH' ? $usage->{'gc-status'} : {};
        # no garbage collection run yet: no upid and no statistics
        if (is_not_empty($gc->{upid})) {
            $datastore->{gc_pending} = $gc->{'pending-bytes'};
            $datastore->{chunks_bad} = $gc->{'still-bad'};
            $datastore->{dedup_factor} = $gc->{'index-data-bytes'} / $gc->{'disk-bytes'}
                if defined($gc->{'index-data-bytes'}) && ($gc->{'disk-bytes'} // 0) > 0;
            my $gc_start = upid_starttime(value => $gc->{upid});
            $datastore->{gc_age} = $current_time > $gc_start ? $current_time - $gc_start : 0
                if defined($gc_start);
        }

        $self->{datastores}->{$name} = $datastore;
    }

    $self->{output}->option_exit(short_msg => 'No datastore found.')
        unless keys %{$self->{datastores}};
}

1;

__END__

=head1 MODE

Check the datastores: status, space usage, estimated full date, deduplication factor and garbage collection.

=over 8

=item B<--include-name>

Filter datastores by name (can be a regexp).

=item B<--exclude-name>

Exclude datastores by name (can be a regexp).

=item B<--include-backend-type>

Filter datastores by backend type (can be a regexp): C<filesystem> or C<s3>.

=item B<--exclude-backend-type>

Exclude datastores by backend type (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{backend_type}>, C<%{mount_status}>, C<%{maintenance}>, C<%{error}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{mount_status} eq "notmounted" or %{maintenance} ne ""'>).
You can use the following variables: C<%{name}>, C<%{backend_type}>, C<%{mount_status}>, C<%{maintenance}>, C<%{error}>.
C<%{mount_status}> can be: C<mounted>, C<notmounted>, C<nonremovable>.
C<%{maintenance}> is empty or the maintenance type: C<read-only>, C<offline>, C<delete>, C<unmount>, C<s3-refresh>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{error} ne ""'>).
You can use the following variables: C<%{name}>, C<%{backend_type}>, C<%{mount_status}>, C<%{maintenance}>, C<%{error}>.

=item B<--warning-usage>

Threshold for the used space in bytes.

=item B<--critical-usage>

Threshold for the used space in bytes.

=item B<--warning-usage-free>

Threshold for the free space in bytes.

=item B<--critical-usage-free>

Threshold for the free space in bytes.

=item B<--warning-usage-prct>

Threshold for the used space in percent.

=item B<--critical-usage-prct>

Threshold for the used space in percent.

=item B<--warning-estimated-full>

Threshold for the number of days until the datastore is estimated full, e.g. C<30:>.
No value if PBS has no estimate or the usage does not grow.

=item B<--critical-estimated-full>

Threshold for the number of days until the datastore is estimated full, e.g. C<7:>.

=item B<--warning-deduplication-factor>

Threshold for the deduplication factor (data referenced by the backups divided by the data on disk).

=item B<--critical-deduplication-factor>

Threshold for the deduplication factor.

=item B<--warning-gc-pending>

Threshold for the bytes pending removal after the last garbage collection.

=item B<--critical-gc-pending>

Threshold for the bytes pending removal after the last garbage collection.

=item B<--warning-gc-last-age>

Threshold for the time in seconds since the start of the last garbage collection.

=item B<--critical-gc-last-age>

Threshold for the time in seconds since the start of the last garbage collection.

=item B<--warning-chunks-bad>

Threshold for the number of chunks still marked as bad after the last garbage collection.

=item B<--critical-chunks-bad>

Threshold for the number of chunks still marked as bad after the last garbage collection.

=back

=cut
