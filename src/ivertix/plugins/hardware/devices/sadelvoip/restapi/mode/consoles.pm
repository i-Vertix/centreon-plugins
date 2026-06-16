#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::consoles;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf(" - state is '%s'", $self->{result_values}->{state});
}

sub prefix_console_output {
    my ($self, %options) = @_;

    return sprintf("'%s' [Operator: %s]", $options{instance_value}->{display}, $options{instance_value}->{operator});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'consoles',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_console_output',
            message_multiple => 'All consoles are ok',
            skipped_code     => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{consoles} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{state} eq "disconnected"',
            set              => {
                key_values                     =>
                    [
                        { name => 'state' },
                        { name => 'display' },
                        { name => 'operator' }
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

sub manage_selection {
    my ($self, %options) = @_;

    my $consoles = $options{custom}->request_api(endpoint => 'diagnostic/consoles', method => 'GET');

    foreach my $console (@{$consoles}) {
        next if is_excluded(
            $console->{id},
            $self->{option_results}->{include_id},
            $self->{option_results}->{exclude_id},
            output => $self->{output}
        );

        next if is_excluded(
            $console->{name},
            $self->{option_results}->{include_name},
            $self->{option_results}->{exclude_name},
            output => $self->{output}
        );

        $self->{consoles}->{$console->{id}} = {
            id       => $console->{id},
            display  => $console->{name},
            operator => $console->{operator},
            state    => $console->{state},
        };
    }

    if (scalar(keys %{$self->{consoles}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No console found with this id.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check console.

=over 8

=item B<--include-id>

Filter console by id (can be a regexp).

=item B<--exclude-id>

Exclude console by id (can be a regexp).

=item B<--include-name>

Filter console by name (can be a regexp).

=item B<--exclude-name>

Exclude console by name (can be a regexp).

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