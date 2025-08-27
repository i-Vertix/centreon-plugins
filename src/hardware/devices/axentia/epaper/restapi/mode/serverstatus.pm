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

package hardware::devices::axentia::epaper::restapi::mode::serverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use DateTime::Format::ISO8601;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'departures', nlabel => 'departures.count', display_ok => 1, set => {
            key_values      => [ { name => 'departures' } ],
            output_template => 'Number of departures: %s',
            perfdatas       => [
                { template => '%s', min => 0 }
            ]
        }
        },
        { label => 'last-update', nlabel => 'last-update.seconds', display_ok => 1, set => {
            key_values      => [ { name => 'last_update' } ],
            output_template => 'Last Database sync %s seconds ago',
            output_use      => 'last_update',
            perfdatas       => [
                { template => '%s', min => 0, unit => 's' }
            ]
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $counts = $options{custom}->request_api(endpoint => '/Supervision/server/status');

    $self->{display} = {};

    my $dt = DateTime::Format::ISO8601->parse_datetime($counts->{lastDatabaseSync});
    $dt->set_time_zone('UTC');
    my $last_sync_epoch = $dt->epoch;

    $self->{global} = {
        departures  => $counts->{numberOfDepartures},
        last_update => time - $last_sync_epoch,
    };
}

1;

__END__

=head1 MODE

Check display health.

=over 8

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'departures', 'last-update' (seconds ago)

=back

=cut
