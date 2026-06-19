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

package network::paloalto::prisma::sase::restapi::mode::tunnelstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_tunnels_output {
    my ($self, %options) = @_;

    return sprintf(
        "Tunnel %s Site %s [location %s - region %s]",
        $options{instance_value}->{tunnel_name},
        $options{instance_value}->{site_name},
        $options{instance_value}->{edge_location_name},
        $options{instance_value}->{cloud_region_name}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        " tunnel state: %s",
        $self->{result_values}->{tunnel_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'tunnels',
            type             => 1,
            cb_prefix_output => 'prefix_tunnels_output',
            message_multiple => 'All tunnels are ok'
        }
    ];

    $self->{maps_counters}->{tunnels} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{tunnel_state} eq "Down"',
            set              =>
                {
                    key_values                     => [
                        { name => 'tunnel_state' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        {
            label      => 'average-throughput',
            nlabel     => 'throughput.average.bitspersecond',
            display_ok => 1,
            set        => {
                key_values          => [ { name => 'avg_throughput' }, { name => 'site_name' } ],
                output_template     => 'average traffic throughput: %s%s/s',
                output_change_bytes => 2,
                perfdatas           => [
                    {
                        template             => '%d',
                        unit                 => 'b/s',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'site_name'
                    }
                ]
            }
        },
        {
            label      => 'peak-throughput',
            nlabel     => 'throughput.max.bitspersecond',
            display_ok => 1,
            set        => {
                key_values          => [ { name => 'peak_throughput' }, { name => 'site_name' } ],
                output_template     => 'peak traffic throughput: %s%s/s',
                output_change_bytes => 2,
                perfdatas           => [
                    {
                        template             => '%d',
                        unit                 => 'b/s',
                        min                  => 0,
                        label_extra_instance => 1,
                        instance_use         => 'site_name'
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
        'filter-tunnel-name:s' => { name => 'filter_tunnel_name' },
        'filter-site-name:s'   => { name => 'filter_site_name' },
        'event-time-minutes:s' => { name => 'event_time_minutes', default => 5 }
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
}

sub manage_selection {
    my ($self, %options) = @_;

    my $json_request = {
        filter => {
            operator => "AND",
            rules    => [
                {
                    property => "event_time",
                    operator => "last_n_minutes",
                    values   => [ $self->{option_results}->{event_time_minutes} ]
                },
                {
                    property => "tunnel_state",
                    operator => "in",
                    values   => [ 0, 1, 2, 3 ]
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
        endpoint                 => '/resource/custom/query/tunnels/tunnel_list',
        method                   => 'POST',
        post_body                => $encoded
    );

    $self->{tunnels} = {};
    foreach my $tunnel (@{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_site_name}) && $self->{option_results}->{filter_site_name} ne '' &&
            $tunnel->{site_name} !~ /$self->{option_results}->{filter_site_name}/);

        next if (defined($self->{option_results}->{filter_tunnel_name}) && $self->{option_results}->{filter_tunnel_name} ne '' &&
            $tunnel->{tunnel_name} !~ /$self->{option_results}->{filter_tunnel_name}/);

        $self->{tunnels}->{ $tunnel->{tunnel_name} } = {
            tunnel_name        => $tunnel->{tunnel_name},
            tunnel_state       => $tunnel->{tunnel_state_name},
            site_name          => $tunnel->{site_name},
            edge_location_name => $tunnel->{edge_location_name},
            cloud_region_name  => $tunnel->{cloud_region_name},
            avg_throughput     => $tunnel->{avg_throughput} * 1000000,
            peak_throughput    => $tunnel->{peak_throughput} * 1000000
        };
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

=item B<--filter-site-name>

Filter volumes by site name (can be a regexp).

=item B<--filter-tunnel-name>

Filter volumes by tunnel name (can be a regexp).

=item B<--event-time-minutes>

Time period in minutes for values.
Can be: 1-1440 (default: 5).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{tunnel_state}, %{tunnel_name}, %{site_name}
%{tunnel_state} can be 'Up', 'Init', 'Inactive', 'Down'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{tunnel_state}, %{tunnel_name}, %{site_name}
%{tunnel_state} can be 'Up', 'Init', 'Inactive', 'Down'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{tunnel_state} eq "Down"')
You can use the following variables: %{tunnel_state}, %{tunnel_name}, %{site_name}
%{tunnel_state} can be 'Up', 'Init', 'Inactive', 'Down'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'average-throughput' (b/s), 'peak-throughput' (b/s)

=back

=cut
