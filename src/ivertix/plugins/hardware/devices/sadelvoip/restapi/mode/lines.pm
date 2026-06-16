#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::lines;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw/is_excluded/;

sub custom_state_output {
    my ($self, %options) = @_;

    return sprintf(" - reachable: '%s'", $self->{result_values}->{reachable});
}

sub prefix_line_output {
    my ($self, %options) = @_;

    return sprintf(
        "Line '%s' [Operator: %s] - busy: '%s' SIM: %s",
        $options{instance_value}->{display},
        $options{instance_value}->{operator},
        $options{instance_value}->{busy},
        $options{instance_value}->{simnum}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'lines',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_line_output',
            message_multiple => 'All lines are ok',
            skipped_code     => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{lines} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{reachable} eq "false"',
            set              => {
                key_values                     =>
                    [
                        { name => 'reachable' },
                        { name => 'display' },
                        { name => 'operator' },
                        { name => 'simnum' },
                        { name => 'busy' }
                    ],
                closure_custom_output          => $self->can('custom_state_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'bit-error-rate', nlabel => 'line.bit.error.rate', display_ok => 0, set => {
            key_values          =>
                [ { name => 'ber' }, { name => 'display' } ],
            output_template     => 'bit error rate: %d',
            output_change_bytes => 1,
            perfdatas           =>
                [
                    {
                        template             => '%d',
                        min                  => 0,
                        unit                 => '',
                        label_extra_instance => 1,
                        instance_use         => 'display'
                    }
                ]
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'include-line-id:s'   => { name => 'include_line_id' },
                'exclude-line-id:s'   => { name => 'exclude_line_id' },
                'include-line-type:s' => { name => 'include_line_type' },
                'exclude-line-type:s' => { name => 'exclude_line_type' }
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

    my $data = $options{custom}->request_api(endpoint => 'diagnostic/lines', method => 'GET');
    my @lines = (
        $data->{modem1},
        $data->{modem2},
        $data->{modem3},
        $data->{modem4},
    );

    foreach my $line (@lines) {
        next if is_excluded(
            $line->{src}->{line_id},
            $self->{option_results}->{include_line_id},
            $self->{option_results}->{exclude_line_id},
            output => $self->{output}
        );

        next if is_excluded(
            $line->{src}->{line_type},
            $self->{option_results}->{include_line_type},
            $self->{option_results}->{exclude_line_type},
            output => $self->{output}
        );

        $self->{lines}->{$line->{src}->{line_id}} = {
            line_id   => $line->{src}->{line_id},
            display   => $line->{src}->{line_id},
            operator  => $line->{diagnostic}->{operator},
            reachable => $map_boolean{$line->{diagnostic}->{reachable}},
            simnum    => $line->{diagnostic}->{simnum},
            busy      => $map_boolean{$line->{diagnostic}->{busy}},
            ber       => $line->{diagnostic}->{ber},
        };
    }

    if (scalar(keys %{$self->{lines}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No line found with this id.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check line.

=over 8

=item B<--include-line-id>

Filter line by id (can be a regexp).

=item B<--exclude-line-id>

Exclude line by id (can be a regexp).

=item B<--include-line-type>

Filter line by type (can be a regexp).

=item B<--exclude-line-type>

Exclude line by type (can be a regexp).

=item B<--warning-bit-error-rate>

Warning thresholds.

=item B<--critical-bit-error-rate>

Critical thresholds.

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