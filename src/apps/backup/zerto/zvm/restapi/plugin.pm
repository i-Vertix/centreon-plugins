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

package apps::backup::zerto::zvm::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'alerts'          => 'apps::backup::zerto::zvm::restapi::mode::alerts',
        'datastores'      => 'apps::backup::zerto::zvm::restapi::mode::datastores',
        'discovery'       => 'apps::backup::zerto::zvm::restapi::mode::discovery',
        'license'         => 'apps::backup::zerto::zvm::restapi::mode::license',
        'list-datastores' => 'apps::backup::zerto::zvm::restapi::mode::listdatastores',
        'list-peer-sites' => 'apps::backup::zerto::zvm::restapi::mode::listpeersites',
        'list-vms'        => 'apps::backup::zerto::zvm::restapi::mode::listvms',
        'list-vpgs'       => 'apps::backup::zerto::zvm::restapi::mode::listvpgs',
        'list-vras'       => 'apps::backup::zerto::zvm::restapi::mode::listvras',
        'peer-sites'      => 'apps::backup::zerto::zvm::restapi::mode::peersites',
        'tasks'           => 'apps::backup::zerto::zvm::restapi::mode::tasks',
        'vms'             => 'apps::backup::zerto::zvm::restapi::mode::vms',
        'volumes'         => 'apps::backup::zerto::zvm::restapi::mode::volumes',
        'vpgs'            => 'apps::backup::zerto::zvm::restapi::mode::vpgs',
        'vras'            => 'apps::backup::zerto::zvm::restapi::mode::vras'
    };

    $self->{custom_modes}->{api} = 'apps::backup::zerto::zvm::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor Zerto Virtual Manager (ZVM) using its REST API (v1): the ZVM Appliance (Zerto 10.x) or a Windows ZVM.

=cut
