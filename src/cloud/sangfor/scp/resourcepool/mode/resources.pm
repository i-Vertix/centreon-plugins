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

package cloud::sangfor::scp::resourcepool::mode::resources;

use strict;
use warnings;
use Exporter qw(import);
use centreon::plugins::misc qw(is_excluded is_not_empty);

our @EXPORT_OK = qw(get_resource_pools);

# returns the selected resource pools. With 'details', the physical resources (cpu in MHz,
# memory and storage in MB) are added: they are only returned by the resource pool details endpoint.
sub get_resource_pools {
    my (%options) = @_;

    my $opts = $options{option_results};
    my $list = is_not_empty($opts->{id})
        ? [ $options{custom}->get_resource_pool(id => $opts->{id}) ]
        : $options{custom}->get_resource_pools();

    my $results = [];
    foreach my $pool (@{$list // []}) {
        next unless ref($pool) eq 'HASH' && is_not_empty($pool->{id});
        next if is_not_empty($opts->{id}) && $pool->{id} ne $opts->{id};
        my $name = $pool->{name} // $pool->{id};
        next if is_excluded($name, $opts->{include_name}, $opts->{exclude_name}, output => $options{output});

        $pool = $options{custom}->get_resource_pool(id => $pool->{id})
            if $options{details} && !defined($pool->{physical_resources});

        my $entry = {
            id      => $pool->{id},
            name    => $name,
            status  => $pool->{status} // 'unknown',
            type    => $pool->{type} // '',
            tag     => $pool->{tag} // '',
            version => $pool->{version} // ''
        };
        foreach my $resource (@{$pool->{physical_resources} // []}) {
            next unless ref($resource) eq 'HASH' && defined($resource->{name});
            $entry->{lc($resource->{name})} = { total => $resource->{total}, used => $resource->{used} };
        }
        push @$results, $entry;
    }

    $options{output}->option_exit(short_msg => 'No resource pool found.')
        unless @$results;

    return $results;
}

1;
