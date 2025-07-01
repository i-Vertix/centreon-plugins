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

package notification::twillio::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'api:s'                  => { name => 'api' },
            'api-version:s'          => { name => 'api_version', default => '/2010-04-01' },
            'api-path:s'             => { name => 'api_path', default => '/Accounts' },
            'account-sid:s'          => { name => 'account_sid' },
            'auth-token:s'           => { name => 'auth_token' },
            'port:s'                 => { name => 'port', default => '443' },
            'proto:s'                => { name => 'proto', default => 'https' },
            'timeout:s'              => { name => 'timeout', default => 30 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '' },
            'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
            'critical-http-status:s' => {
                name    => 'critical_http_status',
                default => '%{http_code} < 200 or %{http_code} > 400'
            }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;

    if (!defined($self->{option_results}->{api}) || $self->{option_results}->{api} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api option.');
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{api_version} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-version option.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{api_path} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --api-path option.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{account_sid} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --account-sid option.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{auth_token} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --auth-token option.");
        $self->{output}->option_exit();
    }
    if (lc($self->{option_results}->{proto}) !~ /^(|http|https)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --proto option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{api_path} = $self->{option_results}->{api_version} .
        $self->{option_results}->{api_path} . "/$self->{option_results}->{account_sid}/";

    if (defined($self->{option_results}->{account_sid}) && $self->{option_results}->{auth_token} ne '') {
        $self->{option_results}->{credentials} = 1;
        $self->{option_results}->{basic} = 1;
        $self->{option_results}->{username} = $self->{option_results}->{account_sid};
        $self->{option_results}->{password} = $self->{option_results}->{auth_token};
    }
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{api} . ':' . $self->{option_results}->{port};
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{option_results}->{api};
}

sub request {
    my ($self, %options) = @_;

    $self->settings();

    my $content = $self->{http}->request(
        hostname        => $self->{option_results}->{api},
        method          => $options{method},
        url_path        => $self->{option_results}->{api_path} . $options{json},
        post_param      => $options{post_param},
        critical_status => '',
        warning_status  => '',
        unknown_status  => ''
    );
    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        return (0, undef, $@);
    }

    return (1, $self->{http}->get_code(), $decoded);
}

1;

__END__

=head1 NAME

twillio Rest API

=head1 REST API OPTIONS

twillio API (https://www.twilio.com/docs/messaging/api)

=over 8

=item B<--api>

Set api.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-path>

Specify the api path (Default: '/Accounts')

=item B<--api-version>

Specify the api version (Default: '/2010-04-01')

=item B<--account-sid>

twillio SID account

=item B<--auth-token>

twillio Authentication token

=item B<--timeout>

Set timeout in seconds (Default: 30).

=item B<--unknown-http-status>

Threshold warning for http response code.
(Default: '')

=item B<--warning-http-status>

Threshold warning for http response code.
(Default: '')

=item B<--critical-http-status>

Threshold warning for http response code.
(Default: '%{http_code} < 200 or %{http_code} >= 400')

=back

=head1 DESCRIPTION

B<custom>.

=cut
