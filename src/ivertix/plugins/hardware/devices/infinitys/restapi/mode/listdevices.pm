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
#

package ivertix::plugins::hardware::devices::infinitys::restapi::mode::listdevices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
        {
            'filter:s'   => { name => 'filter', default => 'name' },
            'device:s'   => { name => 'device' },
        });

    $self->{order} = [ 'name' ];
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{option_results}->{filter} = lc($self->{option_results}->{filter});
    if ($self->{option_results}->{filter} !~ /^(name|id)$/) {
        $self->{output}->add_option_msg(short_msg => "Unsupported --filter option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $temp_devices = $options{custom}->request_api(endpoint => '/device');
    $self->{devices} = [];

    foreach my $device (@{$temp_devices}) {
        if (defined($self->{option_results}->{device}) && $self->{option_results}->{device} ne '' &&
            $device->{$self->{option_results}->{filter}} !~ /$self->{option_results}->{device}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $device->{name} . "': no matching $self->{option_results}->{filter} filter.",
                debug    => 1);
            next;
        }

        push @{$self->{devices}}, $device;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{devices}}) {
        my $ip = defined($_->{ip}) ? $_->{ip} : '';
        my $description = defined($_->{description}) ? $_->{description} : '';
        my $status = $_->{isOnline} eq 1 ? 'online' : 'offline';

        $self->{output}->output_add(long_msg =>
            "[name = '" . $_->{name} . "'] [id = '" . $_->{id} . "'] [sn = '" . $_->{sn} . "'] [ip = '" . $ip . "'] [status = '" . $status . "'] [description = '" . $description . "']");
    }

    $self->{output}->output_add(severity => 'OK',
        short_msg                        => 'List devices:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'id', 'name', 'sn', 'ip', 'description' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{devices}}) {
        $self->{output}->add_disco_entry(
            id          => $_->{id},
            name        => $_->{name},
            sn          => $_->{sn},
            ip          => $_->{ip},
            description => $_->{description},
            status      => $_->{isOnline} eq 1 ? 'online' : 'offline',
        );
    }
}

1;

__END__

=head1 MODE

List devices.

=over 8

=item B<--filter>

Choose the property to filter the device (default: name) ('name', 'id').

=item B<--device>

Filter device (can be a regexp).

=back


=cut
    
