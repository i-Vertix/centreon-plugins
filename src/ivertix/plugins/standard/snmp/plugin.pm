#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::standard::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $self->{modes} = {
        'arp'             => 'snmp_standard::mode::arp',
        'cpu'             => 'snmp_standard::mode::cpu',
        'cpu-detailed'    => 'snmp_standard::mode::cpudetailed',
        'diskio'          => 'snmp_standard::mode::diskio',
        'disk-usage'      => 'snmp_standard::mode::diskusage',
        'entity'          => 'snmp_standard::mode::entity',
        'inodes'          => 'snmp_standard::mode::inodes',
        'interfaces'      => 'snmp_standard::mode::interfaces',
        'load'            => 'snmp_standard::mode::loadaverage',
        'list-diskio'     => 'snmp_standard::mode::listdiskio',
        'list-diskspath'  => 'snmp_standard::mode::listdiskspath',
        'list-interfaces' => 'snmp_standard::mode::listinterfaces',
        'list-processes'  => 'snmp_standard::mode::listprocesses',
        'list-storages'   => 'snmp_standard::mode::liststorages',
        'memory'          => 'snmp_standard::mode::memory',
        'processcount'    => 'snmp_standard::mode::processcount',
        'storage'         => 'snmp_standard::mode::storage',
        'swap'            => 'snmp_standard::mode::swap',
        'time'            => 'snmp_standard::mode::ntp',
        'tcpcon'          => 'snmp_standard::mode::tcpcon',
        'udpcon'          => 'snmp_standard::mode::udpcon',
        'uptime'          => 'snmp_standard::mode::uptime',
    };

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

i-Vertix standard snmp plugin.

=cut
