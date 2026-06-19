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

package network::paloalto::prisma::sase::restapi::mode::edgelocationstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_locations_output {
    my ($self, %options) = @_;

    return sprintf(
        "Edge location %s (%s)",
        $options{instance_value}->{edge_location_name},
        $self->{option_results}->{filter_edge_location_type} eq "service" ? "service connections" : "remote network"
    );
}

my %state_map = (
    0 => 'Down',
    1 => 'Up',
    2 => 'Inactive'
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(" state: %s", $self->{result_values}->{state_instance});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'locations',
            type             => 1,
            cb_prefix_output => 'prefix_locations_output',
            message_multiple => 'All edge locations are ok'
        }
    ];

    $self->{maps_counters}->{locations} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{state_instance} eq "Down"',
            set              =>
                {
                    key_values                     => [
                        { name => 'state_instance' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        {
            label      => 'total-consumption',
            nlabel     => 'consumption.total.bitspersecond',
            display_ok => 1,
            set        => {
                key_values          => [ { name => 'total_consumption' }, { name => 'edge_location_name' } ],
                output_template     => 'total consumption: %s%s/s',
                output_change_bytes => 2,
                perfdatas           => [
                    {
                        template             => '%d',
                        unit                 => 'b/s',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'edge_location_name'
                    }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-edge-location-name:s' => { name => 'filter_edge_location_name' },
        'filter-edge-location-type:s' => { name => 'filter_edge_location_type' },
        'event-time-minutes:s'        => { name => 'event_time_minutes', default => 5 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!centreon::plugins::misc::is_empty(
        $self->{option_results}->{event_time_minutes})
        && $self->{option_results}->{event_time_minutes} !~ /^\d+$/
        && $self->{option_results}->{event_time_minutes} >= 1
        && $self->{option_results}->{event_time_minutes} <= 1440
    ) {
        $self->{output}->add_option_msg(short_msg =>
            "--event-time-minutes not supported. Must be a number between 1-1440");
        $self->{output}->option_exit();
    }

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_edge_location_type})
        && $self->{option_results}->{filter_edge_location_type} !~ /^service|remote$/) {
        $self->{output}->add_option_msg(short_msg =>
            "--filter-edge-location-type not supported. Available service, remote");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $instance_type = $self->{option_results}->{filter_edge_location_type} eq "service" ?
        "sc_state_instance" : "rn_state_instance";

    my $json_request = {
        properties => [
            {
                property => "$instance_type",
                alias    => "state_instance"
            },
            {
                property => "edge_location_display_name",
                alias    => "edge_location_name"
            }
        ],
        filter     => {
            rules => [
                {
                    property => "$instance_type",
                    operator => "in",
                    values   => [ 0, 1, 2 ]
                }
            ]
        }
    };

    my $encoded;
    eval {
        $encoded = encode_json($json_request);
    };
    if (defined $@ && $@ ne '') {
        $self->{output}->add_option_msg(short_msg => "cannot encode json request: $@");
        $self->{output}->option_exit();
    }

    my $response = $options{custom}->request_api(
        use_prisma_tenant_header => 1,
        endpoint                 => '/resource/query/edge_location_current_status',
        method                   => 'POST',
        post_body                => $encoded
    );

    $self->{locations} = {};
    foreach my $location (@{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_edge_location_name}) && $self->{option_results}->{filter_edge_location_name} ne '' &&
            $location->{edge_location_name} !~ /$self->{option_results}->{filter_edge_location_name}/);

        $self->{locations}->{ $location->{edge_location_name} } = {
            state_instance     => $state_map{$location->{state_instance}},
            edge_location_name => $location->{edge_location_name}
        };
    }

    $json_request = {
        properties => [
            {
                property => "edge_location_display_name",
                alias    => "edge_location_name"
            },
            {
                property => "total_consumption"
            }
        ],
        filter     => {
            rules => [
                {
                    property => "event_time",
                    operator => "last_n_minutes",
                    values   => [ 5 ]
                }
            ]
        }
    };

    eval {
        $encoded = encode_json($json_request);
    };
    if (defined $@ && $@ ne '') {
        $self->{output}->add_option_msg(short_msg => "cannot encode json request: $@");
        $self->{output}->option_exit();
    }

    $response = $options{custom}->request_api(
        use_prisma_tenant_header => 1,
        endpoint                 => $self->{option_results}->{filter_edge_location_type} eq "service" ?
            '/resource/custom/query/locations/location_sc_bandwidth' :
            '/resource/custom/query/locations/location_rn_bandwidth',
        method                   => 'POST',
        post_body                => $encoded
    );

    foreach my $location (@{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_edge_location_name}) && $self->{option_results}->{filter_edge_location_name} ne '' &&
            $location->{edge_location_name} !~ /$self->{option_results}->{filter_edge_location_name}/);

        $self->{locations}->{$location->{edge_location_name}}->{total_consumption} = $location->{total_consumption} * 1000000;
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='data-reduction'

=item B<--filter-edge-location-name>

Filter by Prisma SASE edge location name (can be a regexp).

=item B<--filter-edge-location-type>

Filter by Prisma SASE edge location type (can be a regexp). Can be 'service', 'remote'

=item B<--event-time-minutes>

Time period in minutes for values.
Can be: 1-1440 (default: 5).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state_instance}
%{state_instance} can be: 'Down', 'Up', 'Inactive'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state_instance}
%{state_instance} can be: 'Down', 'Up', 'Inactive'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: '%{state_instance} eq "Down"').
You can use the following variables: %{state_instance}
%{state_instance} can be: 'Down', 'Up', 'Inactive'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total_consumption' (b/s)

=back

=cut
