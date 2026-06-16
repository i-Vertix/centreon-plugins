#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::users;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded is_not_empty);

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf("state: '%s'", $self->{result_values}->{state});
}

sub prefix_line_output {
    my ($self, %options) = @_;

    my $output = sprintf(
        "User '%s' ",
        $options{instance_value}->{display}
    );

    if(is_not_empty($options{instance_value}->{description})) {
        $output .= sprintf(" - description: '%s'", $options{instance_value}->{description});
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'users',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_line_output',
            message_multiple => 'All users are ok',
            skipped_code     => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{users} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{state} eq "disconnected"',
            set              => {
                key_values                     =>
                    [
                        { name => 'display' },
                        { name => 'state' },
                        { name => 'description' }
                    ],
                closure_custom_output          => $self->can('custom_state_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'include-id:s'   => { name => 'include_id' },
                'exclude-id:s'   => { name => 'exclude_id' },
                'include-name:s' => { name => 'include_name' },
                'exclude-name:s' => { name => 'exclude_name' }
            }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my %map_boolean = (
    0 => 'false',
    1 => 'true'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $users = $options{custom}->request_api(endpoint => 'diagnostic/users', method => 'GET');

    foreach my $user (@{$users}) {
        next if is_excluded(
            $user->{id},
            $self->{option_results}->{include_id},
            $self->{option_results}->{exclude_id},
            output => $self->{output}
        );

        next if is_excluded(
            $user->{name},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name},
            output => $self->{output}
        );

        $self->{users}->{$user->{id}} = {
            id          => $user->{id},
            display     => $user->{name},
            description => $user->{description},
            state       => $user->{state},
        };
    }

    if (scalar(keys %{$self->{users}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No user found with this id.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check user.

=over 8

=item B<--include-id>

Filter user by id (can be a regexp).

=item B<--exclude-id>

Exclude user by id (can be a regexp).

=item B<--include-name>

Filter user by name (can be a regexp).

=item B<--exclude-name>

Exclude user by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status. (Default: '')
Can used special variables like: %{state}, %{display}, %{operator}

=item B<--warning--status>

Set warning threshold for status (Default: '')
Can used special variables like: %{state}, %{display}, %{operator}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} eq "disconnected"').
Can used special variables like: %{state}, %{display}, %{operator}

=back

=cut