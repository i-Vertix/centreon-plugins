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

package cloud::sangfor::scp::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use centreon::plugins::misc qw(json_decode json_encode is_empty is_not_empty);
use centreon::plugins::constants qw(:messages);
use Digest::SHA qw(sha256_hex hmac_sha256 hmac_sha256_hex);
use POSIX qw(strftime);
use Time::Local qw(timegm);

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
            'port:s'                 => { name => 'port', default => 443, type => 'port' },
            'proto:s'                => { name => 'proto', default => 'https', type => 'protocol_http' },
            'access-key:s'           => { name => 'access_key', default => '' },
            'secret-key:s'           => { name => 'secret_key', default => '' },
            'region:s'               => { name => 'region', default => 'cn-south-1', not_empty => 1 },
            'service:s'              => { name => 'service', default => 'open-api', not_empty => 1 },
            'api-username:s'         => { name => 'api_username', default => '' },
            'api-password:s'         => { name => 'api_password', default => '' },
            'auth-version:s'         => { name => 'auth_version', default => 'v2', is_in => [ 'v1', 'v2' ] },
            'timeout:s'              => { name => 'timeout', default => 30, greater_than => 0 },
            'unknown-http-status:s'  => { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  => { name => 'warning_http_status' },
            'critical-http-status:s' => { name => 'critical_http_status' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'SCP API OPTIONS', once => 1);

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
        foreach qw/hostname access_key secret_key region service api_username api_password auth_version/;
    $self->{$_} = $self->{option_results}->{$_}
        foreach qw/unknown_http_status warning_http_status critical_http_status/;

    $self->{output}->option_exit(short_msg => 'Need to specify --hostname option.')
        if is_empty($self->{hostname});

    if (is_not_empty($self->{access_key})) {
        $self->{output}->option_exit(short_msg => 'Need to specify --secret-key option.')
            if is_empty($self->{secret_key});
        $self->{auth_type} = 'ec2';
    } else {
        $self->{output}->option_exit(short_msg => 'Need to specify --access-key and --secret-key options (or --api-username and --api-password).')
            if is_empty($self->{api_username});
        $self->{output}->option_exit(short_msg => 'Need to specify --api-password option.')
            if is_empty($self->{api_password});
        $self->{auth_type} = 'token';
    }

    # the session cookie is only needed by the legacy (v1) token authentication, the value can be any string
    $self->{cookie_header} = $self->{auth_type} eq 'token' && $self->{auth_version} eq 'v1'
        ? [ 'Cookie: aCMPAuthToken=' . substr(sha256_hex(time() . $$ . rand()), 0, 32) ]
        : [];

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{http}->add_header(key => 'Accept', value => 'application/json');

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;
    return $self->{hostname} . ':' . $self->{option_results}->{port};
}

# returns the headers of the AWS4-HMAC-SHA256 (EC2) signature described in the SCP API documentation:
# only the path and the x-amz-date header are signed, the query string is not part of the signature
sub get_ec2_headers {
    my ($self, %options) = @_;

    my $time = $options{time} // time();
    my $amz_date = strftime('%Y%m%dT%H%M%SZ', gmtime($time));
    my $date_stamp = substr($amz_date, 0, 8);
    my $signed_headers = 'path;x-amz-date';
    my $credential_scope = join('/', $date_stamp, $self->{region}, $self->{service}, 'aws4_request');

    my $canonical_request = join("\n",
        $options{method},
        $options{path},
        '',
        'x-amz-date:' . $amz_date . "\n",
        $signed_headers,
        sha256_hex($options{body} // '')
    );
    my $string_to_sign = join("\n", 'AWS4-HMAC-SHA256', $amz_date, $credential_scope, sha256_hex($canonical_request));

    my $signing_key = 'AWS4' . $self->{secret_key};
    $signing_key = hmac_sha256($_, $signing_key)
        foreach ($date_stamp, $self->{region}, $self->{service}, 'aws4_request');
    my $signature = hmac_sha256_hex($string_to_sign, $signing_key);

    return [
        'Authorization: AWS4-HMAC-SHA256 Credential=' . $self->{access_key} . '/' . $credential_scope .
            ', SignedHeaders=' . $signed_headers . ', Signature=' . $signature,
        'X-Amz-Date: ' . $amz_date
    ];
}

# checks the common response format: 'code' (before 20240725) or 'errcode' (since 20240725)
sub check_response {
    my ($self, %options) = @_;

    my $decoded = $options{decoded};
    return $decoded unless ref($decoded) eq 'HASH' && (exists($decoded->{code}) || exists($decoded->{errcode}));

    my $error = '';
    $error = $decoded->{code} if defined($decoded->{code}) && $decoded->{code} ne '0';
    $error = $decoded->{errcode} if is_not_empty($decoded->{errcode}) && $decoded->{errcode} ne '0';
    $self->{output}->option_exit(short_msg => "API returns error code '" . $error . "': " . ($decoded->{message} // ''))
        if $error ne '';

    return $decoded->{data};
}

sub encrypt_password {
    my ($self, %options) = @_;

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'Crypt::OpenSSL::RSA',
        error_msg => 'Cannot load module Crypt::OpenSSL::RSA (needed for token authentication).'
    );
    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'Crypt::OpenSSL::Bignum',
        error_msg => 'Cannot load module Crypt::OpenSSL::Bignum (needed for token authentication).'
    );

    my $encrypted = eval {
        my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters(
            Crypt::OpenSSL::Bignum->new_from_hex($options{modulus}),
            Crypt::OpenSSL::Bignum->new_from_decimal('65537')
        );
        if ($self->{auth_version} eq 'v2') {
            $rsa->use_pkcs1_oaep_padding();
        } else {
            $rsa->use_pkcs1_padding();
        }
        return unpack('H*', $rsa->encrypt($self->{api_password}));
    };
    $self->{output}->option_exit(short_msg => 'Cannot encrypt the password with the public key: ' . $@)
        if $@ || is_empty($encrypted);

    return $encrypted;
}

sub request_auth {
    my ($self, %options) = @_;

    my $content = $self->{http}->request(
        %options,
        unknown_status  => $self->{unknown_http_status},
        warning_status  => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );
    $self->{output}->option_exit(short_msg => "Authentication endpoint returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']")
        if is_empty($content);

    my $decoded = json_decode($content, output => $self->{output}, no_exit => 1);
    $self->{output}->option_exit(short_msg => MSG_JSON_DECODE_ERROR)
        unless ref($decoded) eq 'HASH';

    return $self->check_response(decoded => $decoded);
}

sub get_token {
    my ($self, %options) = @_;

    $self->{cache}->read(
        statefile => 'sangfor_scp_api_' . sha256_hex($self->get_connection_info() . '_' . $self->{api_username} . '_' . $self->{auth_version})
    );
    my $token = $self->{cache}->get(name => 'token');
    my $expires_on = $self->{cache}->get(name => 'expires_on') // 0;
    my $secret_hash = sha256_hex($self->{api_password});
    my $secret_hash_cache = $self->{cache}->get(name => 'secret_hash') // '';

    return $token
        if is_not_empty($token) && ($expires_on - time()) >= 60 && $secret_hash_cache eq $secret_hash;

    my $prefix = $self->{auth_version} eq 'v2' ? '/janus/v2' : '/janus';

    my $public_key = $self->request_auth(
        url_path => $prefix . '/public-key',
        header   => $self->{cookie_header}
    );
    my $modulus = ref($public_key) eq 'HASH' ? ($public_key->{public_key} // '') : '';
    $modulus =~ s/(?:\\n|\s)+//g;
    $self->{output}->option_exit(short_msg => 'Cannot get the public key modulus.')
        if is_empty($modulus);

    my $body = json_encode(
        { auth => { passwordCredentials => { username => $self->{api_username}, password => $self->encrypt_password(modulus => $modulus) } } },
        output => $self->{output}
    );
    my $access = $self->request_auth(
        method          => 'POST',
        url_path        => $prefix . '/authenticate',
        header          => [ 'Content-Type: application/json', @{$self->{cookie_header}} ],
        query_form_post => $body
    );
    my $token_info = ref($access) eq 'HASH' && ref($access->{access}) eq 'HASH' ? $access->{access}->{token} : undef;
    $self->{output}->option_exit(short_msg => 'Cannot get token from the authentication response.')
        unless ref($token_info) eq 'HASH' && is_not_empty($token_info->{id});

    # the token is valid 24 hours
    $expires_on = time() + 86400;
    if (defined($token_info->{expires}) && $token_info->{expires} =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
        $expires_on = timegm($6, $5, $4, $3, $2 - 1, $1);
    }

    $self->{cache}->write(data => {
        updated     => time(),
        token       => $token_info->{id},
        expires_on  => $expires_on,
        secret_hash => $secret_hash
    });

    return $token_info->{id};
}

sub clean_token {
    my ($self, %options) = @_;
    $self->{cache}->write(data => { updated => time() });
}

sub get_auth_headers {
    my ($self, %options) = @_;

    return $self->get_ec2_headers(method => $options{method}, path => $options{path})
        if $self->{auth_type} eq 'ec2';

    return [ 'Authorization: Token ' . $self->get_token() ];
}

sub request_api {
    my ($self, %options) = @_;

    my $method = $options{method} // 'GET';
    my %request = (
        method    => $method,
        url_path  => $options{endpoint},
        get_param => $options{get_param} // []
    );

    # first call without status check: an expired token must not end the check
    my $content = $self->{http}->request(
        %request,
        header          => [ @{$self->{cookie_header}}, @{$self->get_auth_headers(method => $method, path => $options{endpoint})} ],
        unknown_status  => '',
        warning_status  => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    $self->clean_token() if $code == 401 && $self->{auth_type} eq 'token';
    if ($code < 200 || $code >= 300) {
        $content = $self->{http}->request(
            %request,
            header          => [ @{$self->{cookie_header}}, @{$self->get_auth_headers(method => $method, path => $options{endpoint})} ],
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

    return $self->check_response(decoded => $decoded);
}

# list queries return either a list or a paginated object: { data => [], page_num => 0, next_page_num => '1', ... }
sub request_api_list {
    my ($self, %options) = @_;

    my $results = [];
    my $page_num = 0;
    my $page_size = 100;
    while (1) {
        my $data = $self->request_api(
            endpoint  => $options{endpoint},
            get_param => [ @{$options{get_param} // []}, 'page_num=' . $page_num, 'page_size=' . $page_size ]
        );

        return $data if ref($data) eq 'ARRAY';
        last unless ref($data) eq 'HASH' && ref($data->{data}) eq 'ARRAY';

        push @$results, @{$data->{data}};
        last if is_empty($data->{next_page_num}) || $data->{next_page_num} !~ /^\d+$/ || $data->{next_page_num} <= $page_num;
        last if defined($data->{total_size}) && scalar(@$results) >= $data->{total_size};
        $page_num = $data->{next_page_num};
    }

    return $results;
}

sub get_resource_pools {
    my ($self, %options) = @_;
    return $self->request_api_list(endpoint => '/janus/20180725/azs');
}

sub get_resource_pool {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/janus/20180725/azs/' . $options{id});
}

sub get_clusters {
    my ($self, %options) = @_;
    my $get_param = [];
    push @$get_param, 'az_id=' . $options{az_id} if is_not_empty($options{az_id});
    return $self->request_api_list(endpoint => '/janus/20180725/clusters', get_param => $get_param);
}

sub get_hosts {
    my ($self, %options) = @_;
    my $get_param = [];
    push @$get_param, 'az_id=' . $options{az_id} if is_not_empty($options{az_id});
    return $self->request_api_list(endpoint => '/janus/20180725/hosts', get_param => $get_param);
}

sub get_storages {
    my ($self, %options) = @_;
    my $get_param = [];
    push @$get_param, 'az_id=' . $options{az_id} if is_not_empty($options{az_id});
    return $self->request_api_list(endpoint => '/janus/20180725/storages', get_param => $get_param);
}

sub get_vms {
    my ($self, %options) = @_;
    my $get_param = [];
    foreach (qw/ids az_id host_id project_id/) {
        push @$get_param, $_ . '=' . $options{$_} if is_not_empty($options{$_});
    }
    return $self->request_api_list(endpoint => '/janus/20190725/servers', get_param => $get_param);
}

sub get_alarms {
    my ($self, %options) = @_;
    return $self->request_api_list(endpoint => '/janus/20190725/alarms', get_param => $options{get_param});
}

sub get_licenses {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/janus/20180725/licenses/summary');
}

sub get_maintenance {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/janus/20180725/system/maintenance');
}

sub get_version {
    my ($self, %options) = @_;
    return $self->request_api(endpoint => '/janus/20180725/system/version');
}

1;

__END__

=head1 NAME

Sangfor Cloud Platform (SCP) REST API.

=head1 SCP API OPTIONS

Sangfor Cloud Platform (SCP) Open API. Authentication uses an access key and a secret key (C<EC2> signature,
recommended) or a username and a password (token).

=over 8

=item B<--hostname>

Define the address of the SCP platform.

=item B<--port>

Define the port of the API (default: C<443>).

=item B<--proto>

Define the protocol of the API (default: C<https>). SCP uses a self-signed certificate by default:
add C<--insecure> (curl backend) or C<--ssl-opt="SSL_verify_mode =E<gt> SSL_VERIFY_NONE"> (lwp backend) if needed.

=item B<--access-key>

Define the access key (AK) used for the C<EC2> authentication.

=item B<--secret-key>

Define the secret key (SK) used for the C<EC2> authentication.

=item B<--region>

Define the region used in the C<EC2> signature (default: C<cn-south-1>).

=item B<--service>

Define the service used in the C<EC2> signature (default: C<open-api>).

=item B<--api-username>

Define the username used for the token authentication (used when C<--access-key> is not set).

=item B<--api-password>

Define the password used for the token authentication. The password is encrypted with the public key of the
platform: the Perl modules C<Crypt::OpenSSL::RSA> and C<Crypt::OpenSSL::Bignum> are needed.

=item B<--auth-version>

Define the version of the token authentication API: C<v2> (SCP 6.11.3 and later, default) or C<v1> (legacy API of older versions).

=item B<--timeout>

Define the timeout of the HTTP requests in seconds (default: C<30>).

=item B<--unknown-http-status>

Define the conditions to match on the HTTP status code for the returned status to be UNKNOWN (default: C<'%{http_code} E<lt> 200 or %{http_code} E<gt>= 300'>).

=item B<--warning-http-status>

Define the conditions to match on the HTTP status code for the returned status to be WARNING.

=item B<--critical-http-status>

Define the conditions to match on the HTTP status code for the returned status to be CRITICAL.

=back

=head1 DESCRIPTION

B<custom>.

=cut
