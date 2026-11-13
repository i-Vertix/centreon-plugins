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

package apps::proxmox::bs::restapi::mode::disks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'SMART status: %s [type: %s] [used: %s] [model: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{type},
        $self->{result_values}->{used},
        $self->{result_values}->{model}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Disks ';
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'disks',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_disk_output',
            message_multiple => 'All disks are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'disks-total', nlabel => 'disks.total.count', display_ok => 0, set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{disks} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{status} eq "failed"',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'devpath' }, { name => 'type' }, { name => 'used' },
                    { name => 'model' }, { name => 'serial' }, { name => 'status' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'life-remaining', nlabel => 'disk.life.remaining.percentage', set => {
                key_values      => [ { name => 'life_remaining' }, { name => 'name' } ],
                output_template => 'life remaining: %.2f %%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'name' }
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
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' },
        'include-type:s' => { name => 'include_type', default => '' },
        'exclude-type:s' => { name => 'exclude_type', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $disks = $options{custom}->get_disks();

    $self->{global} = { total => 0 };
    $self->{disks} = {};
    foreach my $disk (@$disks) {
        my $name = $disk->{name} // next;
        my $type = $disk->{'disk-type'} // 'unknown';

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});

        $self->{disks}->{$name} = {
            name           => $name,
            devpath        => $disk->{devpath} // '',
            type           => $type,
            used           => $disk->{used} // 'unused',
            model          => $disk->{model} // '',
            serial         => $disk->{serial} // '',
            status         => $disk->{status} // 'unknown',
            # PBS gives the remaining life of SSDs in percent (100 for a new disk)
            life_remaining => $disk->{wearout}
        };
        $self->{global}->{total}++;
    }

    $self->{output}->option_exit(short_msg => 'No disk found.')
        unless $self->{global}->{total};
}

1;

__END__

=head1 MODE

Check the local disks of the node: SMART status and remaining life of solid-state drives.

=over 8

=item B<--include-name>

Filter disks by name (can be a regexp), e.g. C<^sd[ab]$>.

=item B<--exclude-name>

Exclude disks by name (can be a regexp).

=item B<--include-type>

Filter disks by type (can be a regexp): C<hdd>, C<ssd>, C<usb> or C<unknown>.

=item B<--exclude-type>

Exclude disks by type (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{devpath}>, C<%{type}>, C<%{used}>, C<%{model}>, C<%{serial}>, C<%{status}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{name}>, C<%{devpath}>, C<%{type}>, C<%{used}>, C<%{model}>, C<%{serial}>, C<%{status}>.
C<%{status}> is the SMART status: C<passed>, C<failed> or C<unknown>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} eq "failed"'>).
You can use the following variables: C<%{name}>, C<%{devpath}>, C<%{type}>, C<%{used}>, C<%{model}>, C<%{serial}>, C<%{status}>.

=item B<--warning-disks-total>

Threshold for the number of disks.

=item B<--critical-disks-total>

Threshold for the number of disks.

=item B<--warning-life-remaining>

Threshold for the remaining life of a disk in percent, e.g. C<20:>. Only solid-state drives report it.

=item B<--critical-life-remaining>

Threshold for the remaining life of a disk in percent, e.g. C<10:>.

=back

=cut
