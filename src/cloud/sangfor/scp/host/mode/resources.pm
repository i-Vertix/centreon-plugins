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

package cloud::sangfor::scp::host::mode::resources;

use strict;
use warnings;
use Exporter qw(import);
use centreon::plugins::misc qw(is_excluded is_not_empty);

our @EXPORT_OK = qw(get_hosts);

# returns the selected physical hosts (cpu in MHz, memory in MB)
sub get_hosts {
    my (%options) = @_;

    my $opts = $options{option_results};
    my $results = [];
    foreach my $host (@{$options{custom}->get_hosts(az_id => $opts->{resource_pool_id}) // []}) {
        next unless ref($host) eq 'HASH' && is_not_empty($host->{id});
        next if is_not_empty($opts->{id}) && $host->{id} ne $opts->{id};
        my $name = $host->{name} // $host->{id};
        next if is_excluded($name, $opts->{include_name}, $opts->{exclude_name}, output => $options{output});

        push @$results, {
            id          => $host->{id},
            name        => $name,
            ip          => $host->{ip} // '',
            status      => $host->{status} // 'unknown',
            type        => $host->{type} // '',
            az_id       => $host->{az_id} // '',
            alarm_count => $host->{alarm_count},
            cpu         => { used => $host->{cpu}->{used_mhz}, total => $host->{cpu}->{total_mhz} },
            memory      => { used => $host->{memory}->{used_mb}, total => $host->{memory}->{total_mb} }
        };
    }

    $options{output}->option_exit(short_msg => 'No host found.')
        unless @$results;

    return $results;
}

1;
