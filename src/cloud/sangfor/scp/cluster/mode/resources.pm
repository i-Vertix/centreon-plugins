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

package cloud::sangfor::scp::cluster::mode::resources;

use strict;
use warnings;
use Exporter qw(import);
use centreon::plugins::misc qw(is_excluded is_not_empty);

our @EXPORT_OK = qw(get_clusters);

# returns the selected clusters (cpu in MHz, memory and storage in MB)
sub get_clusters {
    my (%options) = @_;

    my $opts = $options{option_results};
    my $results = [];
    foreach my $cluster (@{$options{custom}->get_clusters(az_id => $opts->{resource_pool_id}) // []}) {
        next unless ref($cluster) eq 'HASH' && is_not_empty($cluster->{id});
        next if is_not_empty($opts->{id}) && $cluster->{id} ne $opts->{id};
        my $name = $cluster->{name} // $cluster->{id};
        next if is_excluded($name, $opts->{include_name}, $opts->{exclude_name}, output => $options{output});

        push @$results, {
            id             => $cluster->{id},
            name           => $name,
            status         => $cluster->{status} // 'unknown',
            type           => $cluster->{type} // '',
            version        => $cluster->{version} // '',
            authorize_mode => $cluster->{authorize_mode} // '',
            az_id          => $cluster->{az_id} // '',
            cpu            => { used => $cluster->{cpu}->{used_mhz}, total => $cluster->{cpu}->{total_mhz} },
            memory         => { used => $cluster->{memory}->{used_mb}, total => $cluster->{memory}->{total_mb} },
            storage        => { used => $cluster->{storage}->{used_mb}, total => $cluster->{storage}->{total_mb} }
        };
    }

    $options{output}->option_exit(short_msg => 'No cluster found.')
        unless @$results;

    return $results;
}

1;
