#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::zerto::zvm::restapi::mode::listvras;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_vra_status $map_alert_status);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my @labels = ('id', 'name', 'status', 'alert_status', 'group', 'ip_address', 'vra_version', 'host_version');

sub manage_selection {
    my ($self, %options) = @_;

    my $vras = $options{custom}->get_vras();

    my $results = [];
    foreach my $vra (@$vras) {
        my $id = $vra->{VraIdentifierStr} // $vra->{VraIdentifier} // '';
        my $name = $vra->{VraName} || $id;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        push @$results, {
            id           => $id,
            name         => $name,
            status       => enum_name(value => $vra->{Status}, map => $map_vra_status),
            alert_status => enum_name(value => $vra->{VraAlerts}->{VraAlertsStatus}, map => $map_alert_status),
            group        => $vra->{VraGroup} // '',
            ip_address   => $vra->{IpAddress} // '',
            vra_version  => $vra->{VraVersion} // '',
            host_version => $vra->{HostVersion} // ''
        };
    }

    return [ sort { $a->{name} cmp $b->{name} } @$results ];
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg =>
            join('', map('[' . $_ . ': ' . $entry->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List VRAs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $entry (@$results) {
        $self->{output}->add_disco_entry(%$entry);
    }
}

1;

__END__

=head1 MODE

List Zerto virtual replication appliances (VRAs).

=over 8

=item B<--include-name>

Filter VRAs by name (can be a regexp).

=item B<--exclude-name>

Exclude VRAs by name (can be a regexp).

=back

=cut
