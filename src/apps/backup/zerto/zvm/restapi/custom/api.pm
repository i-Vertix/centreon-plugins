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

package apps::backup::zerto::zvm::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw(json_decode is_empty is_not_empty);
use centreon::plugins::constants qw(:messages);
use URI::Escape;
use Digest::SHA qw(sha256_hex);
use DateTime;

# a Windows ZVM session ends after 30 minutes without use
use constant SESSION_LIFETIME => 1500;

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    $options{output}->option_exit(short_msg => "Class Custom: Need to specify 'options' argument.")
        unless $options{options};

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'             => { name => 'hostname', default => '' },
            'port:s'                 => { name => 'port', type => 'port' },
            'proto:s'                => { name => 'proto', default => 'https', regexp_match => '^http[s]?$' },
            'auth-type:s'            => { name => 'auth_type', default => 'keycloak', is_in => [ 'keycloak', 'session' ] },
            'api-path:s'             => { name => 'api_path', default => '' },
            'realm:s'                => { name => 'realm', default => 'zerto' },
            'client-id:s'            => { name => 'client_id', default => '' },
            'client-secret:s'        => { name => 'client_secret', default => '' },
            'username:s'             => { name => 'username', default => '' },
            'password:s'             => { name => 'password', default => '' },
            'timeout:s'              => { name => 'timeout', default => 30, greater_than => 0 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'ZVM API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options, default_backend => 'curl');
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

    $self->{$_} = $self->{option_results}->{$_} // ''
        foreach qw/hostname auth_type api_path realm client_id client_secret username password/;
    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/unknown_http_status warning_http_status critical_http_status/;

    # the ZVM Appliance is reached on 443, a Windows ZVM on 9669
    $self->{option_results}->{port} = $self->{auth_type} eq 'session' ? 9669 : 443
        if is_empty($self->{option_results}->{port});

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if is_empty($self->{hostname});
    if ($self->{auth_type} eq 'session') {
        $self->{output}->option_exit(short_msg => 'Need to specify --username and --password options.')
            if is_empty($self->{username}) || is_empty($self->{password});
    } else {
        $self->{output}->option_exit(short_msg => 'Need to specify --client-id option.')
            if is_empty($self->{client_id});
        # without --username the client credentials grant is used, so the client secret is mandatory
        $self->{output}->option_exit(short_msg => 'Need to specify --client-secret option (or --username and --password).')
            if is_empty($self->{username}) && is_empty($self->{client_secret});
        $self->{output}->option_exit(short_msg => 'Need to specify --password option.')
            if is_not_empty($self->{username}) && is_empty($self->{password});
    }

    $self->{api_path} =~ s/\/+$//;

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{hostname} . ':' . $self->{option_results}->{port};
}

sub get_hostname {
    my ($self, %options) = @_;

    return $self->{hostname};
}

sub read_token_cache {
    my ($self, %options) = @_;

    $self->{cache}->read(
        statefile => 'zerto_zvm_api_' . sha256_hex(join('_', $self->get_connection_info(), $self->{auth_type}, $self->{client_id}, $self->{username}))
    );
    my $token = $self->{cache}->get(name => 'token');
    my $expires_on = $self->{cache}->get(name => 'expires_on') // 0;
    my $secret_hash_cache = $self->{cache}->get(name => 'secret_hash') // '';

    return $token
        if is_not_empty($token) && ($expires_on - time()) >= 60 && $secret_hash_cache eq $options{secret_hash};

    return undef;
}

sub get_keycloak_token {
    my ($self, %options) = @_;

    my @post_data = ('client_id=' . uri_escape($self->{client_id}));
    push @post_data, 'client_secret=' . uri_escape($self->{client_secret})
        if is_not_empty($self->{client_secret});
    if (is_not_empty($self->{username})) {
        push @post_data, 'grant_type=password', 'username=' . uri_escape($self->{username}), 'password=' . uri_escape($self->{password});
    } else {
        push @post_data, 'grant_type=client_credentials';
    }

    my $content = $self->{http}->request(
        method          => 'POST',
        url_path        => '/auth/realms/' . $self->{realm} . '/protocol/openid-connect/token',
        header          => [ 'Content-Type: application/x-www-form-urlencoded' ],
        query_form_post => join('&', @post_data),
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    $self->{output}->option_exit(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    # a non-JSON error page (proxy, wrong realm or path) is reported with its HTTP status
    $self->{output}->option_exit(short_msg => "Authentication endpoint error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "'] (add --debug option to display returned content)")
        if ref($decoded) ne 'HASH' && ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless ref($decoded) eq 'HASH';

    if (defined($decoded->{error})) {
        $self->{output}->output_add(long_msg => 'Error message: ' . ($decoded->{error_description} // ''), debug => 1);
        $self->{output}->option_exit(short_msg => "Authentication endpoint returns error '" . $decoded->{error} . "' (add --debug option for detailed message)");
    }
    $self->{output}->option_exit(short_msg => "Cannot get token [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($decoded->{access_token});

    return ($decoded->{access_token}, $decoded->{expires_in} // 300);
}

sub get_session_token {
    my ($self, %options) = @_;

    $self->{http}->request(
        method          => 'POST',
        url_path        => $self->{api_path} . '/v1/session/add',
        header          => [ 'Content-Type: application/json' ],
        query_form_post => '',
        credentials     => 1,
        basic           => 1,
        username        => $self->{username},
        password        => $self->{password},
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    my $session = $self->{http}->get_header(name => 'x-zerto-session');
    $self->{output}->option_exit(short_msg => "Cannot get session [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($session);

    return ($session, SESSION_LIFETIME);
}

sub get_token {
    my ($self, %options) = @_;

    my $secret_hash = sha256_hex($self->{client_secret} . $self->{password});
    my $token = $self->read_token_cache(secret_hash => $secret_hash);
    return $token if defined($token);

    my $lifetime;
    ($token, $lifetime) = $self->{auth_type} eq 'session' ? $self->get_session_token() : $self->get_keycloak_token();

    $self->{cache}->write(data => {
        updated     => time(),
        token       => $token,
        expires_on  => time() + $lifetime,
        secret_hash => $secret_hash
    });

    return $token;
}

sub clean_token {
    my ($self, %options) = @_;

    $self->{cache}->write(data => { updated => time() });
}

sub get_auth_header {
    my ($self, %options) = @_;

    return $self->{auth_type} eq 'session' ? 'x-zerto-session: ' . $options{token} : 'Authorization: Bearer ' . $options{token};
}

sub request_api {
    my ($self, %options) = @_;

    my $token = $self->get_token();
    my %request = (
        url_path  => $self->{api_path} . $options{endpoint},
        get_param => $options{get_param} // []
    );

    # first call without status check: an expired token must not end the check
    my $content = $self->{http}->request(
        %request,
        header          => [ $self->get_auth_header(token => $token) ],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    if ($code == 401 || $code == 403) {
        $self->clean_token();
        $token = $self->get_token();
    }
    if ($code < 200 || $code >= 300) {
        $content = $self->{http}->request(
            %request,
            header          => [ $self->get_auth_header(token => $token) ],
            unknown_status  => $self->{unknown_http_status},
            warning_status  => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless defined($decoded);

    return $decoded;
}

# the list endpoints return an array
sub request_api_list {
    my ($self, %options) = @_;

    my $response = $self->request_api(%options);
    $self->{output}->option_exit(short_msg => "API returns an unexpected response for '" . $options{endpoint} . "' (add --debug option to display returned content)")
        unless ref($response) eq 'ARRAY';

    return $response;
}

sub get_alerts {
    my ($self, %options) = @_;

    my $get_param = [];
    push @$get_param, 'isDismissed=false' unless $options{include_dismissed};

    return $self->request_api_list(endpoint => '/v1/alerts', get_param => $get_param);
}

sub get_datastores {
    my ($self, %options) = @_;

    return $self->request_api_list(endpoint => '/v1/datastores');
}

sub get_license {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/v1/license');
}

sub get_peer_sites {
    my ($self, %options) = @_;

    return $self->request_api_list(endpoint => '/v1/peersites');
}

sub get_tasks {
    my ($self, %options) = @_;

    # no date filter: a task started before the timeframe can still be running
    return $self->request_api_list(endpoint => '/v1/tasks');
}

sub get_vms {
    my ($self, %options) = @_;

    return $self->request_api_list(endpoint => '/v1/vms');
}

sub get_volumes {
    my ($self, %options) = @_;

    my $get_param = [];
    push @$get_param, 'volumeType=' . $options{volume_type} if is_not_empty($options{volume_type});

    return $self->request_api_list(endpoint => '/v1/volumes', get_param => $get_param);
}

sub get_vpgs {
    my ($self, %options) = @_;

    return $self->request_api_list(endpoint => '/v1/vpgs');
}

sub get_vras {
    my ($self, %options) = @_;

    return $self->request_api_list(endpoint => '/v1/vras');
}

# converts a date to epoch: Microsoft JSON date ('/Date(1520423877045)/' or '/Date(928142400000+0300)/'),
# ISO 8601 ('2026-10-31T10:00:00.123Z', '2026-10-31T10:00:00+01:00' or '2026-10-31')
sub date_to_epoch {
    my ($self, %options) = @_;

    return undef if is_empty($options{value});

    # the milliseconds are already UTC, the offset only tells the time zone of the server
    return int($1 / 1000)
        if $options{value} =~ /^\s*\\?\/Date\((-?\d+)(?:[+-]\d{4})?\)\\?\/\s*$/;

    my ($year, $month, $day, $hour, $minute, $second, $tz) =
        $options{value} =~ /^\s*(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?)?\s*(Z|[+-]\d{2}:?\d{2})?\s*$/i;
    return undef unless defined($year);

    $tz = defined($tz) && uc($tz) ne 'Z' ? $tz =~ s/://r : 'UTC';

    my $dt = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hour // 0,
        minute    => $minute // 0,
        second    => $second // 0,
        time_zone => $tz
    );

    return $dt->epoch();
}

1;

__END__

=head1 NAME

Zerto Virtual Manager (ZVM) REST API

=head1 ZVM API OPTIONS

Zerto Virtual Manager REST API (v1).
The ZVM Appliance (Zerto 10.x) authenticates with a Keycloak access token,
a Windows ZVM (up to Zerto 10.0 Update 2) with a Zerto session.

=over 8

=item B<--hostname>

Address of the Zerto Virtual Manager.

=item B<--port>

Define the TCP port to use to reach the API (default: 443, or 9669 with C<--auth-type=session>).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--auth-type>

Define the authentication method (default: C<keycloak>).
C<keycloak>: Keycloak access token of the ZVM Appliance.
C<session>: Zerto session (C<x-zerto-session> header) of a Windows ZVM, opened with C<--username> and C<--password>.

=item B<--api-path>

Define the path prefix of the REST API (default: empty, the API is reached on C</v1>).

=item B<--realm>

Define the Keycloak realm (default: C<zerto>).

=item B<--client-id>

Define the Keycloak client ID.

=item B<--client-secret>

Define the Keycloak client secret. Without C<--username>, the client credentials grant is used.

=item B<--username>

Define the user to authenticate with: a Keycloak user (password grant) or, with C<--auth-type=session>, a Windows or hypervisor manager user.

=item B<--password>

Define the password of the user.

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 30).

=item B<--unknown-http-status>

Threshold unknown for http response code (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Threshold warning for http response code.

=item B<--critical-http-status>

Threshold critical for http response code.

=back

=head1 DESCRIPTION

B<custom>.

=cut
