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

package cloud::sangfor::scp::management::mode::listresources;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);
use cloud::sangfor::scp::management::mode::resources qw(get_resources %resource_labels);

# base class of the list modes: the subclasses set 'resource_type' and 'resource_title'
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

sub manage_selection {
    my ($self, %options) = @_;

    return [
        grep { !is_excluded($_->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output}) }
            @{get_resources(custom => $options{custom}, type => $self->{resource_type})}
    ];
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $entry (@$results) {
        $self->{output}->output_add(long_msg => join('', map { '[' . $_ . ': ' . $entry->{$_} . ']' } @{$resource_labels{$self->{resource_type}}}));
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List ' . $self->{resource_title} . ':');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    $self->{output}->add_disco_format(elements => $resource_labels{$self->{resource_type}});
}

sub disco_show {
    my ($self, %options) = @_;

    foreach my $entry (@{$self->manage_selection(custom => $options{custom})}) {
        $self->{output}->add_disco_entry(%$entry);
    }
}

1;

__END__

=head1 MODE

Base class of the list modes.

=cut
