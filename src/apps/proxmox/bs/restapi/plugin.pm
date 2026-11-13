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

package apps::proxmox::bs::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'datastore-usage' => 'apps::proxmox::bs::restapi::mode::datastoreusage',
        'disks'           => 'apps::proxmox::bs::restapi::mode::disks',
        'list-datastores' => 'apps::proxmox::bs::restapi::mode::listdatastores',
        'node-usage'      => 'apps::proxmox::bs::restapi::mode::nodeusage',
        'services'        => 'apps::proxmox::bs::restapi::mode::services',
        'snapshots'       => 'apps::proxmox::bs::restapi::mode::snapshots',
        'tasks'           => 'apps::proxmox::bs::restapi::mode::tasks',
        'version'         => 'apps::proxmox::bs::restapi::mode::version'
    };

    $self->{custom_modes}->{api} = 'apps::proxmox::bs::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor Proxmox Backup Server (PBS 4.x) using its REST API.

=cut
