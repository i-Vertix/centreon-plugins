#!/usr/bin/perl

use strict;
use warnings;
use POSIX;
use JSON::PP;
use utf8;

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my $alert_type;
# “PROBLEM”, “RECOVERY”, “ACKNOWLEDGEMENT”, “FLAPPINGSTART”, “FLAPPINGSTOP”, “FLAPPINGDISABLED”, “DOWNTIMESTART”, “DOWNTIMEEND”, or “DOWNTIMECANCELLED”
my $notification_type;
my $host_name;
# UP, DOWN, UNREACHABLE
my $host_state;
my $host_output;
my $host_address;
my $host_notes;
my $service_description;
# OK, CRITICAL, WARNING, UNKNOWN
my $service_state;
my $service_output;
my $service_notes;
my $short_datetime;
my $link_url;
my $log_file;
my $api_url;
my $api_key;
my $connection_timeout = 5;
my $timeout = 10;
my $help;

sub write_log($) {
    my ($content) = @_;

    if (defined($log_file)) {
        eval {
            open(FILE, '>>', $log_file) or die $!;
            my $log = strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $content\n";
            print FILE "$log";
            close FILE;
        };
        if ($@) {
            print "Can't write to log file $log_file. Please check the access rights";
        }
    }
}

sub build_message {
    my $message = "";

    if ($alert_type eq 'host') {
        $message .= "host-name $host_name";
        $message .= ", host-state=$host_state" if defined($host_state);
        $message .= ", host-output=$host_output" if defined($host_output);
    } else {
        $message .= "host-name $host_name";
        $message .= ", service $service_description";
        $message .= ", service-state=$service_state" if defined($service_state);
        $message .= ", service-output=$service_output" if defined($service_output);
    }

    return $message;
}

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?'         => \$help,
    'api-url:s'             => \$api_url,
    'api-key:s'             => \$api_key,
    'timeout:s'             => \$timeout,
    'connection-timeout:s'  => \$connection_timeout,
    'alert-type:s'          => \$alert_type,
    'notification-type:s'   => \$notification_type,
    'host-name:s'           => \$host_name,
    'host-address:s'        => \$host_address,
    'host-state:s'          => \$host_state,
    'host-output:s'         => \$host_output,
    'host-notes:s'          => \$host_notes,
    'service-description:s' => \$service_description,
    'service-state:s'       => \$service_state,
    'service-output:s'      => \$service_output,
    'service-notes:s'       => \$service_notes,
    'short-datetime:s'      => \$short_datetime,
    'link-url:s'            => \$link_url,
    'log-file:s'            => \$log_file
) or pod2usage(3);

pod2usage(1) if defined $help;

if (!defined($alert_type) || !$alert_type) {
    print STDERR "Argument alert-type is mandatory\n";
    exit(3);
} elsif ($alert_type !~ /host|service/) {
    print STDERR "Argument must be host or service\n";
    exit(3);
}

if (!defined($host_name) || !$host_name) {
    print STDERR "Argument host-name is mandatory\n";
    exit(3);
}

if (!defined($host_address) || !$host_address) {
    print STDERR "Argument host-address is mandatory\n";
    exit(3);
}

my $data .= build_message();

## Remove all non literal because otherwise we have issues escaping them while composing curl string
my $escaped_host_output = $host_output;
$escaped_host_output =~ s/[^a-zA-Z0-9,-]/ /g;

my $escaped_service_output = undef;
if ($alert_type eq "service") {
    $escaped_service_output = $service_output;
    $escaped_service_output =~ s/[^a-zA-Z0-9,-]/ /g;
}

my $host_flapping_state_output;
if (defined($notification_type) && $notification_type =~ "^FLAPPING" && $alert_type eq "host") {
    if ($notification_type eq "FLAPPINGSTART") {
        $host_flapping_state_output = "Host started flapping, last recorded host state was: " . $host_state;
    } elsif ($notification_type eq "FLAPPINGSTOP") {
        $host_flapping_state_output = "Host stopped flapping, current host state is: " . $host_state;
    } elsif ($notification_type eq "FLAPPINGDISABLED") {
        $host_flapping_state_output .= " stopped flapping while flapping detection has been disabled";
    } else {
        $host_flapping_state_output .= " is in unknown flapping status $notification_type";
    }
}

my $service_flapping_state_output;
if (defined($notification_type) && $notification_type =~ "^FLAPPING" && $alert_type eq "service") {
    if ($notification_type eq "FLAPPINGSTART") {
        $service_flapping_state_output = "Service with name: " . $service_description . " started flapping, last recorded service state was: " . $service_state;
    } elsif ($notification_type eq "FLAPPINGSTOP") {
        $service_flapping_state_output = "Service with name: " . $service_description . " stopped flapping, current state is: " . $service_state;
    } elsif ($notification_type eq "FLAPPINGDISABLED") {
        $service_flapping_state_output .= " stopped flapping while flapping detection has been disabled";
    } else {
        $service_flapping_state_output .= " is in unknown flapping status $notification_type";
    }
}

my $monitor_up_output;
if ($alert_type eq "host") {
    $monitor_up_output = defined($host_flapping_state_output) && $host_state eq "UP" ? $host_flapping_state_output :
        $host_state eq "UP" ? "UP" : undef;
} else {
    $monitor_up_output = defined($service_flapping_state_output) && $service_state eq "OK" ?
        $service_flapping_state_output :
        $service_state eq "OK" ? "Service: " . $service_description . " - state is OK" : undef;
}

my $monitor_down_output;
if ($alert_type eq "host") {
    $monitor_down_output = defined($host_flapping_state_output) && $host_state ne "UP" ?
        $host_flapping_state_output :
        $host_state ne "UP" ? $host_state : undef;
} else {
    $monitor_down_output = defined($service_flapping_state_output) && $service_state ne "OK" ?
        $service_flapping_state_output :
        $service_state ne "OK" ?
            "Service: " . $service_description . " - state is " . $service_state :
            undef;
}

my $req_body = {
    device_name   =>
        $host_name,
    ip_address    =>
        $host_address,
    monitors_up   =>
        defined($monitor_up_output) ? [ $monitor_up_output ] : [],
    monitors_down =>
        defined($monitor_down_output) ? [ $monitor_down_output ] : [],
    data          =>
        { "data",
            ($alert_type eq "host") ? $escaped_host_output : ($alert_type eq "service") ? $escaped_service_output : [] }
};

## Encode request body to json
my $json_encoder = JSON::PP->new->utf8;
my $json_req_body = $json_encoder->encode($req_body);

## Compose curl command string
my $curl_command = qq(curl --verbose --header "Content-Type: application/json" --header "Authorization:Token $api_key" --data '$json_req_body' $api_url -k -m $timeout --connect-timeout $connection_timeout --noproxy '*');
write_log($curl_command);

# Execute curl command
my $r = `$curl_command`;

write_log($data);

exit($?);


__END__

=head1 NAME

perl notify-dummy.pl --alert-type=host --host-name=core-switch --host-state=DOWN --notification-type=PROBLEM --host-output='CRITICAL - 192.168.1.1: rta nan, lost 100%' --host-address=192.168.1.1 --log-file=/tmp/notif-dummy.log

=head1 SYNOPSIS

notify-dummy.pl [options]

=head1 OPTIONS

=over 3

=item B<--api-url>

complete api url to use for the notification request

=item B<--api-key>

api key or token used for auth

=item B<--port>

port used for api request. Default 443

=item B<--proto>

protocol used for api request. Default 'https'

=item B<--timeout>

timeout for api request

=item B<--alert-type>

Type of alert. Can be 'host' or 'alert'

=item B<--host-name>

name of the host

=item B<--host-addr>

IP or FQD of the host

=item B<--host-state>

actual state of the host. (UP, DOWN, UNREACHABLE)

=item B<--host-output>

actual output of the state of the host.

=item B<--host-notes>

notes of the host

=item B<--service-description>

description of the service

=item B<--service-state>

actual state of the host. (OK, WARNING, CRITICAL, UNKNOWN)

=item B<--service-output>

actual output of the state of the service.

=item B<--service-notes>

notes of the service

=item B<--short-datetime>

time stamp in short datetime format

=item B<--link-url>

configured link. can be for example a google maps link or a link to the monitored device

=item B<--log-file>

writes some stuff to the log-file if param is set

=back

=cut
