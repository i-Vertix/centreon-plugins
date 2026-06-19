#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::paloalto::ion::snmp::mode::components::voltage;

use strict;
use warnings;

my $map_state = { 1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 6 => 'notPresent' };

my $mapping = {
    cgxEnvPowerVoltage => { oid => '.1.3.6.1.4.1.50114.10.3.10.41.1.4' },
    cgxEnvPowerStatus  => { oid => '.1.3.6.1.4.1.50114.10.3.10.41.1.3', map => $map_state },
    cgxEnvPowerName    => { oid => '.1.3.6.1.4.1.50114.10.3.10.41.1.2' },
};
my $oid_cgxEnvPowerEntry = '.1.3.6.1.4.1.50114.10.3.10.41.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        {
            oid   => $oid_cgxEnvPowerEntry,
            start => $mapping->{cgxEnvPowerName}->{oid},
            end   => $mapping->{cgxEnvPowerVoltage}->{oid}
        };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking voltages");
    $self->{components}->{voltages} = { name => 'voltages', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'voltages'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cgxEnvPowerEntry}})) {
        next if ($oid !~ /^$mapping->{cgxEnvPowerStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping,
            results  => $self->{results}->{$oid_cgxEnvPowerEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'voltage', instance => $instance));
        next if ($result->{cgxEnvPowerStatus} =~ /notPresent/i &&
            $self->absent_problem(section => 'voltage', instance => $instance));

        $self->{components}->{voltage}->{total}++;
        $self->{output}->output_add(long_msg =>
            sprintf(
                "voltage '%s' sensor out of range status is '%s' [instance: %s]",
                $result->{cgxEnvPowerName},
                $result->{cgxEnvPowerStatus},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'voltage', value => $result->{cgxEnvPowerStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit,
                short_msg => sprintf(
                    "Voltage '%s' sensor out of range status is '%s'",
                    $result->{cgxEnvPowerName},
                    $result->{cgxEnvPowerStatus}
                )
            );
        }

        next if (!defined($result->{cgxEnvPowerVoltage}) || $result->{cgxEnvPowerVoltage} !~ /[0-9]/);

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'voltage',
            instance => $instance,
            value    => $result->{cgxEnvPowerVoltage}
        );

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit2,
                short_msg => sprintf(
                    "Voltage '%s' sensor is %.2f V",
                    $result->{cgxEnvPowerName},
                    $result->{cgxEnvPowerVoltage}
                )
            );
        }

        $self->{output}->perfdata_add(
            label     => 'volt', unit => 'V',
            nlabel    => 'hardware.voltage.volt',
            instances => $result->{cgxEnvPowerName},
            value     => $result->{cgxEnvPowerVoltage},
            warning   => $warn,
            critical  => $crit,
            min       => 0
        );
    }
}

1;
