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

package network::paloalto::prisma::sase::restapi::mode::listedgelocations;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-edge-location-type:s' => { name => 'filter_edge_location_type' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (centreon::plugins::misc::is_empty($self->{option_results}->{filter_edge_location_type})
        || $self->{option_results}->{filter_edge_location_type} !~ /^service|remote$/) {
        $self->{output}->add_option_msg(short_msg =>
            "--filter-edge-location-type not supported. Available service, remote");
        $self->{output}->option_exit();
    }
}

my @labels = (
    'edge_location_name',
    'edge_location_type',
    'state_instance'
);

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

    my $results = {};
    foreach my $edge_location (@{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_site_state}) && $self->{option_results}->{filter_site_state} ne '' &&
            $edge_location->{site_state_name} !~ /$self->{option_results}->{filter_site_state}/);

        $results->{ $edge_location->{edge_location_name} } = {
            edge_location_name => $edge_location->{edge_location_name},
            edge_location_type => $self->{option_results}->{filter_edge_location_type},
            state_instance     => $edge_location->{state_instance}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $results->{$instance}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List arrays:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}
1;

__END__

=head1 MODE

List edge locations

=over 8

=item B<--filter-edge-location-type>

Filter by site state (can be a regexp). Can be 'service', 'remote'

=back

=cut
