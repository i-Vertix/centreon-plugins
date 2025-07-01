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

package ivertix::plugins::notification::sguard::restapi::mode::alert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "event-mode:s"          => { name => 'event_mode', default => "key-text" },
        "key-text:s"            => { name => 'key_text' },
        "event-id:s"            => { name => 'event_id' },
        "fallback-key-text:s"   => { name => 'fallback_key_text' },
        "fallback-event-id:s"   => { name => 'fallback_event_id' },
        "alert-type:s"          => { name => 'alert_type' },
        "host-name:s"           => { name => 'host_name' },
        "host-state:s"          => { name => 'host_state' },
        "host-output:s"         => { name => 'host_output' },
        "host-notes:s"          => { name => 'host_notes' },
        "service-description:s" => { name => 'service_description' },
        "service-state:s"       => { name => 'service_state' },
        "service-output:s"      => { name => 'service_output' },
        "service-notes:s"       => { name => 'service_notes' },
        "short-datetime:s"      => { name => 'short_datetime' },
        "link-url:s"            => { name => 'link_url' },
        "custom-message:s"      => { name => 'custom_message' },
        "response-log-dir:s"    => { name => 'response_log_dir' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{event_mode}) && $self->{option_results}->{event_mode}) {
        if ($self->{option_results}->{event_mode} !~ /key-text|event-id/) {
            $self->{output}->add_option_msg(short_msg => "Value for option --event-mode not valid.");
            $self->{output}->option_exit();
        }
    }

    if ($self->{option_results}->{event_mode} eq 'key-text' &&
        (!defined($self->{option_results}->{key_text}) || $self->{option_results}->{key_text} eq '') &&
        (!defined($self->{option_results}->{fallback_key_text}) || $self->{option_results}->{fallback_key_text} eq '')) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --key-text or --fallback-key-text option.");
        $self->{output}->option_exit();
    } elsif ($self->{option_results}->{event_mode} eq 'event-id' &&
        (!defined($self->{option_results}->{event_id}) || $self->{option_results}->{event_id} eq '') &&
        (!defined($self->{option_results}->{fallback_event_id}) || $self->{option_results}->{fallback_event_id} eq '')) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --event-id or --fallback-event-id option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{alert_type}) || $self->{option_results}->{alert_type} !~ /host|service|custom/) {
        $self->{output}->add_option_msg(short_msg => "--alert-type must be 'host', 'service' or 'custom'.");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{alert_type} eq 'custom' &&
        (!defined($self->{option_results}->{custom_message}) || $self->{option_results}->{custom_message} eq '')) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --custom-message option.");
        $self->{output}->option_exit();
    }

    if (($self->{option_results}->{alert_type} eq 'host' || $self->{option_results}->{alert_type} eq 'service')
        && (!defined($self->{option_results}->{host_name}) || $self->{option_results}->{host_name} eq '')) {
        $self->{output}->add_option_msg(short_msg => "You need to specify --host-name option.");
        $self->{output}->option_exit();

        if ($self->{option_results}->{alert_type} eq 'service' &&
            (!defined($self->{option_results}->{service_description})
                || $self->{option_results}->{service_description} eq '')) {
            $self->{output}->add_option_msg(short_msg => "You need to specify --service-description option.");
            $self->{output}->option_exit();
        }
    }

    if (defined($self->{option_results}->{response_log_dir})) {
        if (!-e $self->{option_results}->{response_log_dir} && !mkdir $self->{option_results}->{response_log_dir}) {
            $self->{output}->add_option_msg(short_msg => "Please specify a valid response_log_dir");
            $self->{output}->option_exit();
        }
    }
}

sub build_host_message {
    my $self = shift;
    my $message = "Host " . $self->{option_results}->{host_name};

    if (defined($self->{option_results}->{host_state}) && $self->{option_results}->{host_state} ne '') {
        $message .= ", " . $self->{option_results}->{host_state};
    }

    if (defined($self->{option_results}->{short_datetime}) && $self->{option_results}->{short_datetime} ne '') {
        $message .= " since " . $self->{option_results}->{short_datetime};
    }

    if (defined($self->{option_results}->{host_output}) && $self->{option_results}->{host_output} ne '') {
        $message .= ": " . $self->{option_results}->{host_output} . '.';
    }

    if (defined($self->{option_results}->{host_notes}) && $self->{option_results}->{host_notes} ne '') {
        $message .= " Host-Notes: " . $self->{option_results}->{host_notes} . '.';
    }

    if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $message .= " Host-Link: " . $self->{option_results}->{link_url};
    }

    return $message;
}

sub build_service_message {
    my $self = shift;
    my $message = "Service " . $self->{option_results}->{service_description} .
        " (" . $self->{option_results}->{host_name} . ")";

    if (defined($self->{option_results}->{service_state}) && $self->{option_results}->{service_state} ne '') {
        $message .= ", " . $self->{option_results}->{service_state};
    }

    if (defined($self->{option_results}->{short_datetime}) && $self->{option_results}->{short_datetime} ne '') {
        $message .= " since " . $self->{option_results}->{short_datetime};
    }

    if (defined($self->{option_results}->{service_output}) && $self->{option_results}->{service_output} ne '') {
        $message .= ": " . $self->{option_results}->{service_output} . '.';
    }

    if (defined($self->{option_results}->{host_notes}) && $self->{option_results}->{host_notes} ne '') {
        $message .= " Host-Notes: " . $self->{option_results}->{host_notes} . '.';
    }

    if (defined($self->{option_results}->{service_notes}) && $self->{option_results}->{service_notes} ne '') {
        $message .= " Service-Notes: " . $self->{option_results}->{service_notes} . '.';
    }

    if (defined($self->{option_results}->{link_url}) && $self->{option_results}->{link_url} ne '') {
        $message .= " Host-Link: " . $self->{option_results}->{link_url};
    }

    return $message;
}

sub set_request_body($$) {
    my $self = shift;
    my ($use_fallback) = @_;

    my $json = JSON->new;
    my $json_body = undef;
    my $body_obj = undef;
    my $message = undef;

    if ($self->{option_results}->{alert_type} eq 'custom') {
        $message = $self->{option_results}->{custom_message};
    } elsif ($self->{option_results}->{alert_type} eq 'host') {
        $message = $self->build_host_message();
    } else {
        $message = $self->build_service_message();
    }

    if ($self->{option_results}->{event_mode} eq "event-id") {
        my $event_id = $use_fallback == 1 ?
            $self->{option_results}->{fallback_event_id} :
            $self->{option_results}->{event_id};
        $body_obj = { message => $message, eventId => $event_id };
    } else {
        my $keyText = $use_fallback == 1 ?
            $self->{option_results}->{fallback_key_text} :
            $self->{option_results}->{key_text};

        my @key_text_arr = ();
        if (index($keyText, ";") != -1) {
            @key_text_arr = split(';', $keyText);
        } else {
            push @key_text_arr, $keyText;
        }

        $body_obj = { message => $message, keyText => \@key_text_arr };
    }

    eval {
        $json_body = $json->encode($body_obj);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    return $json_body;
}

sub write_log($) {
    my $self = shift;
    my ($content) = @_;

    if (defined($self->{option_results}->{response_log_dir})) {
        my $log_file = "$self->{option_results}->{response_log_dir}/response.log";

        open FILE, '>>', $log_file;
        my $log = strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $content\n";
        print FILE "$log";
        close FILE;
    }
}

sub run {
    my ($self, %options) = @_;
    my $used_fallback = 0;

    my $fallback = $self->{option_results}->{event_mode} eq "event-id" ?
        $self->{option_results}->{fallback_event_id} : $self->{option_results}->{fallback_key_text};

    if (($self->{option_results}->{event_mode} eq "key-text" &&
        (!defined($self->{option_results}->{key_text}) || $self->{option_results}->{key_text} eq ''))
        || ($self->{option_results}->{event_mode} eq "event-id" &&
        (!defined($self->{option_results}->{event_id}) || $self->{option_results}->{event_id} eq ''))) {

        $self->write_log("Warning: No $self->{option_results}->{event_mode} passed." .
            " Trying to use fallback $self->{option_results}->{event_mode} $fallback");
        $used_fallback = 1;
    }

    my $body = $self->set_request_body($used_fallback);

    $self->write_log($body);

    my $api_response = $options{custom}->request_api(endpoint => '/episodes', method => 'POST', body => $body);
    my $http_status = $api_response->{status};
    my $json_content = $api_response->{result};
    my $response_msg = undef;

    if (!defined($json_content)) {
        $response_msg = "Api response has no json content";
        $self->write_log($response_msg);
        $self->{output}->add_option_msg(short_msg => $response_msg);
        $self->{output}->option_exit();
    }

    # on a http_status != 200 we have always a json like this
    # {
    #     "name": "Bad Request or Not Found or ...",
    #     "message": "[s.GUARD Error Code] Description",
    #     "code": s.GUARD Error Code,
    #     "status": http code
    # }

    # Key text does not correspond. Try Fallback
    if ($http_status != 200 && ($json_content->{code} == 2003 || $json_content->{code} == 1100) &&
        $used_fallback == 0 && defined($fallback)) {
        $response_msg = "Warning: Received http response status code [$http_status] - $json_content->{name} - $json_content->{message}." .
            " Code $json_content->{code}. Trying to use fallback $self->{option_results}->{event_mode} $fallback";

        $self->write_log($response_msg);

        $body = $self->set_request_body(1);
        $api_response = $options{custom}->request_api(endpoint => '/episodes', method => 'POST', body => $body);
        $http_status = $api_response->{status};
        $json_content = $api_response->{result};
        $used_fallback = 1;
    }

    if ($http_status != 200 && ($json_content->{code} == 2003 || $json_content->{code} == 1100)) {
        $response_msg = $used_fallback == 1 ?
            "Error: Received http response status code [$http_status] - $json_content->{name} using fallback" .
                " $self->{option_results}->{event_mode} $fallback - $json_content->{message}. Code $json_content->{code}." :
            "Error: Received http response status code [$http_status] - $json_content->{name} - $json_content->{message}. Code $json_content->{code}.";

        if (!defined($fallback)) {
            $response_msg .= " No Fallback $self->{option_results}->{event_mode} $fallback defined.";
        }
    } else {
        $response_msg = $http_status == 200 ?
            "[Ok] Received http response status code [$http_status] from sguard api" :
            "Error: Received http response status code [$http_status] - $json_content->{name} - $json_content->{message}. Code $json_content->{code}";
    }

    $self->write_log($response_msg);

    $self->{output}->output_add(short_msg => $response_msg);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send an alert to s.guard

Example for a keyText alert:
centreon_plugins.pl --plugin=ivertix::plugins::notification::sguard::restapi::plugin --mode=alert --hostname=api.instasolution.ch --proto=https --api-path=/api/v2 --email='user@domain.com' --password='1234' --api-key='longkey' --event-mode=key-text --key-text="keytext1;keytext2" --fallback-key-text="keytext3" --custom-message="CRITICAL: this is my error" --response-log-dir=/var/log/sguard/

Example for a eventId alert:
centreon_plugins.pl --plugin=ivertix::plugins::notification::sguard::restapi::plugin --mode=alert --hostname=api.instasolution.ch --proto=https --api-path=/api/v2 --email='user@domain.com' --password='1234' --api-key='longkey' --event-mode=event-id --event-id=1 --fallback-event-id=2 --custom-message="CRITICAL: this is my error" --response-log-dir=/var/log/sguard/

=over 8

=item B<--event-mode>

Specify to send the alert using a "key-text" or a "event-id" (Default: 'key-text').

=item B<--key-text>

Specify the keyText. Multiple keyText separated by ';' (Required if mode is key-text).

=item B<--fallback-key-text>

Specify the fallback keyText if the api can't found the given one

=item B<--event-id>

Specify the event-id. (Required if mode is event-id).

=item B<--fallback-event-id>

Specify the fallback eventId if the api can't found the given one

=item B<--custom-message>

Specify a custom message of the alert. Only this message will be shown

=item B<--response-log-dir>

If set the a response log will be written to specified directory

=back

=cut
