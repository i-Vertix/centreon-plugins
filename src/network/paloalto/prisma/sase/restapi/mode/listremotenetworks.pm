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

package network::paloalto::prisma::sase::restapi::mode::listremotenetworks;

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
            'filter-site-state:s' => { name => 'filter_site_state' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_site_state})
        && $self->{option_results}->{filter_site_state} !~ /^Down|Up|Warning$/) {
        $self->{output}->add_option_msg(short_msg => "--filter-site-state not supported. Available Down, Up, Warning");
        $self->{output}->option_exit();
    }
}

my @labels = (
    'site_state',
    'site_name',
    'edge_location_name',
    'cloud_region_name',
    'compute_location_display_name'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $json_request = {
        filter => {
            operator => "AND",
            rules    => [
                {
                    property => "event_time",
                    operator => "last_n_minutes",
                    values   => [ 1 ]
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

    my $results = {};
    foreach my $remote_network (@{$response->{data}}) {
        next if (defined($self->{option_results}->{filter_site_state}) && $self->{option_results}->{filter_site_state} ne '' &&
            $remote_network->{site_state_name} !~ /$self->{option_results}->{filter_site_state}/);

        $results->{ $remote_network->{site_name} } = {
            site_state                    => $remote_network->{site_state_name},
            site_name                     => $remote_network->{site_name},
            edge_location_name            => $remote_network->{edge_location_display_name},
            cloud_region_name             => $remote_network->{cloud_region_name},
            compute_location_display_name => $remote_network->{compute_location_display_name}
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

List remote networks.

=over 8

=item B<--filter-site-state>

Filter by site state (can be a regexp). Can be 'Down', 'Up', 'Warning'

=back

=cut
