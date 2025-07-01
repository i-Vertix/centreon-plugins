package ivertix::plugins::network::portstatus::snmp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    %{$self->{modes}} = (
        'set-portstatus'  => 'ivertix::plugins::network::portstatus::snmp::mode::setportstatus',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

yuhuuu

=cut
