#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use Scalar::Util qw(looks_like_number);

my $help;
my $meraki_fqdn;
my $meraki_token;
my $ivertix_plugins_dir;
my $timeout;

## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?'        => \$help,
    'meraki-fqdn=s'        => \$meraki_fqdn,
    'meraki-token=s'       => \$meraki_token,
    'ivertix-plugin-dir=s' => \$ivertix_plugins_dir,
    'timeout=s'            => \$timeout,
) or pod2usage(3);

pod2usage(1) if defined $help;

pod2usage({ -message => "UNKNOWN: Argument 'meraki-fqdn' is mandatory",
    -exitval         => 3,
    -verbose         => 1,
    -output          => \*STDOUT }) if not defined $meraki_fqdn;

pod2usage({ -message => "UNKNOWN: Argument 'meraki-token' is mandatory",
    -exitval         => 3,
    -verbose         => 1,
    -output          => \*STDOUT }) if not defined $meraki_token;

pod2usage({ -message => "UNKNOWN: Argument 'ivertix-plugin-dir' is mandatory",
    -exitval         => 3,
    -verbose         => 1,
    -output          => \*STDOUT }) if not defined $ivertix_plugins_dir;

pod2usage({ -message => "UNKNOWN: Argument 'timeout' is mandatory",
    -exitval         => 3,
    -verbose         => 1,
    -output          => \*STDOUT }) if not defined $timeout;

if (!-e $ivertix_plugins_dir) {
    print "UNKNOWN: ivertix-plugin-dir $ivertix_plugins_dir doesn't exist";
    exit(3);
}

if (!looks_like_number($timeout)) {
    print "UNKNOWN: timeout must be a number";
    exit(3);
}

if ($meraki_token =~ /[ ]/ || $meraki_token =~ /[&]/) {
    print "UNKNOWN: token not in correct format";
    exit(3);
}

my $cmd = "perl $ivertix_plugins_dir/network-cisco-meraki-cloudcontroller-restapi.pl --hostname=$meraki_fqdn --api-token=\'$meraki_token\' --plugin=network::cisco::meraki::cloudcontroller::restapi::plugin --mode=cache --timeout=$timeout --ignore-orgs-api-disabled --ignore-permission-errors";
system("$cmd &>/dev/null &");
print "OK: Cache command sent"

__END__

=head1 NAME

ivertix-network-cisco-meraki-generate-cache.pl - creates the meraki cache for the given token using the etwork-cisco-meraki-cloudcontroller-restapi plugin

=head1 SYNOPSIS

generate_meraki_cache.pl [options]

=head1 OPTIONS

=over 3

=item B<--meraki-fqdn>

FQDN for meraki API

=item B<--meraki-token>

user token

=item B<--ivertix-plugin-dir>

directory containing the network-cisco-meraki-cloudcontroller-restapi plugin

=item B<--timeout>

network-cisco-meraki-cloudcontroller-restapi plugin timeout

=item B<--help>

Print a brief help message and exits.

=back

=head1 DESCRIPTION

B<ivertix-network-cisco-meraki-generate-cache.pl > .

=cut
