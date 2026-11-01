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

package cloud::sangfor::scp::storage::mode::resources;

use strict;
use warnings;
use Exporter qw(import);
use centreon::plugins::misc qw(is_excluded is_not_empty);

our @EXPORT_OK = qw(get_storages);

# returns the selected storages (space in MB, IO in B/s)
sub get_storages {
    my (%options) = @_;

    my $opts = $options{option_results};
    my $results = [];
    foreach my $storage (@{$options{custom}->get_storages(az_id => $opts->{resource_pool_id}) // []}) {
        next unless ref($storage) eq 'HASH' && is_not_empty($storage->{id});
        next if is_not_empty($opts->{id}) && $storage->{id} ne $opts->{id};
        my $name = $storage->{name} // $storage->{id};
        next if is_excluded($name, $opts->{include_name}, $opts->{exclude_name}, output => $options{output});
        next if is_excluded($storage->{type} // '', $opts->{include_type}, $opts->{exclude_type}, output => $options{output});

        push @$results, {
            id          => $storage->{id},
            name        => $name,
            type        => $storage->{type} // '',
            status      => $storage->{status} // 'unknown',
            az_id       => $storage->{az_id} // '',
            storage     => { used => $storage->{used_mb}, total => $storage->{total_mb} },
            io          => {
                read      => $storage->{read_byteps},
                write     => $storage->{write_byteps},
                max_read  => $storage->{max_read_byteps},
                max_write => $storage->{max_write_byteps}
            }
        };
    }

    $options{output}->option_exit(short_msg => 'No storage found.')
        unless @$results;

    return $results;
}

1;
