#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package ivertix::plugins::hardware::devices::infinitys::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Date::Parse;
use DateTime::Format::Strptime;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'device', type => 1, cb_prefix_output => 'prefix_output', skipped_code => { -10 => 1 } },
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-online', nlabel => 'devices.total.online.count', display_ok => 1, set => {
            key_values            => [ { name => 'online' }, { name => 'total' }, { name => 'online_prct' } ],
            closure_custom_output => $self->can('custom_online_output'),
            perfdatas             => [
                { template => '%s', min => 0, max => 'total' }
            ]
        }
        },
        { label => 'total-online-prct', nlabel => 'devices.total.online.percentage', display_ok => 0, set => {
            key_values            => [ { name => 'online_prct' }, { name => 'online' }, { name => 'total' } ],
            closure_custom_output => $self->can('custom_online_output_prct'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        },
        { label => 'total-offline', nlabel => 'devices.total.offline.count', display_ok => 0, set => {
            key_values            => [ { name => 'offline' }, { name => 'total' }, { name => 'offline_prct' } ],
            closure_custom_output => $self->can('custom_offline_output'),
            perfdatas             => [
                { template => '%s', min => 0, max => 'total' }
            ]
        }
        },
        { label => 'total-offline-prct', nlabel => 'devices.total.offline.percentage', display_ok => 0, set => {
            key_values            => [ { name => 'offline_prct' }, { name => 'offline' }, { name => 'total' } ],
            closure_custom_output => $self->can('custom_offline_output_prct'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        }
    ];

    $self->{maps_counters}->{device} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /online/i', set => {
            key_values                     => [ { name => 'status' }, { name => 'display' } ],
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold_ng
        }
        },
        { label => 'cpu', display_ok => 0, nlabel => 'cpu.percentage', set => {
            key_values      => [ { name => 'cpu' }, { name => 'display' } ],
            output_template => 'CPU usage : %.2f%%',
            perfdatas       => [
                { label => 'cpu', value => 'cpu', template => '%.2f',
                    min => 0, max => 100, unit => '%', label_extra_instance => 1 },
            ],
        }
        },
        { label => 'memory', display_ok => 0, nlabel => 'memory.usage.bytes', set => {
            key_values            =>
                [
                    { name => 'memory_used' },
                    { name => 'memory_free' },
                    { name => 'memory_total' },
                    { name => 'memory_used_prct' },
                    { name => 'memory_prct_free' }
                ],
            closure_custom_output => $self->can('custom_memory_output'),
            perfdatas             => [
                { value                  => 'memory_used',
                    template             => '%d',
                    min                  => 0,
                    max                  => 'memory_total',
                    unit                 => 'B',
                    cast_int             => 1,
                    label_extra_instance => 1
                }
            ]
        }
        },
        { label => 'memory-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
            key_values            =>
                [
                    { name => 'memory_free' },
                    { name => 'memory_used' },
                    { name => 'memory_total' },
                    { name => 'memory_used_prct' },
                    { name => 'memory_prct_free' }
                ],
            closure_custom_output => $self->can('custom_memory_output'),
            perfdatas             =>
                [
                    { value                  => 'memory_free',
                        template             => '%d',
                        min                  => 0,
                        max                  => 'memory_total',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1 }
                ]
        }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
            key_values            =>
                [
                    { name => 'memory_used_prct' },
                    { name => 'memory_used' },
                    { name => 'memory_total' },
                    { name => 'memory_free' },
                    { name => 'memory_prct_free' },
                    { name => 'memory_total' }
                ],
            closure_custom_output =>
                $self->can('custom_memory_output'),
            perfdatas             =>
                [
                    { value => 'memory_used_prct', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
        }
        },
        { label => 'storage', display_ok => 0, nlabel => 'storage.usage.bytes', set => {
            key_values            =>
                [
                    { name => 'storage_used' },
                    { name => 'storage_free' },
                    { name => 'storage_total' },
                    { name => 'storage_used_prct' },
                    { name => 'storage_prct_free' }
                ],
            closure_custom_output =>
                $self->can('custom_storage_output'),
            perfdatas             =>
                [
                    { value                  => 'storage_used',
                        template             => '%d',
                        min                  => 0,
                        max                  => 'memory_total',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1
                    }
                ]
        }
        },
        { label => 'storage-free', display_ok => 0, nlabel => 'storage.free.bytes', set => {
            key_values            =>
                [
                    { name => 'storage_free' },
                    { name => 'storage_used' },
                    { name => 'storage_total' },
                    { name => 'storage_used_prct' },
                    { name => 'storage_prct_free' }
                ],
            closure_custom_output =>
                $self->can('custom_storage_output'),
            perfdatas             =>
                [
                    { value                  => 'storage_free',
                        template             => '%d',
                        min                  => 0,
                        max                  => 'memory_total',
                        unit                 => 'B',
                        cast_int             => 1,
                        label_extra_instance => 1 }
                ]
        }
        },
        { label => 'storage-usage-prct', display_ok => 0, nlabel => 'storage.usage.percentage', set => {
            key_values            =>
                [
                    { name => 'storage_used_prct' },
                    { name => 'storage_used' },
                    { name => 'storage_total' },
                    { name => 'storage_free' },
                    { name => 'storage_prct_free' }
                ],
            closure_custom_output =>
                $self->can('custom_storage_output'),
            perfdatas             =>
                [
                    { value => 'storage_used_prct', template => '%.2f',
                        min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
        }
        },
        { label => 'uptime', display_ok => 0, nlabel => 'uptime.seconds', set => {
            key_values      => [ { name => 'upTime' }, { name => 'display' } ],
            output_template => 'uptime: %s',
            output_use      => 'upTime',
            perfdatas       => [
                { value  => 'upTime', template => '%s',
                    unit => 's' },
            ],
        }
        },
        { label => 'last-update', display_ok => 0, nlabel => 'last-update.seconds', set => {
            key_values      => [ { name => 'last_update_seconds_ago' }, { name => 'display' } ],
            output_template => 'last_update_seconds_ago: %s',
            output_use      => 'last_update_seconds_ago',
        }
        },
    ];
}

sub custom_online_output_prct {
    my ($self, %options) = @_;

    return sprintf(
        'Devices online %.2f%% (%s on %s)',
        $self->{result_values}->{online_prct},
        $self->{result_values}->{online},
        $self->{result_values}->{total},
    );
}

sub custom_offline_output_prct {
    my ($self, %options) = @_;

    return sprintf(
        'Devices offline %.2f%% (%s on %s)',
        $self->{result_values}->{offline_prct},
        $self->{result_values}->{offline},
        $self->{result_values}->{total},
    );
}

sub custom_online_output {
    my ($self, %options) = @_;

    return '' if $self->{result_values}->{total} == 1 &&
        (!defined($self->{option_results}->{device}) ||
            $self->{option_results}->{device} eq '');

    return sprintf(
        'Devices online %s on %s (%.2f%%)',
        $self->{result_values}->{online},
        $self->{result_values}->{total},
        $self->{result_values}->{online_prct},
    );
}

sub custom_offline_output {
    my ($self, %options) = @_;

    return sprintf(
        'Devices offline %s on %s (%.2f%%)',
        $self->{result_values}->{offline},
        $self->{result_values}->{total},
        $self->{result_values}->{offline_prct}
    );
}

sub prefix_output {
    my ($self, %options) = @_;
    my $pref = "Device '" . $options{instance_value}->{display} . "'";

    if (defined($options{instance_value}->{manufacturer}) && $options{instance_value}->{manufacturer}) {
        $pref = $pref . ", $options{instance_value}->{manufacturer}";
    }

    if (defined($options{instance_value}->{model}) && $options{instance_value}->{model}) {
        $pref = $pref . " ($options{instance_value}->{model})";
    }

    if (defined($options{instance_value}->{sn}) && $options{instance_value}->{sn}) {
        $pref = $pref . ", SN: $options{instance_value}->{sn}";
    }

    if (defined($options{instance_value}->{ip}) && $options{instance_value}->{ip}) {
        $pref = $pref . ", $options{instance_value}->{ip}";
    }

    $pref = $pref . " - ";

    return $pref;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{memory_free});
    return sprintf(
        'Memory Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{memory_used_prct},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{memory_prct_free}
    );
}

sub custom_storage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{storage_total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{storage_used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value =>
        $self->{result_values}->{storage_free});
    return sprintf(
        'Storage Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{storage_used_prct},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{storage_prct_free}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'Status: ' . $self->{result_values}->{status};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter:s' => { name => 'filter', default => 'name' },
        'device:s' => { name => 'device' },
        'units:s'  => { name => 'units', default => '%' },
    });

    return $self;
}

my $map_status_code = {
    1 => 'online', 0 => 'offline'
};

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{filter} = lc($self->{option_results}->{filter});
    if ($self->{option_results}->{filter} !~ /^(name|id)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --filter option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $temp_devices = $options{custom}->request_api(endpoint => '/device');

    $self->{device} = {};
    $self->{global} = {
        total        => 0,
        online       => 0,
        offline      => 0,
        offline_prct => 0,
        online_prct  => 0,
    };

    foreach my $device (@{$temp_devices}) {
        next if (defined($self->{option_results}->{device}) && $self->{option_results}->{device} ne ''
            && $device->{$self->{option_results}->{filter}} !~ /$self->{option_results}->{device}/);

        $device->{memory_used} = $device->{ram};
        $device->{memory_total} = $device->{totalRAM};

        if (defined($device->{totalRAM}) && $device->{totalRAM} > 0) {
            $device->{memory_free} = $device->{totalRAM} - $device->{ram};
            $device->{memory_used_prct} = $device->{ram} * 100 / $device->{totalRAM};
            $device->{memory_prct_free} = (100 - ($device->{ram} * 100 / $device->{totalRAM}));
        } else {
            $device->{memory_free} = 0;
            $device->{memory_used_prct} = 0;
            $device->{memory_prct_free} = 0;
        }

        $device->{storage_used} = $device->{storage};
        $device->{storage_total} = $device->{totalStorage};

        if (defined($device->{totalStorage}) && $device->{totalStorage} > 0) {
            $device->{storage_free} = $device->{totalStorage} - $device->{storage};
            $device->{storage_used_prct} = $device->{storage} * 100 / $device->{totalStorage};
            $device->{storage_prct_free} = (100 - ($device->{storage} * 100 / $device->{totalStorage}));
        } else {
            $device->{storage_free} = 0;
            $device->{storage_used_prct} = 0;
            $device->{storage_prct_free} = 0;
        }

        if (defined($map_status_code->{ $device->{isOnline} })) {
            $device->{status} = $map_status_code->{ $device->{isOnline}};
            if ($device->{status} eq 'online') {
                $self->{global}->{online}++;
            } else {
                $self->{global}->{offline}++;
            }
        } else {
            $device->{status} = 'NA';
        }

        $self->{global}->{total}++;

        if (defined($device->{lastUpdate})) {
            eval {
                my $str = substr($device->{lastUpdate}, 0, -3);
                my $parser = DateTime::Format::Strptime->new(pattern => '%Y-%m-%dT%T', time_zone => 'local');
                my $update = $parser->parse_datetime($str)->epoch;
                $device->{last_update_seconds_ago} = time() - $update;
            };

            if ($@) {
                $self->{output}->add_option_msg(long_msg =>
                    "Can not parse the lastUpdate of device $device->{'name'}");
                $device->{last_update_seconds_ago} = -1;
            }
        } else {
            $device->{last_update_seconds_ago} = -1;
        }

        $self->{device}->{$device->{'name'}} = { display => $device->{'name'}, %{$device} };
    }

    if (scalar(keys %{$self->{device}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No devices found.");
        $self->{output}->option_exit();
    }

    if ($self->{global}->{total} > 0) {
        $self->{global}->{online_prct} = $self->{global}->{online} * 100 / $self->{global}->{total};
        $self->{global}->{offline_prct} = $self->{global}->{offline} * 100 / $self->{global}->{total};
    }
}

1;

__END__

=head1 MODE

Check device health.

=over 8

=item B<--filter>

Choose the property to filter the device (default: name) ('name', 'id').

=item B<--device>

Filter device (can be a regexp).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning--status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /online/i').
Can used special variables like: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'total-online', 'total-online-prct', 'total-offline', 'total-offline-prct', 'memory', 'memory-usage-prct', 'memory-free',
'storage', 'storage-usage-prct', 'storage-free', 'cpu', 'uptime', 'last-update' (seconds ago).

=back

=cut
