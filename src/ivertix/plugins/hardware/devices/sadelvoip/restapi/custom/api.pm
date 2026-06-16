#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::custom::api;

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
            'api-path:s'             => { name => 'api_path', default => '/api/v1' },
            'hostname:s'             => { name => 'hostname' },
            'port:s'                 => { name => 'port', default => 443, greater_than => 0, less_than => 65536 },
            'proto:s'                => { name => 'proto', default => 'https', regexp_match => '^http[s]?$' },
            'timeout:s'              => { name => 'timeout', default => 30, greater_than => 0, less_than => 120 },
            'insecure'               => { name => 'insecure' },
            'unknown-http-status:s'  => {
                name    => 'unknown_http_status',
                default => '%{http_code} < 200 or %{http_code} >= 300'
            },
            'warning-http-status:s'  => { name => 'warning_http_status', default => '' },
            'critical-http-status:s' => { name => 'critical_http_status', default => '' },
            'api-key:s'              => { name => 'api_key' }
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

    $self->{api_key} = $self->{option_results}->{api_key};
    $self->{api_path} = $self->{option_results}->{api_path};

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }

    if (defined($self->{api_key})) {
        return 0 if ($self->{api_key} ne '');
    }

    if (defined($self->{api_path})) {
        return 0 if ($self->{api_path} ne '');
    }

    return 0;
}

sub settings {
    my ($self, %options) = @_;

    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    $self->{http}->add_header(key => 'apikey', value => $self->{api_key});
    $self->{http}->set_options(%{$self->{option_results}});
}

sub request_api {
    my ($self, %options) = @_;

    $self->settings();

    my $path = $self->{api_path};
    my $endpoint = $options{endpoint};

    $path =~ s{/$}{};
    $endpoint =~ s{^/}{};

    my $url_path = "$path/$endpoint";

    my ($content) = $self->{http}->request(
        url_path        => $url_path,
        get_param       => $options{get_param},
        method          => $options{method},
        insecure        => $self->{option_results}->{insecure},
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

C<SadelVoip> Rest API

=head1 REST API OPTIONS

SadelVoip Rest API

=over 8

=item B<--hostname>

Set hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--api-key>

Token API key

=item B<--api-path>

Use api path. (Default: '/api/v1')

=item B<--timeout>

Set timeout in seconds (Default: 30).

=item B<--insecure>

Accept insecure SSL connections.

=item B<--unknown-http-status>

Threshold for unknown HTTP status (default: '%{http_code} < 200 or %{http_code} >= 300').

=item B<--warning-http-status>

Threshold for warning HTTP status.

=item B<--critical-http-status>

Threshold for critical HTTP status.

=back

=head1 DESCRIPTION

B<custom>.

=cut
