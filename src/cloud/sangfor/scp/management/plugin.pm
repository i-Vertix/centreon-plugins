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

package cloud::sangfor::scp::management::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'alarms'              => 'cloud::sangfor::scp::management::mode::alarms',
        'discovery'           => 'cloud::sangfor::scp::management::mode::discovery',
        'license'             => 'cloud::sangfor::scp::management::mode::license',
        'list-clusters'       => 'cloud::sangfor::scp::management::mode::listclusters',
        'list-hosts'          => 'cloud::sangfor::scp::management::mode::listhosts',
        'list-resource-pools' => 'cloud::sangfor::scp::management::mode::listresourcepools',
        'list-storages'       => 'cloud::sangfor::scp::management::mode::liststorages',
        'list-vms'            => 'cloud::sangfor::scp::management::mode::listvms',
        'platform'            => 'cloud::sangfor::scp::management::mode::platform'
    };

    $self->{custom_modes}->{api} = 'cloud::sangfor::scp::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor Sangfor Cloud Platform (SCP) the platform (alarms, licenses, discovery) using the Open API.

=cut
