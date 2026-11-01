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

package cloud::sangfor::scp::management::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw(floor);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(change_seconds is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit      => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{name},
        value     => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value     => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        'activated: %s, disabled: %s',
        $self->{result_values}->{activated},
        $self->{result_values}->{disabled}
    );
}

sub prefix_product_output {
    my ($self, %options) = @_;
    return "Product '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'products', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_product_output', message_multiple => 'All licenses are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{products} = [
        {
            label => 'status',
            type  => COUNTER_KIND_TEXT,
            set   => {
                key_values                     => [ { name => 'name' }, { name => 'activated' }, { name => 'disabled' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        map {
            my $kind = $_;
            { label => $kind . '-expires', nlabel => 'license.' . $kind . '.expires', set => {
                    key_values                     => [ { name => $kind . '_expires_seconds' }, { name => $kind . '_expires_human' }, { name => 'name' } ],
                    output_template                => $kind . ' expires in %s',
                    output_use                     => $kind . '_expires_human',
                    closure_custom_calc            => sub {
                        my ($self, %options) = @_;
                        $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
                        $self->{result_values}->{expires_seconds} = $options{new_datas}->{$self->{instance} . '_' . $kind . '_expires_seconds'};
                        $self->{result_values}->{$kind . '_expires_human'} = $options{new_datas}->{$self->{instance} . '_' . $kind . '_expires_human'};
                        return 0;
                    },
                    closure_custom_perfdata        => $self->can('custom_expires_perfdata'),
                    closure_custom_threshold_check => $self->can('custom_expires_threshold')
                }
            }
        } ('software', 'service')
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s'        => { name => 'include_name', default => '' },
        'exclude-name:s'        => { name => 'exclude_name', default => '' },
        'include-not-activated' => { name => 'include_not_activated' },
        'unit:s'                => { name => 'unit', default => 'd', is_in => [ keys %$unitdiv ] }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $summary = $options{custom}->get_licenses();

    $self->{products} = {};
    foreach my $product (@{ref($summary) eq 'HASH' ? ($summary->{products} // []) : []}) {
        next unless ref($product) eq 'HASH' && defined($product->{name});
        next if is_excluded($product->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if !$product->{activated} && !defined($self->{option_results}->{include_not_activated});

        my $entry = {
            name      => $product->{name},
            activated => $product->{activated} ? 'yes' : 'no',
            disabled  => $product->{disable} ? 'yes' : 'no'
        };
        foreach my $kind ('software', 'service') {
            my $time = $product->{$kind . '_time'};
            # a remaining time of -1 means that the license never expires
            next unless ref($time) eq 'HASH' && defined($time->{remain_timestamp}) && $time->{remain_timestamp} =~ /^\d+$/;
            $entry->{$kind . '_expires_seconds'} = $time->{remain_timestamp};
            $entry->{$kind . '_expires_human'} = $time->{remain_timestamp} > 0 ? change_seconds(value => $time->{remain_timestamp}) : '0s';
        }
        $self->{products}->{$product->{name}} = $entry;
    }

    $self->{output}->option_exit(short_msg => 'No license found.')
        unless %{$self->{products}};
}

1;

__END__

=head1 MODE

Check the licenses of the platform (software and service expiration of products and components).

=over 8

=item B<--include-name>

Filter products by name (can be a regexp).

=item B<--exclude-name>

Exclude products by name (can be a regexp).

=item B<--include-not-activated>

Also check the products that are not activated (skipped by default).

=item B<--unit>

Select the time unit for the expiration thresholds. May be C<s> for seconds, C<m> for minutes, C<h> for hours, C<d> for days, C<w> for weeks (default: C<d>).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{activated}>, C<%{disabled}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{name}>, C<%{activated}>, C<%{disabled}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{name}>, C<%{activated}>, C<%{disabled}>.

=item B<--warning-software-expires>

Threshold for the software license expiration (in the unit set by C<--unit>), for example C<30:> to be alerted when less than 30 days remain.

=item B<--critical-software-expires>

Threshold for the software license expiration (in the unit set by C<--unit>), for example C<30:> to be alerted when less than 30 days remain.

=item B<--warning-service-expires>

Threshold for the service expiration (in the unit set by C<--unit>), for example C<30:> to be alerted when less than 30 days remain.

=item B<--critical-service-expires>

Threshold for the service expiration (in the unit set by C<--unit>), for example C<30:> to be alerted when less than 30 days remain.

=back

=cut
