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

package hardware::devices::axentia::epaper::restapi::custom::api;

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
            'api-key:s'              =>
                { name => 'api-key' },
            'api-path:s'             =>
                { name => 'api_path', default => 'api' },
            'api-version:s'          =>
                { name => 'api_version', default => '4.0' },
            'hostname:s'             =>
                { name => 'hostname' },
            'port:s'                 =>
                { name => 'port', default => 443 },
            'proto:s'                =>
                { name => 'proto', default => 'https' },
            'timeout:s'              =>
                { name => 'timeout' },
            'unknown-http-status:s'  =>
                { name => 'unknown_http_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
            'warning-http-status:s'  =>
                { name => 'warning_http_status' },
            'critical-http-status:s' =>
                { name => 'critical_http_status' }
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

    $self->{api_key} = defined($self->{option_results}->{api_key}) ?
        $self->{option_results}->{api_key} :
        '';
    $self->{warning_http_status} = defined($self->{option_results}->{warning_http_status}) ?
        $self->{option_results}->{warning_http_status} :
        '';
    $self->{critical_http_status} = defined($self->{option_results}->{critical_http_status}) ?
        $self->{option_results}->{critical_http_status} :
        '';

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    if ($self->{api_key} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-key option.');
        $self->{output}->option_exit();
    }
    if ($self->{api_version} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-version option.');
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
    $self->{http}->add_header(key => 'apikey', value => $self->{api_key});
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

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    $self->{api_path} =~ s/\/$//;
    $options{endpoint} =~ s/^\/+//;

    my $get_param = [];
    $get_param = $options{get_param} if (defined($options{get_param}));
    push @$get_param, 'api-version=' . $self->{api_version};

    my ($content) = $self->{http}->request(
        url_path        => $self->{api_path} . $options{endpoint},
        get_param       => $get_param,
        method          => 'GET',
        unknown_status  => $self->{unknown_http_status},
        warning_status  => $self->{warning_http_status},
        critical_status => $self->{critical_http_status}
    );

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg =>
            "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->allow_nonref(1)->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg =>
            "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }

    return $decoded;
}

1;

__END__

=head1 NAME

Axentia e-paper Rest API

=head1 REST API OPTIONS

Infinitys Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-client-id>

API client id.

=item B<--api-client-secret>

API client secret.

=item B<--token>

Use token authentication. If option is empty, token is created.
Only for test purpose because token are valid only an hour by default.

=item B<--timeout>

Set timeout in seconds (Default: 30).

=back

=head1 DESCRIPTION

B<custom>.

=cut
