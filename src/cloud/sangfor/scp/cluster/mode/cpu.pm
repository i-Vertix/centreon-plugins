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

package cloud::sangfor::scp::cluster::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use cloud::sangfor::scp::cluster::mode::resources qw(get_clusters);

sub prefix_cluster_output {
    my ($self, %options) = @_;
    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters CPU usages are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{clusters} = [
        { label => 'cpu-usage-prct', nlabel => 'cluster.cpu.utilization.percentage', set => {
                key_values      => [ { name => 'used_prct' }, { name => 'name' } ],
                output_template => 'CPU usage: %.2f %%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'cpu-usage', nlabel => 'cluster.cpu.utilization.mhz', set => {
                key_values      => [ { name => 'used' }, { name => 'total' }, { name => 'name' } ],
                output_template => 'CPU used: %.2f MHz',
                perfdatas       => [
                    { template => '%.2f', unit => 'MHz', min => 0, max => 'total', label_extra_instance => 1, instance_use => 'name' }
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
        'id:s'           => { name => 'id', default => '' },
        'resource-pool-id:s' => { name => 'resource_pool_id', default => '' },
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{clusters} = {};
    foreach my $entry (@{get_clusters(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}) {
        my $cpu = $entry->{cpu} // {};
        $self->{clusters}->{$entry->{id}} = {
            name      => $entry->{name},
            used      => $cpu->{used},
            total     => $cpu->{total},
            used_prct => $cpu->{prct} // (defined($cpu->{used}) && $cpu->{total} ? $cpu->{used} * 100 / $cpu->{total} : undef)
        };
    }

    $self->{output}->option_exit(short_msg => 'No CPU usage found.')
        unless %{$self->{clusters}};
}

1;

__END__

=head1 MODE

Check the CPU usage of clusters.

=over 8

=item B<--id>

Define the ID of the cluster to check.

=item B<--resource-pool-id>

Only check the clusters of this resource pool ID.

=item B<--include-name>

Filter clusters by name (can be a regexp).

=item B<--exclude-name>

Exclude clusters by name (can be a regexp).

=item B<--warning-cpu-usage-prct>

Threshold for the CPU usage (in %).

=item B<--critical-cpu-usage-prct>

Threshold for the CPU usage (in %).

=item B<--warning-cpu-usage>

Threshold for the CPU used (in MHz).

=item B<--critical-cpu-usage>

Threshold for the CPU used (in MHz).

=back

=cut
