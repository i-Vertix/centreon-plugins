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

package apps::backup::zerto::zvm::restapi::mode::listdatastores;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);

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

my @labels = ('id', 'name', 'cluster', 'health_status', 'availability_status');

sub manage_selection {
    my ($self, %options) = @_;

    my $datastores = $options{custom}->get_datastores();

    my $results = [];
    foreach my $datastore (@$datastores) {
        my $id = $datastore->{DatastoreIdentifier} // '';
        my $name = $datastore->{DatastoreName} || $id;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        push @$results, {
            id                  => $id,
            name                => $name,
            cluster             => ref($datastore->{Config}->{OwningDatastoreCluster}) eq 'HASH'
                ? $datastore->{Config}->{OwningDatastoreCluster}->{DatastoreClusterName} // '' : '',
            health_status       => $datastore->{Health}->{Status} // '',
            availability_status => $datastore->{Stats}->{AvailabilityStatus} // ''
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

    $self->{output}->output_add(severity => 'OK', short_msg => 'List datastores:');
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

List the datastores seen by the Zerto Virtual Manager.

=over 8

=item B<--include-name>

Filter datastores by name (can be a regexp).

=item B<--exclude-name>

Exclude datastores by name (can be a regexp).

=back

=cut
