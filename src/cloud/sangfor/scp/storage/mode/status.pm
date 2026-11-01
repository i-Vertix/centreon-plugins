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

package cloud::sangfor::scp::storage::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use cloud::sangfor::scp::storage::mode::resources qw(get_storages);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        'status: %s [type: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{type}
    );
}

sub prefix_storage_output {
    my ($self, %options) = @_;
    return "Storage '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'storages', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_storage_output', message_multiple => 'All storages are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{storages} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{status} =~ /alarm/i',
            critical_default => '%{status} =~ /offline|error|fail/i',
            set              => {
                key_values                     => [ { name => 'id' }, { name => 'name' }, { name => 'status' }, { name => 'type' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

    $self->{storages} = {
        map { $_->{id} => $_ } @{get_storages(custom => $options{custom}, option_results => $self->{option_results}, output => $self->{output})}
    };
}

1;

__END__

=head1 MODE

Check the status of storages (datastores).

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

Filter storages by type (can be a regexp). The type can be: C<local>, C<vs>, C<fc>, C<iscsi>, C<vmfs>, C<vsan>, C<cifs>, C<nfs>, C<asan>, C<samba_share>.

=item B<--exclude-type>

Exclude storages by type (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{type}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{status} =~ /alarm/i'>).
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{type}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} =~ /offline|error|fail/i'>).
You can use the following variables: C<%{id}>, C<%{name}>, C<%{status}>, C<%{type}>.
The status can be: C<normal>, C<offline>, C<alarm>, C<error> and for virtual storages C<ok>, C<fail>, C<creating>,
C<expanding>, C<deleting>, C<replacing_disk>, C<replacing_host>, ...

=back

=cut
