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

package apps::backup::zerto::zvm::restapi::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_volume_type);

sub prefix_type_output {
    my ($self, %options) = @_;

    return "Volume type '" . $options{instance_value}->{type} . "' ";
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{name} . "' [type: " . $options{instance_value}->{type} . '] ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'types',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_type_output',
            message_multiple => 'All volume types are ok',
            skipped_code     => { NO_VALUE() => 1 }
        },
        {
            name             => 'volumes',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_volume_output',
            message_multiple => 'All volumes are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{types} = [
        { label => 'type-volumes', nlabel => 'volumes.total.count', set => {
                key_values      => [ { name => 'count' }, { name => 'type' } ],
                output_template => 'volumes: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'type' }
                ]
            }
        },
        { label => 'type-used', nlabel => 'volumes.space.used.bytes', set => {
                key_values          => [ { name => 'used' }, { name => 'type' } ],
                output_template     => 'used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'type' }
                ]
            }
        },
        { label => 'type-provisioned', nlabel => 'volumes.space.provisioned.bytes', set => {
                key_values          => [ { name => 'provisioned' }, { name => 'type' } ],
                output_template     => 'provisioned: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'type' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{volumes} = [
        { label => 'used', nlabel => 'volume.space.used.bytes', set => {
                key_values          => [ { name => 'used' }, { name => 'name' } ],
                output_template     => 'used: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'provisioned', nlabel => 'volume.space.provisioned.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'provisioned' }, { name => 'name' } ],
                output_template     => 'provisioned: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'volume-type:s'       => {
            name          => 'volume_type',
            is_in         => [ 'Protected', 'Recovery', 'Journal', 'Scratch', 'Appliances', 'Unknown' ],
            error_message => "Unknown volume type '%{value}'. Accepted values: %{validation_value}."
        },
        'include-name:s'      => { name => 'include_name', default => '' },
        'exclude-name:s'      => { name => 'exclude_name', default => '' },
        'include-vm:s'        => { name => 'include_vm', default => '' },
        'exclude-vm:s'        => { name => 'exclude_vm', default => '' },
        'include-vpg:s'       => { name => 'include_vpg', default => '' },
        'exclude-vpg:s'       => { name => 'exclude_vpg', default => '' },
        'include-vpg-id:s'    => { name => 'include_vpg_id', default => '' },
        'exclude-vpg-id:s'    => { name => 'exclude_vpg_id', default => '' },
        'include-datastore:s' => { name => 'include_datastore', default => '' },
        'exclude-datastore:s' => { name => 'exclude_datastore', default => '' },
        'skip-volumes'        => { name => 'skip_volumes' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $volumes = $options{custom}->get_volumes(volume_type => $self->{option_results}->{volume_type});

    $self->{types} = {};
    $self->{volumes} = {};

    foreach my $volume (@$volumes) {
        my $path = ref($volume->{Path}) eq 'HASH' ? $volume->{Path} : {};
        my $vm = $volume->{ProtectedVm}->{Name} || $volume->{OwningVM}->{Name} || $volume->{OwningVm}->{Name} || '';
        my $vpg = $volume->{Vpg}->{Name} // '';
        my $datastore = $volume->{Datastore}->{Name} // '';
        # the full path ('[datastore] folder/disk.vmdk') identifies the volume
        my $name = $path->{Full} || join('/', grep { $_ ne '' } $datastore, $vm, $path->{FileName} // '');

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($vm, $self->{option_results}->{include_vm}, $self->{option_results}->{exclude_vm}, output => $self->{output});
        next if is_excluded($vpg, $self->{option_results}->{include_vpg}, $self->{option_results}->{exclude_vpg}, output => $self->{output});
        next if is_excluded($volume->{Vpg}->{Identifier} // '', $self->{option_results}->{include_vpg_id}, $self->{option_results}->{exclude_vpg_id}, output => $self->{output});
        next if is_excluded($datastore, $self->{option_results}->{include_datastore}, $self->{option_results}->{exclude_datastore}, output => $self->{output});

        my $type = enum_name(value => $volume->{VolumeType}, map => $map_volume_type);
        my $used = $volume->{Size}->{UsedInBytes};
        my $provisioned = $volume->{Size}->{ProvisionedInBytes};

        $self->{types}->{$type} //= { type => $type, count => 0, used => 0, provisioned => 0 };
        $self->{types}->{$type}->{count}++;
        $self->{types}->{$type}->{used} += $used // 0;
        $self->{types}->{$type}->{provisioned} += $provisioned // 0;

        next if $self->{option_results}->{skip_volumes};

        $self->{volumes}->{$type . '_' . $name} = {
            name        => $name,
            type        => $type,
            used        => $used,
            provisioned => $provisioned
        };
        $self->{output}->output_add(long_msg => sprintf(
            "volume '%s' [type: %s] [vm: %s] [vpg: %s] [datastore: %s] [thin provisioned: %s]",
            $name, $type, $vm, $vpg, $datastore, $volume->{IsThinProvisioned} ? 'yes' : 'no'
        ), debug => 1);
    }

    $self->{output}->option_exit(short_msg => 'No volume found.')
        unless %{$self->{types}};
}

1;

__END__

=head1 MODE

Check the space used by the Zerto volumes (protected, recovery, journal, scratch and appliance volumes), per volume type and per volume.

=over 8

=item B<--volume-type>

Only check one type of volume, filtered by the API.
Can be: C<Protected>, C<Recovery>, C<Journal>, C<Scratch>, C<Appliances>, C<Unknown>.

=item B<--include-name>

Filter volumes by full path (can be a regexp).

=item B<--exclude-name>

Exclude volumes by full path (can be a regexp).

=item B<--include-vm>

Filter volumes by the name of the protected or owning VM (can be a regexp).

=item B<--exclude-vm>

Exclude volumes by the name of the protected or owning VM (can be a regexp).

=item B<--include-vpg>

Filter volumes by VPG name (can be a regexp).

=item B<--exclude-vpg>

Exclude volumes by VPG name (can be a regexp).

=item B<--include-vpg-id>

Filter volumes by VPG ID (can be a regexp).

=item B<--exclude-vpg-id>

Exclude volumes by VPG ID (can be a regexp).

=item B<--include-datastore>

Filter volumes by datastore name (can be a regexp).

=item B<--exclude-datastore>

Exclude volumes by datastore name (can be a regexp).

=item B<--skip-volumes>

Only check the totals per volume type, not each volume.

=item B<--warning-type-volumes>

Threshold for the number of volumes of each type.

=item B<--critical-type-volumes>

Threshold for the number of volumes of each type.

=item B<--warning-type-used>

Threshold for the space used by the volumes of each type (in B).

=item B<--critical-type-used>

Threshold for the space used by the volumes of each type (in B).

=item B<--warning-type-provisioned>

Threshold for the space provisioned for the volumes of each type (in B).

=item B<--critical-type-provisioned>

Threshold for the space provisioned for the volumes of each type (in B).

=item B<--warning-used>

Threshold for the space used by each volume (in B).

=item B<--critical-used>

Threshold for the space used by each volume (in B).

=item B<--warning-provisioned>

Threshold for the space provisioned for each volume (in B).

=item B<--critical-provisioned>

Threshold for the space provisioned for each volume (in B).

=back

=cut
