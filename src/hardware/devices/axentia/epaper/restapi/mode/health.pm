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

package hardware::devices::axentia::epaper::restapi::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'display', type => 1, cb_prefix_output => 'prefix_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{display} = [
        {
            label            => 'status',
            type             => 2,
            unknown_default  => '%{status} eq "unknown" || %{display_mode} eq "unknown"',
            critical_default => '%{status} eq "error"',
            warning_default  => '%{status} eq "notice"',
            set              => {
                key_values                     => [
                    { name => 'status' },
                    { name => 'display' },
                    { name => 'product' },
                    { name => 'display_mode' },
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'temperature', display_ok => 0, nlabel => 'temperature.celsius', set => {
            key_values      => [ { name => 'temperature' }, { name => 'display' } ],
            output_template => 'Temperature: %d C',
            perfdatas       => [
                { value => 'temperature', template => '%d', unit => 'C', label_extra_instance => 1 },
            ],
        }
        },
        { label => 'uptime', display_ok => 0, nlabel => 'uptime.seconds', set => {
            key_values            => [ { name => 'uptime' }, { name => 'display' } ],
            closure_custom_output => $self->can('custom_uptime_output'),
            perfdatas             => [
                { value => 'uptime', template => '%d', unit => 's', label_extra_instance => 1 },
            ],
        }
        },
        { label => 'tcp-quality', display_ok => 0, nlabel => 'tcp.quality.percentage', set => {
            key_values      => [ { name => 'tcp_quality' }, { name => 'display' } ],
            output_template => 'TCP quality : %.2f%%',
            perfdatas       => [
                {
                    value                => 'tcp_quality',
                    template             => '%.2f',
                    min                  => 0,
                    max                  => 100,
                    unit                 => '%',
                    label_extra_instance => 1
                },
            ],
        }
        },
        { label => 'udp-quality', display_ok => 0, nlabel => 'udp.quality.percentage', set => {
            key_values      => [ { name => 'udp_quality' }, { name => 'display' } ],
            output_template => 'UDP quality : %.2f%%',
            perfdatas       => [
                {
                    value                => 'udp_quality',
                    template             => '%.2f',
                    min                  => 0,
                    max                  => 100,
                    unit                 => '%',
                    label_extra_instance => 1
                },
            ],
        }
        },
        { label => 'battery-status', display_ok => 0, nlabel => 'battery.status.percentage', set => {
            key_values      => [ { name => 'battery_status' }, { name => 'display' } ],
            output_template => 'Battery status : %.2f%%',
            perfdatas       => [
                {
                    value                => 'battery_status',
                    template             => '%.2f',
                    min                  => 0,
                    max                  => 100,
                    unit                 => '%',
                    label_extra_instance => 1
                },
            ],
        }
        },
        { label => 'battery-voltage', nlabel => 'battery.voltage.volt', display_ok => 0, set => {
            key_values      => [ { name => 'battery_voltage', no_value => 0 } ],
            output_template => 'Battery voltage: %s V',
            perfdatas       => [
                {
                    value                => 'battery_voltage',
                    template             => '%s',
                    unit                 => 'V',
                    label_extra_instance => 1
                },
            ],
        }
        },
    ];
}

sub custom_uptime_output {
    my ($self, %options) = @_;

    return sprintf(
        'System uptime is: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{uptime}, start => 'd')
    );
}

sub prefix_output {
    my ($self, %options) = @_;
    my $pref = "display '" . $options{instance_value}->{display} . "'";

    if (defined($options{instance_value}->{product}) && $options{instance_value}->{product}) {
        $pref = $pref . ", $options{instance_value}->{product}";
    }

    if (defined($options{instance_value}->{platform}) && $options{instance_value}->{platform}) {
        $pref = $pref . " ($options{instance_value}->{platform})";
    }

    if (defined($options{instance_value}->{firmware}) && $options{instance_value}->{firmware}) {
        $pref = $pref . ", Firmware: $options{instance_value}->{firmware}";
    }

    if (defined($options{instance_value}->{ip}) && $options{instance_value}->{ip}) {
        $pref = $pref . ", $options{instance_value}->{ip}";
    }

    $pref = $pref . " - ";

    return $pref;
}

sub custom_status_output {
    my ($self, %options) = @_;

    return "Status: $self->{result_values}->{status} ($self->{result_values}->{display_mode})";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 'display:s' => { name => 'display' } });

    return $self;
}

my $map_status_code = {
    0 => 'ok', 1 => 'notice', 2 => 'error'
};

my $map_display_mode = {
    0 => 'not mounted',
    1 => 'operation',
    2 => 'operation not mounted on site',
    3 => 'operation demo/mobile',
    4 => 'service',
    5 => 'mounted'
};

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $temp_displays = $options{custom}->request_api(endpoint => '/Display/all/status');

    $self->{display} = {};

    foreach my $temp_dp (@{$temp_displays}) {
        if (defined($self->{option_results}->{display}) && $self->{option_results}->{display} ne '' &&
            $temp_dp->{ibusId} ne $self->{option_results}->{display}) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $temp_dp->{ibusId} . "': no matching display filter.",
                debug    => 1);
            next;
        }

        my $dp;
        # there can be more than one stoppoint on a display. So we make a distinct of the stoppoint names
        my @pairs;
        my $stop_point_name = $temp_dp->{stopPointName};
        if ($stop_point_name =~ /,/) {
            # Normal case: multiple pairs separated by commas
            while ($stop_point_name =~ /\s*([^,]+,\s*[^,]+)\s*(?:,|$)/g) {
                push @pairs, $1;# example "Bolzano, Stazione"
            }
        } else {
            # Special case: no comma at all → the whole string counts as one "pair"
            push @pairs, $stop_point_name;
        }

        my %seen;
        my @unique = grep {!$seen{ lc($_) }++} @pairs;

        $dp->{stoppoint_name} = join(";", @unique);
        $dp->{product} = $temp_dp->{product};
        $dp->{platform} = $temp_dp->{platform};
        $dp->{firmware} = $temp_dp->{firmware};
        $dp->{ip} = defined($temp_dp->{ipAddress}) ? $temp_dp->{ipAddress} : "NA";

        $dp->{battery_status} = $temp_dp->{batteryStatus};
        $dp->{battery_voltage} = $temp_dp->{batteryVoltage};

        if ($temp_dp->{tcpQuality} ne "N/A") {
            $dp->{tcp_quality} = $temp_dp->{tcpQuality};
        }

        if ($temp_dp->{udpQuality} ne "N/A") {
            $dp->{udp_quality} = $temp_dp->{udpQuality};
        }
        $dp->{temperature} = $temp_dp->{temperature};
        $dp->{uptime} = $temp_dp->{upTime};

        $dp->{display_mode} = defined($map_display_mode->{ $temp_dp->{displayMode} }) ?
            $map_display_mode->{ $temp_dp->{displayMode} } : 'unknown';

        $dp->{status} = defined($map_status_code->{ $temp_dp->{displayStatus} }) ?
            $map_status_code->{ $temp_dp->{displayStatus} } : 'unknown';

        $self->{display}->{$temp_dp->{ibusId}} = { display => $dp->{stoppoint_name}, %{$dp} };
    }

    if (scalar(keys %{$self->{display}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No displays found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check display health.

=over 8

=item B<--display>

Filter display by ibusId.

=item B<--unknown-status>

Set unknown threshold for status. (Default: '%{status} eq "unknown" || %{display_mode} eq "unknown"')
Can used special variables like: %{status}, %{display_mode}

=item B<--warning--status>

Set warning threshold for status (Default: '%{status} eq "notice"')
Can used special variables like: %{status}, %{display_mode}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "error"').
Can used special variables like: %{status}, %{display_mode}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'temperature' (C), 'uptime' (s), 'tcp-quality' (%), 'udp-quality' (%), 'battery-status' (%), 'battery-voltage' (V).

=back

=cut
