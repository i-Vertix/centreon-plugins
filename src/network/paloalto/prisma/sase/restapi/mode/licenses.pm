#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::paloalto::prisma::sase::restapi::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    if ($self->{result_values}->{has_expiration_date} eq 'true') {
        $self->{output}->perfdata_add(
            nlabel    => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
            unit      => $self->{instance_mode}->{option_results}->{unit},
            instances => $self->{result_values}->{name},
            value     => floor($self->{result_values}->{expires_seconds}
                / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
            warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min       => 0
        );
    }
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    if ($self->{result_values}->{has_expiration_date} eq 'true') {
        return $self->{perfdata}->threshold_check(
            value     =>
                floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
            threshold =>
                [
                    { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                    { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
                    { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
                ]
        );
    }
}

sub custom_license_output {
    my ($self, %options) = @_;

    if ($self->{result_values}->{has_expiration_date} eq 'true') {
        return sprintf("expires in %s", $self->{result_values}->{expires_human});
    } else {
        return "is unlimited";
    }
}

sub prefix_license_edition_output {
    my ($self, %options) = @_;

    return sprintf("License edition '%s' ", $options{instance_value}->{name});
}

sub prefix_license_quota_output {
    my ($self, %options) = @_;

    return sprintf("License quota '%s' ", $options{instance_value}->{name});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'license_editions',
            type             => 1,
            cb_prefix_output => 'prefix_license_edition_output',
            message_multiple => 'All license editions are ok',
            skipped_code     => { -10 => 1 }
        },
        {
            name             => 'license_quotas',
            type             => 1,
            cb_prefix_output => 'prefix_license_quota_output',
            message_multiple => 'All license quotas are ok',
            skipped_code     => { -10 => 1 }
        },
    ];

    $self->{maps_counters}->{license_editions} = [
        {
            label  => 'edition-expires',
            nlabel => 'license.edition.expires',
            set    => {
                key_values                     =>
                    [
                        { name => 'expires_seconds' },
                        { name => 'expires_human' },
                        { name => 'name' },
                        { name => 'has_expiration_date' }
                    ],
                closure_custom_output          => $self->can('custom_license_output'),
                closure_custom_perfdata        => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];

    $self->{maps_counters}->{license_quotas} = [
        {
            label  => 'quota-expires',
            nlabel => 'license.quota.expires',
            set    => {
                key_values                     =>
                    [
                        { name => 'expires_seconds' },
                        { name => 'expires_human' },
                        { name => 'name' },
                        { name => 'has_expiration_date' }
                    ],
                closure_custom_output          => $self->can('custom_license_output'),
                closure_custom_perfdata        => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unit:s'        => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub add_license_edition {
    my ($self, %options) = @_;

    $self->{license_editions}->{$options{name}} = {
        name => $options{name}
    };

    if (defined($options{expires})) {
        $self->{license_editions}->{ $options{name} }->{has_expiration_date} = 'true';
        $self->{license_editions}->{ $options{name} }->{expires_seconds} = $options{expires} - time();
        $self->{license_editions}->{ $options{name} }->{expires_seconds} =
            0 if ($self->{license_editions}->{ $options{name} }->{expires_seconds} < 0);
        $self->{license_editions}->{ $options{name} }->{expires_human} = centreon::plugins::misc::change_seconds(
            value => $self->{license_editions}->{ $options{name} }->{expires_seconds}
        );
    } else {
        $self->{license_editions}->{ $options{name} }->{has_expiration_date} = 'false';
        $self->{license_editions}->{ $options{name} }->{expires_human} = 'unlimited';
        $self->{license_editions}->{ $options{name} }->{expires_seconds} = 0;
    }
}

sub add_license_quotas {
    my ($self, %options) = @_;

    $self->{license_quotas}->{$options{name}} = {
        name => $options{name}
    };

    if (defined($options{expires}) && $options{expires} > 0) {
        $self->{license_quotas}->{ $options{name} }->{has_expiration_date} = 'true';
        $self->{license_quotas}->{ $options{name} }->{expires_seconds} = $options{expires} - time();
        $self->{license_quotas}->{ $options{name} }->{expires_seconds} =
            0 if ($self->{license_quotas}->{ $options{name} }->{expires_seconds} < 0);
        $self->{license_quotas}->{ $options{name} }->{expires_human} = centreon::plugins::misc::change_seconds(
            value => $self->{license_quotas}->{ $options{name} }->{expires_seconds}
        );
    } else {
        $self->{license_quotas}->{ $options{name} }->{has_expiration_date} = 'false';
        $self->{license_quotas}->{ $options{name} }->{expires_human} = 'unlimited';
        $self->{license_quotas}->{ $options{name} }->{expires_seconds} = 0;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api(
        use_x_panw_region => 1,
        endpoint          => '/agg/custom/license/quota?agg_by=tenant',
        method            => 'GET'
    );

    $self->{license_editions} = {};
    $self->{license_quotas} = {};

    foreach my $license_data (@{$response->{data}}) {
        foreach my $edition (@{$license_data->{editions}}) {
            $self->add_license_edition(
                name    => $edition->{license_edition_name},
                expires => scalar(@{$edition->{expiry_ts}}) > 0 ? $edition->{expiry_ts}[0] : undef
            );
        }

        foreach my $quota (@{$license_data->{quotas}}) {
            $self->add_license_quotas(
                name    => "MU",
                expires => $quota->{licenseDetails}{"MU"}->{expiry_ts}
            );
            $self->add_license_quotas(
                name    => "CDL",
                expires => $quota->{licenseDetails}{"CDL"}->{expiry_ts}
            );
            $self->add_license_quotas(
                name    => "RN",
                expires => $quota->{licenseDetails}{"RN"}->{expiry_ts}
            );
        }
    }
}

1;

__END__

=head1 MODE

Check licenses.

=over 8

=item B<--unit>

Select the time unit for the expiration thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'edition-expires', 'quota-expires'.

=back

=cut
