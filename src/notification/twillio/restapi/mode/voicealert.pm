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

package notification::twillio::restapi::mode::voicealert;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON;
use POSIX;
use URI::Encode;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "to:s"                  =>
            { name => 'to' },
        "from:s"                =>
            { name => 'from' },
        "message-pattern:s"     =>
            { name => 'message_pattern' },
        "say-settings:s"      =>
            { name => 'say_settings', default => 'voice=alice#language=it-IT#strength=x-weak#time=100ms' },
        "host-name:s"          =>
            { name => 'host_name' },
        "host-state:s"          =>
            { name => 'host_state' },
        "service-description:s" =>
            { name => 'service_description' },
        "service-state:s"       =>
            { name => 'service_state' },
        "short-datetime:s"      =>
            { name => 'short_datetime' },
        "response-log-dir:s"    =>
            { name => 'response_log_dir' }
    });

    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{response_log_dir})) {
        if (!-e $self->{option_results}->{response_log_dir} && !mkdir $self->{option_results}->{response_log_dir}) {
            $self->{output}->add_option_msg(short_msg => "Please specify a valid response_log_dir");
            $self->{output}->option_exit();
        }
    }

    if ($self->{option_results}->{to} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --to option.");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{from} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --from option.");
        $self->{output}->option_exit();
    }

    my ($voice,
        $language,
        $strength,
        $time) = $self->{option_results}->{say_settings} =~ /voice=(.*?)#language=(.*?)#strength=(.*?)#time=(.*?)$/;

    if ((!defined($voice) || $voice eq '') ||
        (!defined($language) || $language eq '') ||
        (!defined($strength) || $strength eq '') ||
        (!defined($time) || $time eq '')) {
        $self->{output}->add_option_msg(short_msg =>
            "Need to specify all --say-settings options pipe separated. Like default 'voice=alice#language=it-IT#strength=x-weak#time=100ms'.");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{message_pattern} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --message-pattern option.");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{message_pattern})) {
        $self->{option_results}->{message_pattern} =~ s/%\{(.*?)\}/$self->{option_results}->{$1}/eg;
    }

    $self->{option_results}->{twiml} = "<Response><Say voice=\'$voice\' language=\'$language\'><break strength=\'$strength\' time=\'$time\'/>" .
        "$self->{option_results}->{message_pattern}</Say></Response>";
}

sub set_payload($$) {
    my $self = shift;

    my $post_param = [
        'To=' . $self->{option_results}->{to},
        'From=' . $self->{option_results}->{from},
        'Twiml=' . $self->{option_results}->{twiml}
    ];
    return ($post_param);
}

sub write_log($) {
    my $self = shift;
    my ($content) = @_;

    if (defined($self->{option_results}->{response_log_dir})) {
        my $log_file = "$self->{option_results}->{response_log_dir}/twillio-notification.log";

        open FILE, '>>', $log_file;
        my $log = strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $content\n";
        print FILE "$log";
        close FILE;
    }
}

sub run {
    my ($self, %options) = @_;

    my $post_param = $self->set_payload();
    $self->write_log("[INFO] new voice alert: " . join(', ', @{$post_param}));

    my ($response, $http_status_code, $api_response) = $options{custom}->request(
        method     => 'POST',
        post_param => $post_param,
        json       => "Calls.json");

    if ($response == 1) {
        my $msg = "";
        if ($http_status_code >= 400) {
            $msg = "[ERROR] Could not send voice alert. HTTP Status: $api_response->{status}, Error code: $api_response->{code} Error message: $api_response->{message}";
            $self->{output}->add_option_msg(short_msg => $msg);
            $self->write_log($msg);
            $self->{output}->exit();
        }

        $msg = "[INFO] HTTP Status: $http_status_code, Voice status: $api_response->{status}, sid: $api_response->{sid}";
        $self->write_log($msg);

        $self->{output}->output_add(short_msg => $msg);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);

    } else {
        $self->{output}->output_add(long_msg => $@, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->write_log("[ERROR] could not send voice alert. Cannot decode json response. Details: $@");
    }

    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Send an voice alert via twillio

Example
centreon_plugins.pl --plugin=ivertix::plugins::notification::twillio::restapi::plugin --mode=voice-alert --api=api.twilio.com --account-sid=123456 --auth-token=123456 --say-settings='voice=alice#language=it-IT#strength=x-weak#time=100ms' --message-pattern='Alarm:Host %{host_name} %{host_state} since %{short_datetime}' --host-name=host123 --host-state=DOWN --short-datetime='01.01.2024 01:00:00' --to='<phonenumber>' --from='<phonenumber>'

=over 8

=item B<--to>

Specify the phone number of the receiver of the voice call

=item B<--from>

Specify the phone number of the caller (twillio account)

=item B<--ay-settings>

Set of settings for the <say /> xml part. Please see the twillio documentation for the values. At the moment only voice,language,strength e time are supported.
(Default: 'voice=alice#language=it-IT#strength=x-weak#time=100ms')


=item B<--message-pattern>

Message pattern used in the speach of the call. Can contain text and the variables %{host_name}, %{host_state}, %{service_description}, %{service_state}, %{short_datetime}.
This variables will be replaced with the corresponding options --host-name, --host-state, --service-description, --service-state and --short-datetime

=item B<--host-name>

Hostname of the affected host or service problem

=item B<--host-state>

State of the host

=item B<--service-description>

Service description of the affected service problem

=item B<--service-state>

State of the service

=item B<--short-datetime>

DateTime when the problem occured

=item B<--response-log-dir>

If set the a response log will be written to specified directory

=back

=cut
