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

package apps::proxmox::bs::restapi::mode::resources;

use strict;
use warnings;
use Exporter;
use centreon::plugins::misc qw(is_empty);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(maintenance_type upid_starttime task_state);

# maintenance mode of a datastore: a property string like 'type=offline,message=...' or 'offline'
sub maintenance_type {
    my (%options) = @_;

    return '' if is_empty($options{value});
    return $1 if $options{value} =~ /(?:^|,)\s*type=([^,]+)/;
    return $1 if $options{value} =~ /^\s*([^,=]+)\s*(?:,|$)/;

    return '';
}

# start time (epoch) of a task from its UPID:
# 'UPID:<node>:<pid>:<pstart>:<task id>:<starttime>:<type>:<id>:<user>:', numbers in hexadecimal
sub upid_starttime {
    my (%options) = @_;

    return undef if is_empty($options{value});
    my @fields = split(/:/, $options{value});
    return undef unless @fields >= 6 && $fields[0] eq 'UPID' && $fields[5] =~ /^[0-9A-Fa-f]+$/;

    return hex($fields[5]);
}

# state of a task from its status: a running task has no end time,
# a finished one has 'OK', 'WARNINGS: <count>', 'unknown' or the error message
sub task_state {
    my (%options) = @_;

    return 'running' unless defined($options{endtime});
    return 'unknown' if is_empty($options{status}) || $options{status} =~ /^unknown$/i;
    return 'ok' if $options{status} eq 'OK';
    return 'warning' if $options{status} =~ /^WARNINGS:/;

    return 'error';
}

1;
