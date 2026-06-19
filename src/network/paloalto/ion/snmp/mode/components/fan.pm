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

package network::paloalto::ion::snmp::mode::components::fan;

use strict;
use warnings;

my $map_state = { 1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown', 6 => 'notPresent' };

my $mapping = {
    cgxEnvFanSpeed  => { oid => '.1.3.6.1.4.1.50114.10.3.10.11.1.4' },
    cgxEnvFanStatus => { oid => '.1.3.6.1.4.1.50114.10.3.10.11.1.3', map => $map_state },
    cgxEnvFanName   => { oid => '.1.3.6.1.4.1.50114.10.3.10.11.1.2' },
};
my $oid_cgxEnvFanEntry = '.1.3.6.1.4.1.50114.10.3.10.11.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}},
        {
            oid   => $oid_cgxEnvFanEntry,
            start => $mapping->{cgxEnvFanName}->{oid},
            end   => $mapping->{cgxEnvFanSpeed}->{oid}
        };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = { name => 'fans', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_cgxEnvFanEntry}})) {
        next if ($oid !~ /^$mapping->{cgxEnvFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(
            mapping  => $mapping,
            results  => $self->{results}->{$oid_cgxEnvFanEntry},
            instance => $instance
        );

        next if ($self->check_filter(section => 'fan', instance => $instance));
        next if ($result->{cgxEnvFanStatus} =~ /notPresent/i &&
            $self->absent_problem(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg =>
            sprintf("fan '%s' status is '%s' [instance = %s, speed = %s]",
                $result->{cgxEnvFanName}, $result->{cgxEnvFanStatus}, $instance,
                defined($result->{cgxEnvFanSpeed}) ? $result->{cgxEnvFanSpeed} : '-'));

        my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{cgxEnvFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>
                $exit,
                short_msg                        =>
                    sprintf("fan '%s' state is '%s'", $result->{cgxEnvFanName}, $result->{cgxEnvFanStatus}));
        }

        next if (!defined($result->{cgxEnvFanSpeed}) || $result->{cgxEnvFanSpeed} !~ /[0-9]/);

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(
            section  => 'fan',
            instance => $instance,
            value    => $result->{cgxEnvFanSpeed}
        );

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>
                $exit2,
                short_msg                        =>
                    sprintf("fan '%s' speed is %s rpm", $result->{cgxEnvFanName}, $result->{cgxEnvFanSpeed}));
        }
        $self->{output}->perfdata_add(
            label     => 'fan', unit => 'rpm',
            nlabel    => 'hardware.fan.speed.rpm',
            instances => $result->{cgxEnvFanName},
            value     => $result->{cgxEnvFanSpeed},
            warning   => $warn,
            critical  => $crit,
            min       => 0
        );
    }
}

1;
