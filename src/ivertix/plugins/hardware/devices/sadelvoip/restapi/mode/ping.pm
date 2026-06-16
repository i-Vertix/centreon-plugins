#
# Copyright 2026 i-Vertix (http://i-vertix.com/)
#

package ivertix::plugins::hardware::devices::sadelvoip::restapi::mode::ping;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);

sub custom_connection_output {
    my ($self, %options) = @_;

    return sprintf(" - DB connection is '%s'", $self->{result_values}->{db_connection});
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return sprintf("Ping Timestamp: '%s'", $options{instance_value}->{timestamp});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'global',
            type             => COUNTER_TYPE_GLOBAL,
            cb_prefix_output => 'prefix_global_output',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{db_connection} eq "down"',
            set              => {
                key_values                     => [ { name => 'db_connection' } ],
                closure_custom_output          => $self->can('custom_connection_output'),
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

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $map_connection = {
    1 => 'up', 0 => 'down'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $data = $options{custom}->request_api(endpoint => 'ping', method => 'GET');

    $self->{global} = {
        timestamp     => $data->{timestamp},
        mac_address   => $data->{macAddress},
        db_connection => $map_connection->{$data->{dbConnection}},
    };
}

1;

__END__

=head1 MODE

Check DB connection.

=over 8

=item B<--unknown-status>

Set unknown threshold for status. (Default: '')
Can used special variables like: %{db_connection}

=item B<--warning--status>

Set warning threshold for status (Default: '')
Can used special variables like: %{db_connection}

=item B<--critical-status>

Set critical threshold for status (Default: '%{db_connection} eq "down"').
Can used special variables like: %{db_connection}

=back

=cut