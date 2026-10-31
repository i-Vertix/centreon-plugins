#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::backup::zerto::zic::restapi::mode::listmemberaccounts;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-description:s' => { name => 'include_description', default => '' },
        'exclude-description:s' => { name => 'exclude_description', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my @labels = (
    'id',
    'description',
    'status'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $accounts = $options{custom}->get_member_accounts();

    my $results = [];
    foreach my $account (@$accounts) {
        my $description = $account->{description} // '';

        next if is_excluded($description, $self->{option_results}->{include_description}, $self->{option_results}->{exclude_description}, output => $self->{output});

        push @$results, {
            id          => ref($account->{accountId}) eq 'HASH' ? $account->{accountId}->{id} : $account->{accountId},
            description => $description,
            status      => $account->{status} // ''
        };
    }

    return [ sort { $a->{id} cmp $b->{id} } @$results ];
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg =>
            join('', map('[' . $_ . ': ' . $entry->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List member accounts:');
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

List Zerto In-Cloud AWS member accounts.

=over 8

=item B<--include-description>

Filter member accounts by description (can be a regexp).

=item B<--exclude-description>

Exclude member accounts by description (can be a regexp).

=back

=cut
