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

package apps::backup::zerto::zvm::restapi::mode::peersites;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_pairing_status);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "pairing status: %s, version: %s",
        $self->{result_values}->{pairing_status},
        $self->{result_values}->{version}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Peer sites ';
}

sub prefix_site_output {
    my ($self, %options) = @_;

    return "Peer site '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'sites',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_site_output',
            message_multiple => 'All peer sites are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'sites-total', nlabel => 'peersites.total.count', set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sites-paired', nlabel => 'peersites.paired.count', display_ok => 0, set => {
                key_values      => [ { name => 'paired' }, { name => 'total' } ],
                output_template => 'paired: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sites} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{pairing_status} =~ /^Pairing$/i',
            critical_default => '%{pairing_status} =~ /Unpaired/i',
            set              => {
                key_values                     => [
                    { name => 'name' }, { name => 'id' }, { name => 'hostname' }, { name => 'location' },
                    { name => 'pairing_status' }, { name => 'version' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'incoming-throughput', nlabel => 'peersite.throughput.incoming.bitspersecond', set => {
                key_values          => [ { name => 'incoming_throughput' }, { name => 'name' } ],
                output_template     => 'incoming throughput: %s %s/s',
                output_change_bytes => 2,
                perfdatas           => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'storage-provisioned', nlabel => 'peersite.storage.provisioned.bytes', display_ok => 0, set => {
                key_values          => [ { name => 'storage_provisioned' }, { name => 'name' } ],
                output_template     => 'provisioned storage: %s %s',
                output_change_bytes => 1,
                perfdatas           => [
                    { template => '%d', unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'storage-used', nlabel => 'peersite.storage.used.bytes', set => {
                key_values          => [ { name => 'storage_used' }, { name => 'name' } ],
                output_template     => 'used storage: %s %s',
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
        'include-name:s' => { name => 'include_name', default => '' },
        'exclude-name:s' => { name => 'exclude_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $sites = $options{custom}->get_peer_sites();

    $self->{global} = { total => 0, paired => 0 };
    $self->{sites} = {};

    foreach my $site (@$sites) {
        my $id = $site->{SiteIdentifier} // '';
        my $name = $site->{PeerSiteName} || $id;

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});

        my $pairing_status = enum_name(value => $site->{PairingStatus}, map => $map_pairing_status);
        # storage values are in MB, the incoming throughput in Mb/s
        $self->{sites}->{$id} = {
            id                  => $id,
            name                => $name,
            hostname            => $site->{HostName} // '',
            location            => $site->{Location} // '',
            pairing_status      => $pairing_status,
            version             => $site->{Version} // '-',
            incoming_throughput => defined($site->{IncomingThroughputInMb}) ? $site->{IncomingThroughputInMb} * 1000 * 1000 : undef,
            storage_provisioned => defined($site->{ProvisionedStorage}) ? $site->{ProvisionedStorage} * 1024 * 1024 : undef,
            storage_used        => defined($site->{UsedStorage}) ? $site->{UsedStorage} * 1024 * 1024 : undef
        };
        $self->{global}->{total}++;
        $self->{global}->{paired}++ if $pairing_status eq 'Paired';
    }

    $self->{output}->option_exit(short_msg => 'No peer site found.')
        if $self->{global}->{total} == 0;
}

1;

__END__

=head1 MODE

Check Zerto peer sites: pairing status, ZVM version, incoming throughput and storage used by the VPGs recovered to the site.

=over 8

=item B<--include-name>

Filter peer sites by name (can be a regexp).

=item B<--exclude-name>

Exclude peer sites by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{name}>, C<%{id}>, C<%{hostname}>, C<%{location}>, C<%{pairing_status}>, C<%{version}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{pairing_status} =~ /^Pairing$/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{hostname}>, C<%{location}>, C<%{pairing_status}>, C<%{version}>.
C<%{pairing_status}> can be: C<Paired>, C<Pairing>, C<Unpaired>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{pairing_status} =~ /Unpaired/i'>).
You can use the following variables: C<%{name}>, C<%{id}>, C<%{hostname}>, C<%{location}>, C<%{pairing_status}>, C<%{version}>.

=item B<--warning-sites-total>

Threshold for the total number of peer sites.

=item B<--critical-sites-total>

Threshold for the total number of peer sites.

=item B<--warning-sites-paired>

Threshold for the number of paired peer sites.

=item B<--critical-sites-paired>

Threshold for the number of paired peer sites.

=item B<--warning-incoming-throughput>

Threshold for the incoming throughput of the VMs recovered on the peer site (in b/s).

=item B<--critical-incoming-throughput>

Threshold for the incoming throughput of the VMs recovered on the peer site (in b/s).

=item B<--warning-storage-provisioned>

Threshold for the storage provisioned for the VMs recovered to the peer site (in B).

=item B<--critical-storage-provisioned>

Threshold for the storage provisioned for the VMs recovered to the peer site (in B).

=item B<--warning-storage-used>

Threshold for the storage used by the VMs recovered to the peer site (in B).

=item B<--critical-storage-used>

Threshold for the storage used by the VMs recovered to the peer site (in B).

=back

=cut
