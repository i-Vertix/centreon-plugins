#!/usr/bin/perl

use strict;
use warnings;
use POSIX;

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

my $plugin;
my $plugin_path;
my $mode;
my $event_mode;
my $key_text;
my $event_id;
my $fallback_key_text;
my $fallback_event_id;
my $alert_type;
my $host_name;
my $host_state;
my $host_output;
my $host_notes;
my $service_description;
my $service_state;
my $service_output;
my $service_notes;
my $short_datetime;
my $link_url;
my $custom_message;
my $response_log_dir;
my $api_path;
my $api_key;
my $email;
my $password;
my $hostname;
my $port;
my $proto;
my $timeout;
my $unknown_http_status;
my $warning_http_status;
my $critical_http_status;
my $sguard_active;

my $log_filename = "sguard-sak-plugin.log";

sub write_log($) {
    my ($content) = @_;

    if (defined($response_log_dir)) {
        my $log_file = "$response_log_dir/$log_filename";

        eval {
            open (FILE, '>>', $log_file) or die $!;
            my $log = strftime('%Y-%m-%d %H:%M:%S', localtime) . " - $content\n";
            print $log;
            print FILE "$log";
            close FILE;
        };
        if ($@) {
            print "Can't write to log file $response_log_dir/$log_filename. Please check the access rights";
        }
    }
}

sub build_message {
    my $message = "";

    if (!defined($host_name) || !$host_name) {
        $host_name = "unknown";
    }

    if ($alert_type eq 'custom') {
        $message .= defined($custom_message) && $custom_message ? $custom_message : "";
    } elsif ($alert_type eq 'host') {
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

GetOptions('plugin:s'        => \$plugin,
    'plugin-path:s'          => \$plugin_path,
    'mode:s'                 => \$mode,
    'api-path:s'             => \$api_path,
    'api-key:s'              => \$api_key,
    'email:s'                => \$email,
    'password:s'             => \$password,
    'hostname:s'             => \$hostname,
    'port:s'                 => \$port,
    'proto:s'                => \$proto,
    'timeout:s'              => \$timeout,
    'unknown-http-status:s'  => \$unknown_http_status,
    'warning-http-status:s'  => \$warning_http_status,
    'critical-http-status:s' => \$critical_http_status,
    'event-mode:s'           => \$event_mode,
    'key-text:s'             => \$key_text,
    'event-id:s'             => \$event_id,
    'fallback-key-text:s'    => \$fallback_key_text,
    'fallback-event-id:s'    => \$fallback_event_id,
    'alert-type:s'           => \$alert_type,
    'host-name:s'            => \$host_name,
    'host-state:s'           => \$host_state,
    'host-output:s'          => \$host_output,
    'host-notes:s'           => \$host_notes,
    'service-description:s'  => \$service_description,
    'service-state:s'        => \$service_state,
    'service-output:s'       => \$service_output,
    'service-notes:s'        => \$service_notes,
    'short-datetime:s'       => \$short_datetime,
    'link-url:s'             => \$link_url,
    'custom-message:s'       => \$custom_message,
    'response-log-dir:s'     => \$response_log_dir,
    'sguard-active:s'        => \$sguard_active
) or pod2usage(3);

if (!defined($plugin) || !$plugin) {
    write_log("Argument plugin is mandatory");
    exit(3);
}

if (!defined($alert_type) || !$alert_type) {
    write_log("Argument alert-type is mandatory");
    exit(3);
}

if (!defined($sguard_active) || $sguard_active ne 'true') {
    print "OK: Skip notification";

    my $message = "Skip notification of type $alert_type: ";
    $message .= build_message();
    write_log($message);

    exit(1);
}

my $cmd = "perl $plugin_path --plugin=$plugin";

$cmd .= " --mode='$mode'" if defined($mode);
$cmd .= " --api-path='$api_path'" if defined($api_path);
$cmd .= " --api-key='$api_key'" if defined($api_key);
$cmd .= " --email='$email'" if defined($email);
$cmd .= " --password='$password'" if defined($password);
$cmd .= " --hostname='$hostname'" if defined($hostname);
$cmd .= " --port='$port'" if defined($port);
$cmd .= " --proto='$proto'" if defined($proto);
$cmd .= " --timeout='$timeout'" if defined($timeout);
$cmd .= " --unknown-http-status='$unknown_http_status'" if defined($unknown_http_status);
$cmd .= " --warning-http-status='$warning_http_status'" if defined($warning_http_status);
$cmd .= " --critical-http-status='$critical_http_status'" if defined($critical_http_status);

$cmd .= " --event-mode='$event_mode'" if defined($event_mode);
$cmd .= " --key-text='$key_text'" if defined($key_text);
$cmd .= " --event-id='$event_id'" if defined($event_id);
$cmd .= " --fallback-key-text='$fallback_key_text'" if defined($fallback_key_text);
$cmd .= " --fallback-event-id='$fallback_event_id'" if defined($fallback_event_id);
$cmd .= " --alert-type='$alert_type'" if defined($alert_type);
$cmd .= " --host-name='$host_name'" if defined($host_name);
$cmd .= " --host-state='$host_state'" if defined($host_state);
$cmd .= " --host-output='$host_output'" if defined($host_output);
$cmd .= " --host-notes='$host_notes'" if defined($host_notes);
$cmd .= " --service-description='$service_description'" if defined($service_description);
$cmd .= " --service-state='$service_state'" if defined($service_state);
$cmd .= " --service-output='$service_output'" if defined($service_output);
$cmd .= " --service-notes='$service_notes'" if defined($service_notes);
$cmd .= " --short-datetime='$short_datetime'" if defined($short_datetime);
$cmd .= " --custom-message='$custom_message'" if defined($custom_message);
$cmd .= " --response-log-dir='$response_log_dir'" if defined($response_log_dir);
$cmd .= " --link-url='$link_url'" if defined($link_url);

my $message = "Calling sguard plugin for alert of type $alert_type: ";
$message .= build_message();
write_log($message);

my $output = `$cmd`;
write_log($output);

exit($?);