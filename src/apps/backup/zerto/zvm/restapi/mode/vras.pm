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

package apps::backup::zerto::zvm::restapi::mode::vras;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_vra_status $map_alert_status);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s, alert status: %s, version: %s",
        $self->{result_values}->{status},
        $self->{result_values}->{alert_status},
        $self->{result_values}->{vra_version}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'VRAs ';
}

sub prefix_vra_output {
    my ($self, %options) = @_;

    return "VRA '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'vras',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_vra_output',
            message_multiple => 'All VRAs are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vras-total', nlabel => 'vras.total.count', set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vras} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{alert_status} =~ /Warning/i || %{status} =~ /MaintenanceMode|Installing|Removing/i',
            critical_default => '%{alert_status} =~ /Error/i || %{status} =~ /InstallationError|HostPasswordChanged|UnsupportedEsxVersion|NotInstalled/i',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'status' }, { name => 'alert_status' }, { name => 'vra_version' },
                    { name => 'host_version' }, { name => 'group' }, { name => 'ip_address' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'protected-vms', nlabel => 'vra.vms.protected.count', set => {
                key_values      => [ { name => 'protected_vms' }, { name => 'name' } ],
                output_template => 'protected VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'protected-vpgs', nlabel => 'vra.vpgs.protected.count', display_ok => 0, set => {
                key_values      => [ { name => 'protected_vpgs' }, { name => 'name' } ],
                output_template => 'protected VPGs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'protected-volumes', nlabel => 'vra.volumes.protected.count', display_ok => 0, set => {
                key_values      => [ { name => 'protected_volumes' }, { name => 'name' } ],
                output_template => 'protected volumes: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'recovery-vms', nlabel => 'vra.vms.recovery.count', set => {
                key_values      => [ { name => 'recovery_vms' }, { name => 'name' } ],
                output_template => 'recovery VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'recovery-vpgs', nlabel => 'vra.vpgs.recovery.count', display_ok => 0, set => {
                key_values      => [ { name => 'recovery_vpgs' }, { name => 'name' } ],
                output_template => 'recovery VPGs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'recovery-volumes', nlabel => 'vra.volumes.recovery.count', display_ok => 0, set => {
                key_values      => [ { name => 'recovery_volumes' }, { name => 'name' } ],
                output_template => 'recovery volumes: %s',
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

    $options{options}->add_options(arguments => {
        'include-name:s'  => { name => 'include_name', default => '' },
        'exclude-name:s'  => { name => 'exclude_name', default => '' },
        'include-group:s' => { name => 'include_group', default => '' },
        'exclude-group:s' => { name => 'exclude_group', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vras = $options{custom}->get_vras();

    $self->{global} = { total => 0 };
    $self->{vras} = {};

    foreach my $vra (@$vras) {
        my $id = $vra->{VraIdentifierStr} // $vra->{VraIdentifier} // '';
        my $name = $vra->{VraName} || $id;
        my $group = $vra->{VraGroup} // '';

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($group, $self->{option_results}->{include_group}, $self->{option_results}->{exclude_group}, output => $self->{output});

        my $protected = $vra->{ProtectedCounters} // {};
        my $recovery = $vra->{RecoveryCounters} // {};
        $self->{vras}->{$id} = {
            name              => $name,
            status            => enum_name(value => $vra->{Status}, map => $map_vra_status),
            alert_status      => enum_name(value => $vra->{VraAlerts}->{VraAlertsStatus}, map => $map_alert_status),
            vra_version       => $vra->{VraVersion} // '-',
            host_version      => $vra->{HostVersion} // '-',
            group             => $group,
            ip_address        => $vra->{IpAddress} // '',
            protected_vms     => $protected->{Vms},
            protected_vpgs    => $protected->{Vpgs},
            protected_volumes => $protected->{Volumes},
            recovery_vms      => $recovery->{Vms},
            recovery_vpgs     => $recovery->{Vpgs},
            recovery_volumes  => $recovery->{Volumes}
        };
        $self->{global}->{total}++;
    }

    $self->{output}->option_exit(short_msg => 'No VRA found.')
        if $self->{global}->{total} == 0;
}

1;

__END__

=head1 MODE

Check Zerto virtual replication appliances (VRAs): installation and alert status, protected and recovered workloads.

=over 8

=item B<--include-name>

Filter VRAs by name (can be a regexp).

=item B<--exclude-name>

Exclude VRAs by name (can be a regexp).

=item B<--include-group>

Filter VRAs by VRA group (can be a regexp).

=item B<--exclude-group>

Exclude VRAs by VRA group (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{status}>, C<%{alert_status}>, C<%{vra_version}>, C<%{host_version}>, C<%{group}>, C<%{ip_address}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{alert_status} =~ /Warning/i || %{status} =~ /MaintenanceMode|Installing|Removing/i'>).
You can use the following variables: C<%{name}>, C<%{status}>, C<%{alert_status}>, C<%{vra_version}>, C<%{host_version}>, C<%{group}>, C<%{ip_address}>.
C<%{status}> can be: C<Installed>, C<UnsupportedEsxVersion>, C<NotInstalled>, C<Installing>, C<Removing>, C<InstallationError>,
C<HostPasswordChanged>, C<UpdatingIpSettings>, C<DuringChangeHost>, C<HostInMaintenanceMode>, C<HostEnteringMaintenanceMode>.
C<%{alert_status}> can be: C<Normal>, C<Warning>, C<Error>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{alert_status} =~ /Error/i || %{status} =~ /InstallationError|HostPasswordChanged|UnsupportedEsxVersion|NotInstalled/i'>).
You can use the following variables: C<%{name}>, C<%{status}>, C<%{alert_status}>, C<%{vra_version}>, C<%{host_version}>, C<%{group}>, C<%{ip_address}>.

=item B<--warning-vras-total>

Threshold for the total number of VRAs.

=item B<--critical-vras-total>

Threshold for the total number of VRAs.

=item B<--warning-protected-vms>

Threshold for the number of VMs protected through the VRA.

=item B<--critical-protected-vms>

Threshold for the number of VMs protected through the VRA.

=item B<--warning-protected-vpgs>

Threshold for the number of VPGs protected through the VRA.

=item B<--critical-protected-vpgs>

Threshold for the number of VPGs protected through the VRA.

=item B<--warning-protected-volumes>

Threshold for the number of volumes protected through the VRA.

=item B<--critical-protected-volumes>

Threshold for the number of volumes protected through the VRA.

=item B<--warning-recovery-vms>

Threshold for the number of VMs recovered to the VRA host.

=item B<--critical-recovery-vms>

Threshold for the number of VMs recovered to the VRA host.

=item B<--warning-recovery-vpgs>

Threshold for the number of VPGs recovered to the VRA host.

=item B<--critical-recovery-vpgs>

Threshold for the number of VPGs recovered to the VRA host.

=item B<--warning-recovery-volumes>

Threshold for the number of volumes recovered to the VRA host.

=item B<--critical-recovery-volumes>

Threshold for the number of volumes recovered to the VRA host.

=back

=cut
