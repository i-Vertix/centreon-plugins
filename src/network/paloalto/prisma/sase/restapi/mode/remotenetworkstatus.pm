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

package network::paloalto::prisma::sase::restapi::mode::remotenetworkstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_remote_networks_output {
    my ($self, %options) = @_;

    return sprintf(
        "Remote network Site %s [location %s - region %s]",
        $options{instance_value}->{site_name},
        $options{instance_value}->{edge_location_name},
        $options{instance_value}->{cloud_region_name}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        " state: %s, Tunnels %s/%s up",
        $self->{result_values}->{site_state},
        $self->{result_values}->{site_up_tunnels},
        $self->{result_values}->{site_all_tunnels}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'remote_networks',
            type             => 1,
            cb_prefix_output => 'prefix_remote_networks_output',
            message_multiple => 'All remote networks are ok'
        }
    ];

    $self->{maps_counters}->{remote_networks} = [
        {
            label            => 'status',
            type             => 2,
            critical_default => '%{site_state} eq "Down"',
            warning_default  => '%{site_state} eq "Warning" || %{site_up_tunnels} < %{site_all_tunnels}',
            set              =>
                {
                    key_values                     => [
                        { name => 'site_state' },
                        { name => 'site_up_tunnels' },
                        { name => 'site_all_tunnels' }
                    ],
                    closure_custom_output          => $self->can('custom_status_output'),
                    closure_custom_perfdata        => sub {return 0;},
                    closure_custom_threshold_check => \&catalog_status_threshold_ng
                }
        },
        {
            label      => 'average-egress',
            nlabel     => 'egress.average.bitspersecond',
            display_ok => 1,
            set        => {
                key_values          => [ { name => 'avg_egress' }, { name => 'site_name' } ],
                output_template     => 'average traffic egress: %s%s/s',
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
            label      => 'average-ingress',
            nlabel     => 'ingress.average.bitspersecond',
            display_ok => 1,
            set        => {
                key_values          => [ { name => 'avg_ingress' }, { name => 'site_name' } ],
                output_template     => 'average traffic ingress: %s%s/s',
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
        endpoint                 => '/resource/custom/query/remotenetworks/rn_list',
        method                   => 'POST',
        post_body                => $encoded
    );

    $self->{remote_networks} = {};
    foreach my $remote_network (@{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_site_name}) && $self->{option_results}->{filter_site_name} ne '' &&
            $remote_network->{site_name} !~ /$self->{option_results}->{filter_site_name}/);

        $self->{remote_networks}->{ $remote_network->{site_name} } = {
            site_name          => $remote_network->{site_name},
            site_state         => $remote_network->{site_state_name},
            edge_location_name => $remote_network->{edge_location_name},
            cloud_region_name  => $remote_network->{cloud_region_name},
            avg_egress         => $remote_network->{avg_egress} * 1000000,
            avg_ingress        => $remote_network->{avg_ingress} * 1000000,
            avg_throughput     => $remote_network->{avg_throughput} * 1000000,
            peak_throughput    => $remote_network->{peak_throughput} * 1000000,
            site_all_tunnels   => $remote_network->{site_all_tunnels},
            site_up_tunnels    => $remote_network->{site_up_tunnels}
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

=item B<--event-time-minutes>

Time period in minutes for values.
Can be: 1-1440 (default: 5).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{site_state}, %{site_all_tunnels}, %{site_up_tunnels}, %{site_name}
%{site_state} can be: 'Down', 'Up', 'Warning'

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. (default: '%{site_state} eq "Warning" || %{site_up_tunnels} < %{site_all_tunnels}')
You can use the following variables: %{site_state}, %{site_all_tunnels}, %{site_up_tunnels}, %{site_name}
%{site_state} can be: 'Down', 'Up', 'Warning'

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{site_state} eq "Down"')
You can use the following variables: %{site_state}, %{site_all_tunnels}, %{site_up_tunnels}, %{site_name}
%{site_state} can be: 'Down', 'Up', 'Warning'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'average-egress' (b/s), 'average-ingress' (b/s), 'average-throughput' (b/s), 'peak-throughput' (b/s),
'site-all-tunnels', 'site-up-tunnels'

=back

=cut
