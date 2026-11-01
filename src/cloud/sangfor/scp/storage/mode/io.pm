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

package cloud::sangfor::scp::storage::mode::io;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values :unit_conversion);
use cloud::sangfor::scp::storage::mode::resources qw(get_storages);

sub prefix_storage_output {
    my ($self, %options) = @_;
    return "Storage '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storages', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages IO are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{storages} = [
        { label => 'read', nlabel => 'storage.io.read.usage.bytespersecond', set => {
                key_values          => [ { name => 'read' }, { name => 'name' } ],
                output_template     => 'read: %.2f %s/s',
                output_change_bytes => CONVERT_STORAGE,
                perfdatas           => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'write', nlabel => 'storage.io.write.usage.bytespersecond', set => {
                key_values          => [ { name => 'write' }, { name => 'name' } ],
                output_template     => 'write: %.2f %s/s',
                output_change_bytes => CONVERT_STORAGE,
                perfdatas           => [
                    { template => '%d', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'id:s'               => { name => 'id', default => '' },
        'resource-pool-id:s' => { name => 'resource_pool_id', default => '' },
        'include-name:s'     => { name => 'include_name', default => '' },
        'exclude-name:s'     => { name => 'exclude_name', default => '' },
        'include-type:s'     => { name => 'include_type', default => '' },
        'exclude-type:s'     => { name => 'exclude_type', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{storages} = {};
    foreach my $entry (@{get_storages(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}) {
        $self->{storages}->{$entry->{id}} = { name => $entry->{name}, read => $entry->{io}->{read}, write => $entry->{io}->{write} };
    }
}

1;

__END__

=head1 MODE

Check the IO of storages (datastores).

=over 8

=item B<--id>

Define the ID of the storage to check.

=item B<--resource-pool-id>

Only check the storages of this resource pool ID.

=item B<--include-name>

Filter storages by name (can be a regexp).

=item B<--exclude-name>

Exclude storages by name (can be a regexp).

=item B<--include-type>

Filter storages by type (can be a regexp).

=item B<--exclude-type>

Exclude storages by type (can be a regexp).

=item B<--warning-read>

Threshold for the read speed (in B/s).

=item B<--critical-read>

Threshold for the read speed (in B/s).

=item B<--warning-write>

Threshold for the write speed (in B/s).

=item B<--critical-write>

Threshold for the write speed (in B/s).

=back

=cut
