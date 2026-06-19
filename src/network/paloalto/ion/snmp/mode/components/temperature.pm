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

package network::paloalto::ion::snmp::mode::components::temperature;

use strict;
use warnings;
use POSIX qw(round);

my $map_state = { 1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 6 => 'notPresent' };

my $mapping = {
    cgxEnvTempReading => { oid => '.1.3.6.1.4.1.50114.10.3.10.31.1.4' },
    cgxEnvTempStatus  => { oid => '.1.3.6.1.4.1.50114.10.3.10.31.1.3', map => $map_state },
    cgxEnvTempName    => { oid => '.1.3.6.1.4.1.50114.10.3.10.31.1.2' },
};
my $oid_cgxEnvTempEntry = '.1.3.6.1.4.1.50114.10.3.10.31.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        {
            oid   => $oid_cgxEnvTempEntry,
            start => $mapping->{cgxEnvTempName}->{oid},
            end   => $mapping->{cgxEnvTempReading}->{oid}
        };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = { name => 'temperatures', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'temperature'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cgxEnvTempEntry}})) {
        next if ($oid !~ /^$mapping->{cgxEnvTempStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping,
            results  => $self->{results}->{$oid_cgxEnvTempEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'temperature', instance => $instance));
        next if ($result->{cgxEnvTempStatus} =~ /notPresent/i &&
            $self->absent_problem(section => 'temperature', instance => $instance));

        my $temp_value = defined($result->{cgxEnvTempReading}) ? round($result->{cgxEnvTempReading} / 1000) : '-';

        $self->{components}->{temperature}->{total}++;
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "temperature '%s' is '%s' %s C [instance = %s]",
                    $result->{cgxEnvTempName},
                    $result->{cgxEnvTempStatus},
                    $temp_value,
                    $instance
                )
        );

        my $exit = $self->get_severity(
            label   => 'default',
            section => 'temperature',
            value   => $result->{cgxEnvTempStatus}
        );
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>
                $exit,
                short_msg                        =>
                    sprintf("temperature '%s' state is '%s'", $result->{cgxEnvTempName}, $result->{cgxEnvTempStatus}));
        }

        next if (!defined($temp_value) || $temp_value !~ /[0-9]/);

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'temperature',
            instance => $instance,
            value    => $temp_value
        );

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $exit2,
                short_msg => sprintf("temperature '%s' is %s C", $result->{cgxEnvTempName}, $temp_value
                )
            );
        }
        $self->{output}->perfdata_add(
            label     => 'temperature', unit => 'C',
            nlabel    => 'hardware.temperature.celsius',
            instances => $result->{cgxEnvTempName},
            value     => $temp_value,
            warning   => $warn,
            critical  => $crit,
        );
    }
}

1;
