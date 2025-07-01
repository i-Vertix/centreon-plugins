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
# Authors : Roman Morandell - i-Vertix
#

package ivertix::plugins::apps::sguard::restapi::mode::keepalive;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::http;
use JSON;

sub custom_status_output {
    my ($self, %options) = @_;

    # the error code is in the description. so no needs to print them out separately
    return  'HTTP ' . $self->{result_values}->{http_code} . ' - ' . $self->{result_values}->{message};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            # critical if error_code is set
            label      => 'status', type => 2, critical_default => '%{error_code}',
            display_ok => 0, set => {
            key_values                     => [
                { name => 'error_code' }, { name => 'http_code' }, { name => 'message' }
            ],
            closure_custom_output          => $self->can('custom_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold_ng
        }
        },
        { label => 'time', nlabel => 'sguard.response.time.seconds', set => {
            key_values      => [ { name => 'time' } ],
            output_template => 'Keep alive sent in %.3fs',
            perfdatas       => [
                { label => 'time', template => '%.3f', min => 0, unit => 's' }
            ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'event-id:s' => { name => 'event_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{event_id}) || $self->{option_results}->{event_id} !~ /^\d+$/) {
        $self->{output}->add_option_msg(short_msg => "--event-id must be a valid number.");
        $self->{output}->option_exit();
    }
}

sub set_request_body {
    my $self = shift;

    my $json = JSON->new;
    my $json_body = undef;
    my $body_obj = { eventId => $self->{option_results}->{event_id} };

    eval {
        $json_body = $json->encode($body_obj);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    return $json_body;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $timing0 = [ gettimeofday ];
    my $body = $self->set_request_body(0);
    my $api_response = $options{custom}->request_api(endpoint => '/watchdog/ping/api', method => 'PUT', body => $body);
    my $http_status = $api_response->{status};
    my $json_content = $api_response->{result};
    $self->{global}->{time} = tv_interval($timing0, [ gettimeofday ]);
    $self->{global}->{http_code} = $http_status;

    if ($http_status == 204) {
        $self->{global}->{message} = "Keep Alive successfully sent";
    } elsif (defined($json_content)) {
        $self->{global}->{error_code} = defined($json_content->{code}) ?
            $json_content->{code} : 0;
        $self->{global}->{message} = defined($json_content->{message}) ?
            $json_content->{message} : "Keep Alive couldn't be sent";
    }
}

1;

__END__

=head1 MODE

Calls a Keep Alive endpoint on s.guard API after getting a sessionId

=over 8

=item B<--event-id>

event-id to use for the keep alive.

=item B<--warning-time> B<--critical-time>

Threshold warning for response time

=back

=cut