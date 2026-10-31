#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::backup::zerto::zic::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw(json_decode is_empty is_not_empty);
use centreon::plugins::constants qw(:messages);
use URI::Escape;
use Digest::SHA qw(sha256_hex);
use DateTime;

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
            'port:i'                 => { name => 'port', default => '443', greater_than => 0, less_than => 65536 },
            'proto:s'                => { name => 'proto', default => 'https', regexp_match => '^http[s]?$' },
            'api-path:s'             => { name => 'api_path', default => '/zic' },
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
    $options{options}->add_help(package => __PACKAGE__, sections => 'ZIC API OPTIONS', once => 1);

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
        foreach qw/hostname api_path realm client_id client_secret username password/;
    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/unknown_http_status warning_http_status critical_http_status/;

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if is_empty($self->{hostname});
    $self->{output}->option_exit(short_msg => 'Need to specify --client-id option.')
        if is_empty($self->{client_id});
    # without --username the client credentials grant is used, so the client secret is mandatory
    $self->{output}->option_exit(short_msg => 'Need to specify --client-secret option (or --username and --password).')
        if is_empty($self->{username}) && is_empty($self->{client_secret});
    $self->{output}->option_exit(short_msg => 'Need to specify --password option.')
        if is_not_empty($self->{username}) && is_empty($self->{password});

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

sub get_token {
    my ($self, %options) = @_;

    $self->{cache}->read(
        statefile => 'zerto_zic_api_' . sha256_hex($self->get_connection_info() . '_' . $self->{client_id} . '_' . $self->{username})
    );
    my $access_token = $self->{cache}->get(name => 'access_token');
    my $expires_on = $self->{cache}->get(name => 'expires_on') // 0;
    my $secret_hash = sha256_hex($self->{client_secret} . $self->{password});
    my $secret_hash_cache = $self->{cache}->get(name => 'secret_hash') // '';

    return $access_token
        if is_not_empty($access_token) && ($expires_on - time()) >= 60 && $secret_hash_cache eq $secret_hash;

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
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless ref($decoded) eq 'HASH';

    if (defined($decoded->{error})) {
        $self->{output}->output_add(long_msg => 'Error message: ' . ($decoded->{error_description} // ''), debug => 1);
        $self->{output}->option_exit(short_msg => "Authentication endpoint returns error '" . $decoded->{error} . "' (add --debug option for detailed message)");
    }
    $self->{output}->option_exit(short_msg => "Cannot get token [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($decoded->{access_token});

    $self->{cache}->write(data => {
        updated      => time(),
        access_token => $decoded->{access_token},
        expires_on   => time() + ($decoded->{expires_in} // 300),
        secret_hash  => $secret_hash
    });

    return $decoded->{access_token};
}

sub clean_token {
    my ($self, %options) = @_;

    $self->{cache}->write(data => { updated => time() });
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
        header          => [ 'Authorization: Bearer ' . $token ],
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
            header          => [ 'Authorization: Bearer ' . $token ],
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

sub get_vpgs {
    my ($self, %options) = @_;

    # the response also holds 'vpgsWithoutData', so it is returned as is
    return $self->request_api(endpoint => '/api/v2/vpgs');
}

sub get_alerts {
    my ($self, %options) = @_;

    my $get_param = [];
    push @$get_param, 'isDismissed=false' unless $options{include_dismissed};

    my $response = $self->request_api(endpoint => '/api/v2/alerts', get_param => $get_param);

    return $response->{alerts} // [];
}

sub get_license {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/api/v2/zicconfiguration/license');
}

sub get_tasks {
    my ($self, %options) = @_;

    my $get_param = [];
    push @$get_param, 'top=' . $options{top} if is_not_empty($options{top});

    my $response = $self->request_api(endpoint => '/api/v2/tasks', get_param => $get_param);

    return $response->{tasks} // [];
}

sub get_member_accounts {
    my ($self, %options) = @_;

    my $response = $self->request_api(endpoint => '/api/v2/zicconfiguration/memberaccounts');

    return $response->{accounts} // [];
}

sub get_member_accounts_statistics {
    my ($self, %options) = @_;

    my $response = $self->request_api(endpoint => '/api/v2/zicconfiguration/memberaccounts/statistics');

    return $response->{accounts} // [];
}

# converts a date-span ('1.02:03:04', '00:15:00.000' or ISO 8601 'PT15M') to seconds
sub timespan_to_seconds {
    my ($self, %options) = @_;

    return undef if is_empty($options{value});

    if ($options{value} =~ /^\s*(-)?(?:(\d+)\.)?(\d+):(\d+):(\d+)(?:\.\d+)?\s*$/) {
        my $seconds = ($2 // 0) * 86400 + $3 * 3600 + $4 * 60 + $5;
        return defined($1) ? -$seconds : $seconds;
    }
    if ($options{value} =~ /^\s*P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:\.\d+)?)S)?)?\s*$/) {
        return int(($1 // 0) * 86400 + ($2 // 0) * 3600 + ($3 // 0) * 60 + ($4 // 0));
    }

    return undef;
}

# converts an ISO 8601 date ('2026-10-31T10:00:00.123Z', '2026-10-31T10:00:00+01:00' or '2026-10-31') to epoch
sub date_to_epoch {
    my ($self, %options) = @_;

    return undef
        if is_empty($options{value})
            || $options{value} !~ /^\s*(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?)?\s*(Z|[+-]\d{2}:?\d{2})?\s*$/i;

    my $tz = defined($7) && uc($7) ne 'Z' ? $7 : 'UTC';
    $tz =~ s/://;

    my $dt = DateTime->new(
        year      => $1,
        month     => $2,
        day       => $3,
        hour      => $4 // 0,
        minute    => $5 // 0,
        second    => $6 // 0,
        time_zone => $tz
    );

    return $dt->epoch();
}

1;

__END__

=head1 NAME

Zerto In-Cloud for AWS (ZIC) REST API

=head1 ZIC API OPTIONS

Zerto In-Cloud for AWS REST API (v2). Authentication uses a Keycloak access token.

=over 8

=item B<--hostname>

Address of the Zerto In-Cloud appliance.

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--api-path>

Define the path prefix of the ZIC REST API (default: '/zic').

=item B<--realm>

Define the Keycloak realm (default: C<zerto>).

=item B<--client-id>

Define the Keycloak client ID.

=item B<--client-secret>

Define the Keycloak client secret. Without --username, the client credentials grant is used.

=item B<--username>

Define a Keycloak user to authenticate with the password grant instead of the client credentials grant.

=item B<--password>

Define the password of the Keycloak user.

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
