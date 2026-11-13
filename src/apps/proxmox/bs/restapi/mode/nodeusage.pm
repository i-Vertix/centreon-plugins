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

package apps::proxmox::bs::restapi::mode::nodeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(change_seconds);

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_value . ' ' . $total_unit,
        $used_value . ' ' . $used_unit, $self->{result_values}->{prct_used},
        $free_value . ' ' . $free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_uptime_output {
    my ($self, %options) = @_;

    return 'uptime: ' . ($self->{result_values}->{uptime} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{uptime}));
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return 'Memory ';
}

sub prefix_swap_output {
    my ($self, %options) = @_;

    return 'Swap ';
}

sub prefix_root_output {
    my ($self, %options) = @_;

    return 'Root filesystem ';
}

# usage counters: used bytes, free bytes and used percentage of a memory or filesystem
sub usage_counters {
    my ($self, %options) = @_;

    my @keys = ({ name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' });

    return [
        { label => $options{label} . '-usage', nlabel => $options{nlabel} . '.usage.bytes', set => {
                key_values            => [ @keys ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', unit => 'B', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => $options{label} . '-usage-free', nlabel => $options{nlabel} . '.free.bytes', display_ok => 0, set => {
                key_values            => [ $keys[1], $keys[0], @keys[2..4] ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', unit => 'B', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => $options{label} . '-usage-prct', nlabel => $options{nlabel} . '.usage.percentage', display_ok => 0, set => {
                key_values            => [ $keys[2], @keys[0..1], @keys[3..4] ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } },
        { name => 'memory', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_memory_output', skipped_code => { NO_VALUE() => 1 } },
        { name => 'swap', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_swap_output', skipped_code => { NO_VALUE() => 1 } },
        { name => 'root', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_root_output', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-usage', nlabel => 'node.cpu.utilization.percentage', set => {
                key_values      => [ { name => 'cpu' } ],
                output_template => 'CPU usage: %.2f %%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'cpu-iowait', nlabel => 'node.cpu.iowait.percentage', set => {
                key_values      => [ { name => 'wait' } ],
                output_template => 'CPU I/O wait: %.2f %%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        },
        { label => 'load1', nlabel => 'node.load.1m.average.count', set => {
                key_values      => [ { name => 'load1' } ],
                output_template => 'load average: %.2f',
                perfdatas       => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'load5', nlabel => 'node.load.5m.average.count', set => {
                key_values      => [ { name => 'load5' } ],
                output_template => '%.2f',
                perfdatas       => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'load15', nlabel => 'node.load.15m.average.count', set => {
                key_values      => [ { name => 'load15' } ],
                output_template => '%.2f',
                perfdatas       => [
                    { template => '%.2f', min => 0 }
                ]
            }
        },
        { label => 'uptime', nlabel => 'node.uptime.seconds', set => {
                key_values            => [ { name => 'uptime' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                perfdatas             => [
                    { template => '%d', unit => 's', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = $self->usage_counters(label => 'memory', nlabel => 'node.memory');
    $self->{maps_counters}->{swap} = $self->usage_counters(label => 'swap', nlabel => 'node.swap');
    $self->{maps_counters}->{root} = $self->usage_counters(label => 'root', nlabel => 'node.rootfs');
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

# returns the usage values, or no value if the total is unknown or 0 (e.g. no swap)
sub usage_values {
    my ($self, %options) = @_;

    my $total = $options{total} // 0;
    return {}
        if $total <= 0 || !defined($options{used});

    my $free = $options{free} // ($total - $options{used});
    $free = 0 if $free < 0;

    return {
        total     => $total,
        used      => $options{used},
        free      => $free,
        prct_used => $options{used} * 100 / $total,
        prct_free => $free * 100 / $total
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $status = $options{custom}->get_node_status();

    my $loadavg = ref($status->{loadavg}) eq 'ARRAY' ? $status->{loadavg} : [];
    $self->{cpu} = {
        cpu    => defined($status->{cpu}) ? $status->{cpu} * 100 : undef,
        wait   => defined($status->{wait}) ? $status->{wait} * 100 : undef,
        load1  => $loadavg->[0],
        load5  => $loadavg->[1],
        load15 => $loadavg->[2],
        uptime => $status->{uptime}
    };

    # the 'free' memory of the API does not count the page cache: free is total minus used
    $self->{memory} = $self->usage_values(total => $status->{memory}->{total}, used => $status->{memory}->{used});
    $self->{swap} = $self->usage_values(total => $status->{swap}->{total}, used => $status->{swap}->{used});
    # free space of the root filesystem is the space available to unprivileged users
    $self->{root} = $self->usage_values(total => $status->{root}->{total}, used => $status->{root}->{used}, free => $status->{root}->{avail});
}

1;

__END__

=head1 MODE

Check the node usage: CPU, I/O wait, load average, uptime, memory, swap and root filesystem.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used), e.g. C<cpu|memory>.

=item B<--warning-cpu-usage>

Threshold for the CPU usage in percent.

=item B<--critical-cpu-usage>

Threshold for the CPU usage in percent.

=item B<--warning-cpu-iowait>

Threshold for the CPU I/O wait in percent.

=item B<--critical-cpu-iowait>

Threshold for the CPU I/O wait in percent.

=item B<--warning-load1>

Threshold for the load average over 1 minute.

=item B<--critical-load1>

Threshold for the load average over 1 minute.

=item B<--warning-load5>

Threshold for the load average over 5 minutes.

=item B<--critical-load5>

Threshold for the load average over 5 minutes.

=item B<--warning-load15>

Threshold for the load average over 15 minutes.

=item B<--critical-load15>

Threshold for the load average over 15 minutes.

=item B<--warning-uptime>

Threshold for the uptime in seconds.

=item B<--critical-uptime>

Threshold for the uptime in seconds.

=item B<--warning-memory-usage>

Threshold for the used memory in bytes.

=item B<--critical-memory-usage>

Threshold for the used memory in bytes.

=item B<--warning-memory-usage-free>

Threshold for the free memory in bytes.

=item B<--critical-memory-usage-free>

Threshold for the free memory in bytes.

=item B<--warning-memory-usage-prct>

Threshold for the used memory in percent.

=item B<--critical-memory-usage-prct>

Threshold for the used memory in percent.

=item B<--warning-swap-usage>

Threshold for the used swap in bytes.

=item B<--critical-swap-usage>

Threshold for the used swap in bytes.

=item B<--warning-swap-usage-free>

Threshold for the free swap in bytes.

=item B<--critical-swap-usage-free>

Threshold for the free swap in bytes.

=item B<--warning-swap-usage-prct>

Threshold for the used swap in percent.

=item B<--critical-swap-usage-prct>

Threshold for the used swap in percent.

=item B<--warning-root-usage>

Threshold for the used space of the root filesystem in bytes.

=item B<--critical-root-usage>

Threshold for the used space of the root filesystem in bytes.

=item B<--warning-root-usage-free>

Threshold for the free space of the root filesystem in bytes.

=item B<--critical-root-usage-free>

Threshold for the free space of the root filesystem in bytes.

=item B<--warning-root-usage-prct>

Threshold for the used space of the root filesystem in percent.

=item B<--critical-root-usage-prct>

Threshold for the used space of the root filesystem in percent.

=back

=cut
