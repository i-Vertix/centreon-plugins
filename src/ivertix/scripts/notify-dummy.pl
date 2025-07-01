#!/usr/bin/perl

use strict;
use warnings;
use POSIX;

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my $alert_type;
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
my $timeout;
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
    'alert-type:s'          => \$alert_type,
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

# put you code here

write_log($data);


exit($?);


__END__

=head1 NAME

perl notify-dummy.pl --alert-type=host --host-name=core-switch --host-state=DOWN --host-output='CRITICAL - 192.168.1.1: rta nan, lost 100%' --host-address=192.168.1.1 --log-file=/tmp/notif-dummy.log

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