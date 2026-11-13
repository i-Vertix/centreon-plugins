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

package apps::proxmox::bs::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw(json_decode is_empty is_not_empty);
use centreon::plugins::constants qw(:messages);
use URI::Escape;
use Digest::SHA qw(sha256_hex);

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
            'port:s'                 => { name => 'port', default => 8007, type => 'port' },
            'proto:s'                => { name => 'proto', default => 'https', regexp_match => '^http[s]?$' },
            'node:s'                 => { name => 'node', default => 'localhost', regexp_match => '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$' },
            'api-token-id:s'         => { name => 'api_token_id', default => '' },
            'api-token-secret:s'     => { name => 'api_token_secret', default => '' },
            'api-username:s'         => { name => 'api_username', default => '' },
            'api-password:s'         => { name => 'api_password', default => '' },
            'realm:s'                => { name => 'realm', default => 'pbs' },
            'ticket-lifetime:s'      => { name => 'ticket_lifetime', default => 5400, numeric => 1, greater_than => 0, less_than_or_equal => 7200 },
            'timeout:s'              => { name => 'timeout', default => 10, numeric => 1, greater_than => 0 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'PBS API OPTIONS', once => 1);

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
        foreach qw/hostname node api_token_id api_token_secret api_username api_password realm/;
    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/ticket_lifetime unknown_http_status warning_http_status critical_http_status/;

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if is_empty($self->{hostname});

    if (is_not_empty($self->{api_token_id})) {
        $self->{output}->option_exit(short_msg => 'Need to specify --api-token-secret option.')
            if is_empty($self->{api_token_secret});
        $self->{auth_type} = 'token';
    } else {
        $self->{output}->option_exit(short_msg => 'Need to specify --api-token-id and --api-token-secret options (or --api-username and --api-password).')
            if is_empty($self->{api_username});
        $self->{output}->option_exit(short_msg => 'Need to specify --api-password option.')
            if is_empty($self->{api_password});
        # the user ID of PBS is 'user@realm'
        $self->{api_username} .= '@' . $self->{realm}
            if $self->{api_username} !~ /@/ && is_not_empty($self->{realm});
        $self->{auth_type} = 'ticket';
    }

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

sub get_node {
    my ($self, %options) = @_;

    return $self->{node};
}

sub get_ticket_cache_name {
    my ($self, %options) = @_;

    return 'proxmox_bs_api_' . sha256_hex($self->get_connection_info() . '_' . $self->{api_username});
}

sub request_ticket {
    my ($self, %options) = @_;

    my $content = $self->{http}->request(
        method          => 'POST',
        url_path        => '/api2/json/access/ticket',
        header          => [ 'Content-Type: application/x-www-form-urlencoded' ],
        query_form_post => 'username=' . uri_escape($self->{api_username}) . '&password=' . uri_escape($self->{api_password}),
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    $self->{output}->option_exit(short_msg => "Authentication failed [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if $self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300;

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless ref($decoded) eq 'HASH';
    $self->{output}->option_exit(short_msg => "Cannot get ticket [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        unless ref($decoded->{data}) eq 'HASH' && is_not_empty($decoded->{data}->{ticket});

    return $decoded->{data}->{ticket};
}

sub get_ticket {
    my ($self, %options) = @_;

    my $secret_hash = sha256_hex($self->{api_password});
    $self->{cache}->read(statefile => $self->get_ticket_cache_name());
    my $ticket = $self->{cache}->get(name => 'ticket');
    my $expires_on = $self->{cache}->get(name => 'expires_on') // 0;
    my $secret_hash_cache = $self->{cache}->get(name => 'secret_hash') // '';

    return $ticket
        if is_not_empty($ticket) && $expires_on > time() && $secret_hash_cache eq $secret_hash;

    $ticket = $self->request_ticket();
    $self->{cache}->write(data => {
        updated     => time(),
        ticket      => $ticket,
        expires_on  => time() + $self->{ticket_lifetime},
        secret_hash => $secret_hash
    });

    return $ticket;
}

sub clean_ticket {
    my ($self, %options) = @_;

    $self->{ticket} = undef;
    $self->{cache}->read(statefile => $self->get_ticket_cache_name());
    $self->{cache}->write(data => { updated => time() });
}

sub get_auth_header {
    my ($self, %options) = @_;

    return 'Authorization: PBSAPIToken=' . $self->{api_token_id} . ':' . $self->{api_token_secret}
        if $self->{auth_type} eq 'token';

    $self->{ticket} //= $self->get_ticket();
    return 'Cookie: PBSAuthCookie=' . $self->{ticket};
}

sub request_api {
    my ($self, %options) = @_;

    my %request = (
        url_path  => '/api2/json' . $options{endpoint},
        get_param => $options{get_param} // []
    );

    # first call without status check: an expired ticket must not end the check
    my $content = $self->{http}->request(
        %request,
        header          => [ $self->get_auth_header() ],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    if ($code < 200 || $code >= 300) {
        $self->clean_ticket() if $code == 401 && $self->{auth_type} eq 'ticket';
        $content = $self->{http}->request(
            %request,
            header          => [ $self->get_auth_header() ],
            unknown_status  => $options{ignore_error} ? '' : $self->{unknown_http_status},
            warning_status  => $options{ignore_error} ? '' : $self->{warning_http_status},
            critical_status => $options{ignore_error} ? '' : $self->{critical_http_status}
        );
    }

    # the caller handles the error (e.g. one datastore that cannot be read)
    if ($options{ignore_error} && ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300)) {
        $self->{output}->output_add(long_msg => "request '" . $options{endpoint} . "' failed [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']", debug => 1);
        return undef;
    }

    $self->{output}->option_exit(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless ref($decoded) eq 'HASH';

    # every PBS response is wrapped in a 'data' attribute
    my $data = $decoded->{data};
    $self->{output}->option_exit(short_msg => "API returns an unexpected response for '" . $options{endpoint} . "' (add --debug option to display returned content)")
        if (defined($options{expect}) && ref($data) ne $options{expect});

    return $data;
}

sub get_node_status {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/nodes/' . $self->{node} . '/status', expect => 'HASH');
}

sub get_services {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/nodes/' . $self->{node} . '/services', expect => 'ARRAY');
}

sub get_disks {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/nodes/' . $self->{node} . '/disks/list', expect => 'ARRAY');
}

sub get_tasks {
    my ($self, %options) = @_;

    # limit=0: no limit, the API returns 50 tasks by default
    my $get_param = [ 'limit=0' ];
    push @$get_param, 'since=' . $options{since} if is_not_empty($options{since});
    push @$get_param, 'typefilter=' . $options{typefilter} if is_not_empty($options{typefilter});
    push @$get_param, 'store=' . $options{store} if is_not_empty($options{store});

    return $self->request_api(endpoint => '/nodes/' . $self->{node} . '/tasks', get_param => $get_param, expect => 'ARRAY');
}

sub get_datastores {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/admin/datastore', expect => 'ARRAY');
}

sub get_datastores_usage {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/status/datastore-usage', expect => 'ARRAY');
}

sub get_snapshots {
    my ($self, %options) = @_;

    my $get_param = [];
    push @$get_param, 'ns=' . $options{namespace} if is_not_empty($options{namespace});

    return $self->request_api(
        endpoint     => '/admin/datastore/' . uri_escape($options{store}) . '/snapshots',
        get_param    => $get_param,
        expect       => 'ARRAY',
        ignore_error => $options{ignore_error}
    );
}

sub get_version {
    my ($self, %options) = @_;

    return $self->request_api(endpoint => '/version', expect => 'HASH');
}

1;

__END__

=head1 NAME

Proxmox Backup Server REST API

=head1 PBS API OPTIONS

Proxmox Backup Server REST API (C</api2/json>).
Authenticate with an API token (C<--api-token-id> and C<--api-token-secret>, recommended)
or with a user and its password (C<--api-username> and C<--api-password>): the plugin then gets a ticket and keeps it in a cache file.

=over 8

=item B<--hostname>

Address of the Proxmox Backup Server.

=item B<--port>

Define the TCP port to use to reach the API (default: 8007).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--node>

Define the node name (default: C<localhost>).

=item B<--api-token-id>

Define the API token ID, e.g. C<monitoring@pbs!user-api>.

=item B<--api-token-secret>

Define the secret of the API token.

=item B<--api-username>

Define the user to authenticate with, e.g. C<monitoring@pbs>. Without a realm, C<--realm> is appended.

=item B<--api-password>

Define the password of the user.

=item B<--realm>

Define the realm appended to a user without a realm (default: C<pbs>).

=item B<--ticket-lifetime>

Define the time in seconds a ticket is reused from the cache file (default: 5400). A PBS ticket expires after 7200 seconds.

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 10).

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
