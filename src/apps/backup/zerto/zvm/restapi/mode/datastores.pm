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

package apps::backup::zerto::zvm::restapi::mode::datastores;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "health: %s, availability: %s",
        $self->{result_values}->{health_status},
        $self->{result_values}->{availability_status}
    );
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

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Datastores ';
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "Datastore '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'datastores',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_datastore_output',
            message_multiple => 'All datastores are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'datastores-total', nlabel => 'datastores.total.count', display_ok => 0, set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{datastores} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{health_status} =~ /Warning/i || %{availability_status} =~ /Maintenance/i',
            critical_default => '%{health_status} =~ /Error/i || %{availability_status} =~ /Unavailable/i',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'id' }, { name => 'cluster' }, { name => 'health_status' }, { name => 'availability_status' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'datastore.space.usage.bytes', set => {
                key_values            => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', unit => 'B', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'datastore.space.free.bytes', display_ok => 0, set => {
                key_values            => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', unit => 'B', min => 0, max => 'total', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'datastore.space.usage.percentage', display_ok => 0, set => {
                key_values            => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'journal-used', nlabel => 'datastore.zerto.journal.used.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'journal_used' }, { name => 'name' } ],
                output_template     => 'journal used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'recovery-used', nlabel => 'datastore.zerto.recovery.used.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'recovery_used' }, { name => 'name' } ],
                output_template     => 'recovery used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'incoming-vms', nlabel => 'datastore.vms.incoming.count', display_ok => 0, set => {
                key_values      => [ { name => 'incoming_vms' }, { name => 'name' } ],
                output_template => 'incoming VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'outgoing-vms', nlabel => 'datastore.vms.outgoing.count', display_ok => 0, set => {
                key_values      => [ { name => 'outgoing_vms' }, { name => 'name' } ],
                output_template => 'outgoing VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'vras', nlabel => 'datastore.vras.count', display_ok => 0, set => {
                key_values      => [ { name => 'vras' }, { name => 'name' } ],
                output_template => 'VRAs: %s',
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
        'include-name:s'    => { name => 'include_name', default => '' },
        'exclude-name:s'    => { name => 'exclude_name', default => '' },
        'include-cluster:s' => { name => 'include_cluster', default => '' },
        'exclude-cluster:s' => { name => 'exclude_cluster', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $datastores = $options{custom}->get_datastores();

    $self->{global} = { total => 0 };
    $self->{datastores} = {};

    foreach my $datastore (@$datastores) {
        my $id = $datastore->{DatastoreIdentifier} // '';
        my $name = $datastore->{DatastoreName} || $id;
        my $cluster = ref($datastore->{Config}->{OwningDatastoreCluster}) eq 'HASH'
            ? $datastore->{Config}->{OwningDatastoreCluster}->{DatastoreClusterName} // '' : '';

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($cluster, $self->{option_results}->{include_cluster}, $self->{option_results}->{exclude_cluster}, output => $self->{output});

        my $stats = $datastore->{Stats} // {};
        my $usage = $stats->{Usage}->{Datastore} // {};
        my $zerto = $stats->{Usage}->{Zerto} // {};
        my $entry = {
            id                  => $id,
            name                => $name,
            cluster             => $cluster,
            health_status       => $datastore->{Health}->{Status} // 'unknown',
            availability_status => $stats->{AvailabilityStatus} // 'unknown',
            journal_used        => $zerto->{Journal}->{UsedInBytes},
            recovery_used       => $zerto->{Recovery}->{UsedInBytes},
            incoming_vms        => $stats->{NumIncomingVMs},
            outgoing_vms        => $stats->{NumOutgoingVMs},
            vras                => $stats->{NumVRAs}
        };

        my ($total, $free) = ($usage->{CapacityInBytes}, $usage->{FreeInBytes});
        if ($total && $total > 0 && defined($free)) {
            $entry->{total} = $total;
            $entry->{free} = $free;
            $entry->{used} = $total - $free;
            $entry->{prct_used} = $entry->{used} * 100 / $total;
            $entry->{prct_free} = 100 - $entry->{prct_used};
        }

        $self->{datastores}->{$id} = $entry;
        $self->{global}->{total}++;
    }

    $self->{output}->option_exit(short_msg => 'No datastore found.')
        if $self->{global}->{total} == 0;
}

1;

__END__

=head1 MODE

Check the datastores seen by the Zerto Virtual Manager: health and availability status, space usage and space used by Zerto (journal and recovery volumes).

=over 8

=item B<--include-name>

Filter datastores by name (can be a regexp).

=item B<--exclude-name>

Exclude datastores by name (can be a regexp).

=item B<--include-cluster>

Filter datastores by datastore cluster name (can be a regexp).

=item B<--exclude-cluster>

Exclude datastores by datastore cluster name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{id}>, C<%{cluster}>, C<%{health_status}>, C<%{availability_status}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{health_status} =~ /Warning/i || %{availability_status} =~ /Maintenance/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{cluster}>, C<%{health_status}>, C<%{availability_status}>.
C<%{health_status}> can be: C<NotApplicable>, C<Error>, C<Normal>, C<Warning>.
C<%{availability_status}> can be: C<EnteringMaintenance>, C<InMaintenance>, C<Normal>, C<Unavailable>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{health_status} =~ /Error/i || %{availability_status} =~ /Unavailable/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{cluster}>, C<%{health_status}>, C<%{availability_status}>.

=item B<--warning-datastores-total>

Threshold for the total number of datastores.

=item B<--critical-datastores-total>

Threshold for the total number of datastores.

=item B<--warning-usage>

Threshold for the used space (in B).

=item B<--critical-usage>

Threshold for the used space (in B).

=item B<--warning-usage-free>

Threshold for the free space (in B).

=item B<--critical-usage-free>

Threshold for the free space (in B).

=item B<--warning-usage-prct>

Threshold for the used space (in %).

=item B<--critical-usage-prct>

Threshold for the used space (in %).

=item B<--warning-journal-used>

Threshold for the space used by Zerto journal volumes (in B).

=item B<--critical-journal-used>

Threshold for the space used by Zerto journal volumes (in B).

=item B<--warning-recovery-used>

Threshold for the space used by Zerto recovery volumes (in B).

=item B<--critical-recovery-used>

Threshold for the space used by Zerto recovery volumes (in B).

=item B<--warning-incoming-vms>

Threshold for the number of VMs recovered to the datastore.

=item B<--critical-incoming-vms>

Threshold for the number of VMs recovered to the datastore.

=item B<--warning-outgoing-vms>

Threshold for the number of VMs protected from the datastore.

=item B<--critical-outgoing-vms>

Threshold for the number of VMs protected from the datastore.

=item B<--warning-vras>

Threshold for the number of VRAs using the datastore.

=item B<--critical-vras>

Threshold for the number of VRAs using the datastore.

=back

=cut
