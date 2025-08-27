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

package hardware::devices::axentia::epaper::restapi::mode::operationaldisplaystatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'ok', nlabel => 'displays.operation.ok.count', display_ok => 1, set => {
            key_values            => [ { name => 'ok' }, { name => 'operation' }, { name => 'ok_prct' } ],
            closure_custom_output => $self->can('custom_ok_output'),
            perfdatas             => [
                { template => '%s', min => 0, max => 'operation' }
            ]
        }
        },
        { label => 'ok-prct', nlabel => 'displays.operation.ok.percentage', display_ok => 0, set => {
            key_values            => [ { name => 'ok_prct' }, { name => 'ok' }, { name => 'operation' } ],
            closure_custom_output => $self->can('custom_ok_output_prct'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        },
        { label => 'error', nlabel => 'displays.operation.error.count', display_ok => 0, set => {
            key_values            => [ { name => 'error' }, { name => 'operation' }, { name => 'error_prct' } ],
            closure_custom_output => $self->can('custom_error_output'),
            perfdatas             => [
                { template => '%s', min => 0, max => 'operation' }
            ]
        }
        },
        { label => 'error-prct', nlabel => 'displays.operation.error.percentage', display_ok => 0, set => {
            key_values            => [ { name => 'error_prct' }, { name => 'error' }, { name => 'operation' } ],
            closure_custom_output => $self->can('custom_error_output_prct'),
            perfdatas             => [
                { template => '%.2f', unit => '%', min => 0, max => 100 }
            ]
        }
        },
        { label => 'notice', nlabel => 'displays.operation.notice.count', display_ok => 0, set => {
            key_values            =>
                [ { name => 'notice' }, { name => 'operation' }, { name => 'notice_prct' } ],
            closure_custom_output =>
                $self->can('custom_notice_output'),
            perfdatas             =>
                [
                    { template => '%s', min => 0, max => 'operation' }
                ]
        }
        },
        { label => 'notice-prct', nlabel => 'displays.operation.notice.percentage', display_ok => 0, set => {
            key_values            =>
                [ { name => 'notice_prct' }, { name => 'notice' }, { name => 'operation' } ],
            closure_custom_output =>
                $self->can('custom_notice_output_prct'),
            perfdatas             =>
                [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
        }
        }
    ];
}

sub custom_ok_output_prct {
    my ($self, %options) = @_;

    return sprintf(
        'displays ok %.2f%% (%s on %s in operation)',
        $self->{result_values}->{ok_prct},
        $self->{result_values}->{ok},
        $self->{result_values}->{operation},
    );
}

sub custom_error_output_prct {
    my ($self, %options) = @_;

    return sprintf(
        'displays error %.2f%% (%s on %s in operation)',
        $self->{result_values}->{error_prct},
        $self->{result_values}->{error},
        $self->{result_values}->{operation},
    );
}

sub custom_ok_output {
    my ($self, %options) = @_;

    return '' if $self->{result_values}->{operation} == 1 &&
        (!defined($self->{option_results}->{display}) ||
            $self->{option_results}->{display} eq '');

    return sprintf(
        'displays ok %s on %s in operation (%.2f%%)',
        $self->{result_values}->{ok},
        $self->{result_values}->{operation},
        $self->{result_values}->{ok_prct},
    );
}

sub custom_error_output {
    my ($self, %options) = @_;

    return sprintf(
        'displays error %s on %s in operation (%.2f%%)',
        $self->{result_values}->{error},
        $self->{result_values}->{operation},
        $self->{result_values}->{error_prct}
    );
}

sub custom_notice_output {
    my ($self, %options) = @_;

    return sprintf(
        'displays notice %s on %s in operation (%.2f%%)',
        $self->{result_values}->{notice},
        $self->{result_values}->{operation},
        $self->{result_values}->{notice_prct}
    );
}

sub custom_notice_output_prct {
    my ($self, %options) = @_;

    return sprintf(
        'displays notice %.2f%% (%s on %s in operation)',
        $self->{result_values}->{notice_prct},
        $self->{result_values}->{notice},
        $self->{result_values}->{operation},
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $counts = $options{custom}->request_api(endpoint => '/Supervision/displays/status');

    $self->{display} = {};
    $self->{global} = {
        operation => $counts->{inOperation},
        ok        => $counts->{ok},
        notice    => $counts->{warning},
        error     => $counts->{error}
    };

    if ($self->{global}->{operation} > 0) {
        $self->{global}->{ok_prct} = $self->{global}->{ok} * 100 / $self->{global}->{operation};
        $self->{global}->{error_prct} = $self->{global}->{error} * 100 / $self->{global}->{operation};
        $self->{global}->{notice_prct} = $self->{global}->{notice} * 100 / $self->{global}->{operation};
    }
}

1;

__END__

=head1 MODE

Check display health.

=over 8

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'ok', 'ok-prct' (%), 'error', 'error-prct' (%), 'notice', 'notice-prct' (%)

=back

=cut
