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

package cloud::sangfor::scp::cluster::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use cloud::sangfor::scp::cluster::mode::resources qw(get_clusters);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        'status: %s [type: %s] [version: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{version}
    );
}

sub prefix_cluster_output {
    my ($self, %options) = @_;
    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{clusters} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{status} !~ /normal/i',
            set              => {
                key_values                     => [ { name => 'id' }, { name => 'name' }, { name => 'status' }, { name => 'type' }, { name => 'version' }, { name => 'authorize_mode' } ],
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
        'id:s'               => { name => 'id', default => '' },
        'resource-pool-id:s' => { name => 'resource_pool_id', default => '' },
        'include-name:s'     => { name => 'include_name', default => '' },
        'exclude-name:s'     => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{clusters} = {
        map { $_->{id} => $_ } @{get_clusters(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}
    };
}

1;

__END__

=head1 MODE

Check the status of clusters.

=over 8

=item B<--id>

Define the ID of the cluster to check.

=item B<--resource-pool-id>

Only check the clusters of this resource pool ID.

=item B<--include-name>

Filter clusters by name (can be a regexp).

=item B<--exclude-name>

Exclude clusters by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{type}>, C<%{version}>, C<%{authorize_mode}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{type}>, C<%{version}>, C<%{authorize_mode}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} !~ /normal/i'>).
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{type}>, C<%{version}>, C<%{authorize_mode}>.
The status can be: C<normal>, C<offline>, C<unauthorized>, C<master_offline>, C<password_error>.

=back

=cut
