#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'consoles'      => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::consoles',
        'lines'         => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::lines',
        'list-consoles' => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::listconsoles',
        'list-lines'    => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::listlines',
        'list-users'    => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::listusers',
        'ping'          => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::ping',
        'users'         => 'ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::users'
    };

    $self->{custom_modes}->{api} = 'ivertix::plugins::hardware::devices::sadelvoip::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check C<SadelVoip> through REST API.

=cut
