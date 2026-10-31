#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::backup::zerto::zic::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'alerts'               => 'apps::backup::zerto::zic::restapi::mode::alerts',
        'license'              => 'apps::backup::zerto::zic::restapi::mode::license',
        'list-member-accounts' => 'apps::backup::zerto::zic::restapi::mode::listmemberaccounts',
        'list-vpgs'            => 'apps::backup::zerto::zic::restapi::mode::listvpgs',
        'member-accounts'      => 'apps::backup::zerto::zic::restapi::mode::memberaccounts',
        'tasks'                => 'apps::backup::zerto::zic::restapi::mode::tasks',
        'vpgs'                 => 'apps::backup::zerto::zic::restapi::mode::vpgs'
    };

    $self->{custom_modes}->{api} = 'apps::backup::zerto::zic::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor Zerto In-Cloud for AWS (ZIC) using its REST API (v2).

=cut
