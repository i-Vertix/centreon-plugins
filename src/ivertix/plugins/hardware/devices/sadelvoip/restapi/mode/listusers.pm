#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::listusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'include-name:s'  => { name => 'include_name' },
                'exclude-name:s'  => { name => 'exclude_name' },
                'include-state:s' => { name => 'include_state' },
                'exclude-state:s' => { name => 'exclude_state' }
            }
    );

    return $self;
}

my @labels = ('id', 'name', 'description', 'state');

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $consoles = $options{custom}->request_api(endpoint => 'diagnostic/users', method => 'GET');

    my $results = {};
    foreach my $console (@{$consoles}) {
        next if is_excluded(
            $console->{name},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name},
            output => $self->{output}
        );

        next if is_excluded(
            $console->{state},
            $self->{option_results}->{include_state},
            $self->{option_results}->{exclude_state},
            output => $self->{output}
        );

        $results->{$console->{id}} = {
            id          => $console->{id},
            name        => $console->{name},
            description => $console->{description},
            state       => $console->{state}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach my $user (sort keys %$results) {
        $self->{output}->output_add(long_msg =>
            join('', map("[$_: " . $results->{$user}->{$_} . ']', @labels))
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List users'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ @labels ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(custom => $options{custom});
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(
            %{$results->{$_}}
        );
    }
}

1;

__END__

=head1 MODE

List users.

=over 8

=item B<--include-name>

Filter user by name (can be a regexp).

=item B<--exclude-name>

Exclude user by name (can be a regexp).

=item B<--include-state>

Filter user by state (can be a regexp).

=item B<--exclude-state>

Exclude user by state (can be a regexp).

=back

=cut