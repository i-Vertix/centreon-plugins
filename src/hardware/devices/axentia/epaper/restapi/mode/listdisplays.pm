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

package hardware::devices::axentia::epaper::restapi::mode::listdisplays;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 'display:s' => { name => 'display' } });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_status_code = {
    0 => 'ok', 1 => 'notice', 2 => 'error'
};

my $map_display_mode = {
    0 => 'not mounted',
    1 => 'operation',
    2 => 'operation not mounted on site',
    3 => 'operation demo/mobile',
    4 => 'service',
    5 => 'mounted'
};

my @labels = (
    'ibus_id',
    'stoppoint_id',
    'stoppoint_name',
    'product',
    'ip',
    'firmware',
    'platform',
    'display_mode',
    'display_status'
);

sub manage_selection {
    my ($self, %options) = @_;

    my $temp_display = $options{custom}->request_api(endpoint => '/Display/all/status');
    my $results = {};

    foreach my $display (@{$temp_display}) {
        if (defined($self->{option_results}->{display}) && $self->{option_results}->{display} ne '' &&
            $display->{ibusId} ne $self->{option_results}->{display}) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $display->{ibusId} . "': no matching display filter.",
                debug    => 1);
            next;
        }

        # there can be more than one stoppoint on a display. So we make a distinct of the stoppoint names
        my $stop_point_name = $display->{stopPointName};
        my @names = split /\s*,\s*/, $stop_point_name;
        my %seen;
        my @unique_name = grep {!$seen{lc $_}++} @names;

        $results->{ $display->{ibusId} } = {
            ibus_id        => $display->{ibusId},
            stoppoint_name => join(";", @unique_name),
            product        => $display->{product},
            ip             => defined($display->{ipAddress}) ? $display->{ipAddress} : "NA",
            firmware       => $display->{firmware},
            platform       => $display->{platform},
            display_mode   => defined($map_display_mode->{ $display->{displayMode} }) ?
                $map_display_mode->{ $display->{displayMode} } : 'NOT_DOCUMENTED',
            display_status => defined($map_status_code->{ $display->{displayStatus} }) ?
                $map_status_code->{ $display->{displayStatus} } : 'NOT_DOCUMENTED'
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $ibus_id (sort keys %$results) {
        my $display = $results->{$ibus_id};
        $self->{output}->output_add(
            long_msg =>
                sprintf("[ibus_id = %s] [stoppoint_name = %s] [product = %s] [ip = %s] [firmware = %s] [platform = %s] [display_mode = %s] [display_status = %s]",
                    $display->{ibus_id},
                    $display->{stoppoint_name},
                    $display->{product},
                    $display->{ip},
                    $display->{firmware},
                    $display->{platform},
                    $display->{display_mode},
                    $display->{display_status}
                )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'List devices:');
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
    foreach (sort keys %$results) {
        $self->{output}->add_disco_entry(%{$results->{$_}});
    }
}

1;

__END__

=head1 MODE

List displays.

=over 8

=item B<--display>

Filter displays by ibusId.

=back


=cut
    
