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

package cloud::sangfor::scp::vm::mode::resources;

use strict;
use warnings;
use Exporter qw(import);
use centreon::plugins::misc qw(is_excluded is_not_empty);

our @EXPORT_OK = qw(get_vms);

# returns the selected virtual machines (cpu in MHz, memory and storage in MB, disk in B/s, network in b/s)
sub get_vms {
    my (%options) = @_;

    my $opts = $options{option_results};
    my $results = [];
    foreach my $vm (@{$options{custom}->get_vms(ids => $opts->{id}, az_id => $opts->{resource_pool_id}) // []}) {
        next unless ref($vm) eq 'HASH' && is_not_empty($vm->{id});
        next if is_not_empty($opts->{id}) && $vm->{id} ne $opts->{id};
        my $name = $vm->{name} // $vm->{id};
        next if is_excluded($name, $opts->{include_name}, $opts->{exclude_name}, output => $options{output});

        my ($alarm, $warning) = ($vm->{alarm} // {}, $vm->{warning} // {});
        push @$results, {
            id          => $vm->{id},
            name        => $name,
            status      => $vm->{status} // 'unknown',
            power_state => $vm->{power_state} // 'unknown',
            alarm       => ref($alarm) eq 'HASH' && $alarm->{alarm} ? 'yes' : 'no',
            warning     => ref($warning) eq 'HASH' && $warning->{warning} ? ($warning->{warning_info} || $warning->{warning_type} || 'yes') : 'no',
            uptime      => $vm->{uptime},
            host_name   => $vm->{host_name} // '',
            az_name     => $vm->{az_name} // '',
            cpu         => { used => $vm->{cpu_status}->{used_mhz}, total => $vm->{cpu_status}->{total_mhz} },
            memory      => { used => $vm->{memory_status}->{used_mb}, total => $vm->{memory_status}->{total_mb} },
            storage     => { used => $vm->{storage_status}->{used_mb}, total => $vm->{storage_status}->{total_mb} },
            disk        => {
                read      => $vm->{io_status}->{read_speed_byteps},
                write     => $vm->{io_status}->{write_speed_byteps},
                read_ops  => $vm->{io_status}->{read_iops},
                write_ops => $vm->{io_status}->{write_iops}
            },
            network     => {
                in  => $vm->{network_status}->{read_speed_bitps},
                out => $vm->{network_status}->{write_speed_bitps}
            }
        };
    }

    $options{output}->option_exit(short_msg => 'No VM found.')
        unless @$results;

    return $results;
}

1;
