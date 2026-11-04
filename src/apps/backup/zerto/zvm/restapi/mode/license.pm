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

package apps::backup::zerto::zvm::restapi::mode::license;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw(floor);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "type: %s, expired: %s, expiry date: %s",
        $self->{result_values}->{type},
        $self->{result_values}->{is_expired},
        $self->{result_values}->{expiry_date}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'protected VMs total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub prefix_license_output {
    my ($self, %options) = @_;

    return 'License ';
}

sub prefix_site_output {
    my ($self, %options) = @_;

    return "Site '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'license', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_license_output', skipped_code => { NO_VALUE() => 1 } },
        {
            name             => 'sites',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_site_output',
            message_multiple => 'All sites are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{license} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{is_expired} eq "true"',
            set              => {
                key_values                     => [ { name => 'type' }, { name => 'is_expired' }, { name => 'expiry_date' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'expires', nlabel => 'license.expires.days', set => {
                key_values      => [ { name => 'expires_days' } ],
                output_template => 'expires in %d days',
                perfdatas       => [
                    { template => '%d', unit => 'd' }
                ]
            }
        },
        { label => 'vms-usage', nlabel => 'license.vms.usage.count', set => {
                key_values            => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'vms-usage-free', nlabel => 'license.vms.free.count', display_ok => 0, set => {
                key_values            => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'vms-usage-prct', nlabel => 'license.vms.usage.percentage', display_ok => 0, set => {
                key_values            => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas             => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sites} = [
        { label => 'site-protected-vms', nlabel => 'license.site.vms.protected.count', set => {
                key_values      => [ { name => 'protected_vms' }, { name => 'name' } ],
                output_template => 'protected VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->get_license();
    my $details = ref($response) eq 'HASH' ? $response->{Details} : undef;
    $self->{output}->option_exit(short_msg => 'No license information found.')
        unless ref($details) eq 'HASH';

    my $expiry_time = $options{custom}->date_to_epoch(value => $details->{ExpiryTime});
    $self->{license} = {
        type        => $details->{LicenseType} || '-',
        is_expired  => defined($expiry_time) && $expiry_time < time() ? 'true' : 'false',
        expiry_date => $details->{ExpiryTime} // '-'
    };
    $self->{license}->{expires_days} = floor(($expiry_time - time()) / 86400) if defined($expiry_time);

    my $total = $details->{MaxVms};
    my $used = $response->{Usage}->{TotalVmsCount};
    if ($total && $total > 0 && defined($used)) {
        $self->{license}->{total} = $total;
        $self->{license}->{used} = $used;
        $self->{license}->{free} = $total - $used;
        $self->{license}->{prct_used} = $used * 100 / $total;
        $self->{license}->{prct_free} = 100 - $self->{license}->{prct_used};
    }

    $self->{sites} = {};
    foreach my $site (@{$response->{Usage}->{SitesUsage} // []}) {
        my $name = $site->{SiteName} || $site->{SiteIdentifier} // '';
        $self->{sites}->{$site->{SiteIdentifier} // $name} = {
            name          => $name,
            # the documentation spells the field 'ProtectedVmsCount' and 'ProtectedVMsCount'
            protected_vms => $site->{ProtectedVmsCount} // $site->{ProtectedVMsCount}
        };
    }
}

1;

__END__

=head1 MODE

Check Zerto license: expiration and protected VMs against the license VM limit.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{type}>, C<%{is_expired}>, C<%{expiry_date}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{type}>, C<%{is_expired}>, C<%{expiry_date}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{is_expired} eq "true"'>).
You can use the following variables: C<%{type}>, C<%{is_expired}>, C<%{expiry_date}>.

=item B<--warning-expires>

Threshold for the number of days before the license expires.

=item B<--critical-expires>

Threshold for the number of days before the license expires.

=item B<--warning-vms-usage>

Threshold for the number of protected VMs.

=item B<--critical-vms-usage>

Threshold for the number of protected VMs.

=item B<--warning-vms-usage-free>

Threshold for the number of VMs that can still be protected.

=item B<--critical-vms-usage-free>

Threshold for the number of VMs that can still be protected.

=item B<--warning-vms-usage-prct>

Threshold for the license VM usage (in %).

=item B<--critical-vms-usage-prct>

Threshold for the license VM usage (in %).

=item B<--warning-site-protected-vms>

Threshold for the number of protected VMs of each site using the license.

=item B<--critical-site-protected-vms>

Threshold for the number of protected VMs of each site using the license.

=back

=cut
