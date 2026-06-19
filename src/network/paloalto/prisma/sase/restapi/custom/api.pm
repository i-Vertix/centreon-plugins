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

package network::paloalto::prisma::sase::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::statefile;
use DateTime;

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
        $options{options}->add_options(
            arguments => {
                'sase-api:s'             => {
                    name    => 'sase_api',
                    default => 'pa-eu01.api.prismaaccess.com'
                },
                'sase-api-version:s'     => { name => 'sase_api_version', default => 'v2.0' },
                'sase-api-path:s'        => { name => 'sase_api_path', default => '/api/sase/' },
                'auth-api:s'             => {
                    name    => 'auth_api',
                    default => 'auth.apps.paloaltonetworks.com'
                },
                'auth-api-path:s'        => {
                    name    => 'auth_api_path',
                    default => '/oauth2/access_token'
                },
                'port:s'                 => { name => 'port', default => 443 },
                'proto:s'                => { name => 'proto', default => 'https' },
                'client-id:s'            => { name => 'client_id' },
                'client-secret:s'        => { name => 'client_secret' },
                'prisma-tenant:s'        => { name => 'prisma_tenant' },
                'x-panw-region:s'        => { name => 'x_panw_region' => default => 'europe' },
                'timeout:s'              => { name => 'timeout' },
                'unknown-http-status:s'  => {
                    name    => 'unknown_http_status',
                    default => '%{http_code} < 200 or %{http_code} >= 300'
                },
                'warning-http-status:s'  => { name => 'warning_http_status' },
                'critical-http-status:s' => { name => 'critical_http_status' }
            }
        );
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'Palo Alto Prisma SASE REST API OPTIONS', once => 1);

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

    if (!defined($self->{option_results}->{sase_api}) || length($self->{option_results}->{sase_api}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --sase-api option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{sase_api_path}) || length($self->{option_results}->{sase_api_path}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --sase-api-path option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{sase_api_version}) || length($self->{option_results}->{sase_api_version}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --sase-api-version option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{auth_api}) || length($self->{option_results}->{auth_api}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --auth-api option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{auth_api_path}) || length($self->{option_results}->{auth_api_path}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --auth-api-path option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{client_id}) || length($self->{option_results}->{client_id}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-id option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{client_secret}) || length($self->{option_results}->{client_secret}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --client-secret option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{prisma_tenant}) || length($self->{option_results}->{prisma_tenant}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --prisma-tenant option.");
        $self->{output}->option_exit();
    }

    if (defined($options{use_x_panw_region}) && (!defined($self->{option_results}->{x_panw_region}) || length($self->{option_results}->{x_panw_region}) == 0)) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --x-panw-region option.");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{timeout} = (defined($self->{option_results}->{timeout})) ?
        $self->{option_results}->{timeout} :
        10;

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{proto})
        && $self->{option_results}->{proto} !~ /^http|https$/) {
        $self->{output}->add_option_msg(short_msg => "--proto not supported. Available http, https");
        $self->{output}->option_exit();
    }

    $self->{warning_http_status} = (defined($self->{option_results}->{warning_http_status})) ?
        $self->{option_results}->{warning_http_status} :
        '';
    $self->{critical_http_status} = (defined($self->{option_results}->{critical_http_status})) ?
        $self->{option_results}->{critical_http_status} :
        '';
    $self->{unknown_http_status} = (defined($self->{option_results}->{unknown_http_status})) ?
        $self->{option_results}->{unknown_http_status} :
        '';

    $self->{cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub json_decode {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub get_connection_infos {
    my ($self, %options) = @_;

    return $self->{option_results}->{sase_api} . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{timeout} = $self->{option_results}->{timeout};
    $self->{option_results}->{port} = $self->{option_results}->{port};
    $self->{option_results}->{proto} = $self->{option_results}->{proto};
}

sub clean_token {
    my ($self, %options) = @_;

    my $datas = {};
    $options{statefile}->write(data => $datas);
    $self->{access_token} = undef;
    $self->{http}->add_header(key => 'Authorization', value => undef);
}

sub get_auth_token {
    my ($self, %options) = @_;

    my $has_cache_file = $options{statefile}->read(statefile =>
        'extremecloudiq_api_' . md5_hex($self->{option_results}->{sase_api}) . '_' . md5_hex($self->{option_results}->{client_id}));
    my $expires_on = $options{statefile}->get(name => 'expires_on');
    my $access_token = $options{statefile}->get(name => 'access_token');

    my $post_data = 'grant_type=client_credentials' . "&scope=tsg_id:$self->{option_results}->{prisma_tenant}";

    # Token expires every 1 day
    if ($has_cache_file == 0 || !defined($access_token) || (time() > $expires_on)) {
        $self->{http}->add_header(key => 'Content-Type', value => 'application/x-www-form-urlencoded');

        my ($content) = $self->{http}->request(
            hostname        => $self->{option_results}->{auth_api},
            url_path        => $self->{option_results}->{auth_api_path},
            method          => 'POST',
            credentials     => 1,
            basic           => 1,
            username        => $self->{option_results}->{client_id},
            password        => $self->{option_results}->{client_secret},
            query_form_post => $post_data,
            unknown_status  => $self->{option_results}->{unknown_http_status},
            warning_status  => $self->{option_results}->{warning_http_status},
            critical_status => $self->{option_results}->{critical_http_status}
        );

        $self->{http}->remove_header(key => 'Content-Type');

        if ($self->{http}->get_code() != 200) {
            $self->{output}->add_option_msg(
                short_msg =>
                    "Authentication error [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']"
            );
            $self->{output}->option_exit();
        }

        my $decoded = $self->json_decode(content => $content);
        if (!defined($decoded->{access_token})) {
            $self->{output}->add_option_msg(short_msg => "Cannot get token");
            $self->{output}->option_exit();
        }

        $access_token = $decoded->{access_token};
        my $datas = {
            access_token => $access_token,
            expires_on   => time() + 900
        };
        $options{statefile}->write(data => $datas);
    }

    $self->{access_token} = $access_token;
    $self->{http}->add_header(key => 'Authorization', value => 'Bearer ' . $self->{access_token});
}

sub request_api {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->set_options(%{$self->{option_results}});

    if (!defined($self->{access_token})) {
        $self->get_auth_token(statefile => $self->{cache});
    }

    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');

    if (defined($options{use_prisma_tenant_header}) && $options{use_prisma_tenant_header} == 1) {
        $self->{http}->add_header(key => 'Prisma-Tenant', value => $self->{option_results}->{prisma_tenant});
    }

    if (defined($options{use_x_panw_region}) && $options{use_x_panw_region} == 1) {
        $self->{http}->add_header(key => 'X-PANW-Region', value => $self->{option_results}->{x_panw_region});
    }

    my $url_path = $self->{option_results}->{sase_api_path} . '/' . $self->{option_results}->{sase_api_version} . '/' . $options{endpoint};
    $url_path =~ s{(?<!:)//+}{/}g;

    my $content = $self->{http}->request(
        method          => $options{method},
        hostname        => $self->{option_results}->{sase_api},
        url_path        => $url_path,
        query_form_post => $options{post_body},
        warning_status  => '',
        unknown_status  => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();

    # Maybe there is an issue with the token. So we retry.
    if (!defined($self->{access_token}) || $code =~ /400|401|403/) {
        $self->clean_token(statefile => $self->{cache});
        $self->get_auth_token(statefile => $self->{cache});
        $content = $self->{http}->request(
            method         => $options{method},
            hostname       => $self->{option_results}->{sase_api},
            url_path       => $url_path,
            query_form_post => $options{post_body},
            unknown_status  => $self->{unknown_http_status},
            warning_status  => $self->{warning_http_status},
            critical_status => $self->{critical_http_status}
        );
    }

    my $decoded = $self->json_decode(content => $content);
    if (!defined($decoded)) {
        $self->{output}->add_option_msg(
            short_msg => 'Error while retrieving data (add --debug option for detailed message)'
        );
        $self->{output}->option_exit();
    }
    if ($self->{http}->get_code() < 200 || $self->{http}->get_code() >= 300) {
        my $message = 'api request error';
        if (defined($decoded->{error_message})) {
            $message .= ': ' . $decoded->{error_message};
        }
        $self->{output}->add_option_msg(short_msg => $message);
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Palo Alto Prisma SASE REST API

=head1 Palo Alto Prisma SASE REST API OPTIONS

Palo Alto Prisma SASE REST API

=over 8

=item B<--sase-api>

Palo Alto Prisma SASE api URL. (default: pa-eu01.api.prismaaccess.com)

=item B<--sase-api-version>

Define the API version (default: v2.0).

=item B<--sase-api-path>

Define the API path (default: /api/sase/).

=item B<--auth-api>

Define the API version (default: auth.apps.paloaltonetworks.com).

=item B<--auth-api-path>

Define the API path (default: /oauth2/access_token).

=item B<--port>

Define the TCP port to use to reach the API (default: 443).

=item B<--proto>

Define the protocol to reach the API (default: 'https').

=item B<--client-id>

Prisma SASE Client ID
https://pan.dev/sase/docs/access-tokens/

=item B<--client-secret>

Prisma SASE Client Secret
https://pan.dev/sase/docs/access-tokens/

=item B<--prisma-tenant>

Prisma SASE Tenant 'tsg_id'
https://pan.dev/sase/docs/access-tokens/

=item B<--x-panw-region>

Prisma SASE x-panw-region (default: 'europe')
https://pan.dev/sase/docs/api-call/#about-x-panw-region

=item B<--timeout>

Define the timeout in seconds for HTTP requests (default: 30).

=item B<--unknown-http-status>

Threshold unknown for http response code (default: '%{http_code} < 200 or (%{http_code} >= 300 && %{http_code} != 404)')

=item B<--warning-http-status>

Warning threshold for http response code

=item B<--critical-http-status>

Critical threshold for http response code

=back

=head1 DESCRIPTION

B<custom>.

=cut
