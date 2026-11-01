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

package cloud::sangfor::scp::management::mode::resources;

use strict;
use warnings;
use Exporter qw(import);
use centreon::plugins::misc qw(is_not_empty);

our @EXPORT_OK = qw(get_resources %resource_labels);

# attributes returned for each resource type (used by the list and discovery modes)
our %resource_labels = (
    resourcepool => [ qw(id name status type tag version) ],
    cluster      => [ qw(id name status type version az_id az_name) ],
    host         => [ qw(id name ip status type cpu_type az_id az_name) ],
    vm           => [ qw(id name status power_state ip os_name os_type host_id host_name az_id az_name project_name description) ],
    storage      => [ qw(id name status type az_id az_name) ]
);

sub get_vm_ip {
    my (%options) = @_;

    foreach my $network (@{$options{vm}->{networks} // []}) {
        return $network->{ip_address} if ref($network) eq 'HASH' && is_not_empty($network->{ip_address});
    }
    foreach my $ip (@{$options{vm}->{ips} // []}) {
        return $ip if !ref($ip) && is_not_empty($ip);
        return $ip->{ip_address} // $ip->{ip} if ref($ip) eq 'HASH' && is_not_empty($ip->{ip_address} // $ip->{ip});
    }
    return '';
}

# returns the resources of a type as a list of flat hashes (sorted by name)
sub get_resources {
    my (%options) = @_;

    my $type = $options{type};
    my $custom = $options{custom};

    my $pools = $custom->get_resource_pools();
    my %az_names = map { $_->{id} => $_->{name} // '' } grep { ref($_) eq 'HASH' && defined($_->{id}) } @{$pools // []};

    my $items = $type eq 'resourcepool' ? $pools
        : $type eq 'cluster' ? $custom->get_clusters()
        : $type eq 'host' ? $custom->get_hosts()
        : $type eq 'storage' ? $custom->get_storages()
        : $custom->get_vms();

    my $results = [];
    foreach my $item (@{$items // []}) {
        next unless ref($item) eq 'HASH' && is_not_empty($item->{id});

        my $entry = { %$item };
        $entry->{name} //= $item->{id};
        $entry->{az_name} = $item->{az_name} || $az_names{$item->{az_id} // ''} // '';
        if ($type eq 'host') {
            $entry->{cpu_type} = ref($item->{cpu}) eq 'HASH' ? ($item->{cpu}->{type} // '') : '';
        } elsif ($type eq 'vm') {
            $entry->{ip} = get_vm_ip(vm => $item);
        }

        push @$results, { map { $_ => (defined($entry->{$_}) && !ref($entry->{$_}) ? $entry->{$_} : '') } @{$resource_labels{$type}} };
    }

    return [ sort { $a->{name} cmp $b->{name} } @$results ];
}

1;
