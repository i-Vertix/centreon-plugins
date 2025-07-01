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

package ivertix::plugins::centreon::common::sguard::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

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
            'api-path:s'             => { name => 'api_path' },
            'api-key:s'              => { name => 'api_key' },
            'email:s'                => { name => 'email' },
            'password:s'             => { name => 'password' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port' },
            'proto:s'                => { name => 'proto' },
            'timeout:s'              => { name => 'timeout' },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '' },
            'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
            'critical-http-status:s' => {
                name    => 'critical_http_status',
                default => '%{http_code} < 200 or %{http_code} > 404'
            }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 30;
    $self->{email} = (defined($self->{option_results}->{email})) ?
        $self->{option_results}->{email} :
        '';
    $self->{password} = (defined($self->{option_results}->{password})) ?
        $self->{option_results}->{password} :
        '';
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ?
        $self->{option_results}->{api_path} :
        '/api/v1';
    $self->{api_key} = (defined($self->{option_results}->{api_key})) ?
        $self->{option_results}->{api_key} :
        '';

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    if ($self->{email} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --email option.');
        $self->{output}->option_exit();
    }
    if ($self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --password option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-key option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{option_results}->{hostname};
}

sub get_session {
    my ($self, %options) = @_;

    my $has_cache_file = $self->{cache}->read(statefile =>
        'sguard_' . md5_hex($self->{option_results}->{hostname} . '_' . $self->{email}));
    my $session_id = $self->{cache}->get(name => 'sessionId');
    my $md5_secret_cache = $self->{cache}->get(name => 'md5_secret');
    my $md5_secret = md5_hex($self->{email} . $self->{password});

    if ($has_cache_file == 0 ||
        !defined($session_id) ||
        (defined($md5_secret_cache) && $md5_secret_cache ne $md5_secret) ||
        (time() > $self->{cache}->get(name => 'expires_on'))
    ) {
        my $body = { email => $self->{email}, password => $self->{password}, apiKey => $self->{api_key} };
        my $post_json = JSON::XS->new->utf8->encode($body);

        $self->settings();

        my $content = $self->{http}->request(
            url_path        => $self->{api_path} . '/system/session',
            query_form_post => $post_json,
            method          => 'POST',
            warning_status  => $self->{option_results}->{warning_http_status},
            unknown_status  => $self->{option_results}->{unknown_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
        );

        my $decoded;
        eval {
            $decoded = JSON::XS->new->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->output_add(long_msg => $content, debug => 1);
            $self->{output}->add_option_msg(short_msg =>
                "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
        if (!($decoded->{sessionId}) || $decoded->{isError}) {
            $self->{output}->output_add(long_msg => "Error message : " . $decoded->{message}, debug => 1);
            $self->{output}->add_option_msg(short_msg =>
                "Authentication endpoint returns error code '" . $decoded->{message} . "' (add --debug option for detailed message)");
            $self->{output}->option_exit();
        }

        $session_id = $decoded->{sessionId};
        my $datas = {
            updated    => time(),
            sessionId  => $decoded->{sessionId},
            expires_on => $decoded->{time} + $decoded->{expiresIn},
            md5_secret => $md5_secret
        };
        $self->{cache}->write(data => $datas);
    }

    return $session_id;
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = { updated => time() };
    $self->{cache}->write(data => $datas);
}

sub request_api {
    my ($self, %options) = @_;

    my $session_id = $self->get_session(statefile => $self->{cache});

    if (!defined($session_id)) {
        $self->{output}->add_option_msg(short_msg => "No valid sessionId for a request found");
        $self->{output}->option_exit();
    }

    $self->settings();
    $self->{http}->add_header(key => 'sessionId', value => $session_id);

    my %params = (
        url_path  => $self->{api_path} . $options{endpoint},
        get_param => $options{get_param},
        method    => $options{method}
    );

    if (defined($options{body})) {
        $params{query_form_post} = $options{body}
    }

    my ($content) = $self->{http}->request(
        %params,
        warning_status  => $self->{option_results}->{warning_http_status},
        unknown_status  => $self->{option_results}->{unknown_http_status},
        critical_status => $self->{option_results}->{critical_http_status}
    );

    # Maybe session is invalid or expired in the last few seconds
    if ($self->{http}->get_code() == 401 || $self->{http}->get_code() == 403) {
        $self->clean_token();
        $session_id = $self->get_session(statefile => $self->{cache});
        $self->{http}->add_header(key => 'sessiondId', value => $session_id) if (defined($session_id));

        $content = $self->{http}->request(
            %params,
            warning_status  => $self->{option_results}->{warning_http_status},
            unknown_status  => $self->{option_results}->{unknown_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
        );
    }

    my $decoded = undef;

    if (defined($content) && $content ne '') {
        eval {
            $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg =>
                "Cannot decode response (add --debug option to display returned content)");
            $self->{output}->option_exit();
        }
    }

    return { status => $self->{http}->get_code(), result => $decoded };
}

1;

__END__

=head1 NAME

s.Guardian Rest API

=head1 REST API OPTIONS

s.GuardRest API (https://www.swissphone.com/de/loesungen/komponenten/plattformen-services/s-guard/)

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-path>

Specify https if needed (Default: '/api/v2')

=item B<--api-key>

API client key.

=item B<--email>

user email with access rights to communicate with the api

=item B<--password>

user password

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
(Default: '%{http_code} < 200 or %{http_code} >= 404')

=back

=head1 DESCRIPTION

B<custom>.

=cut
