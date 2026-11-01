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

package cloud::sangfor::scp::management::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(json_encode is_excluded);
use cloud::sangfor::scp::management::mode::resources qw(get_resources);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'resource-type:s'  => { name => 'resource_type', default => 'vm', is_in => [ 'resourcepool', 'cluster', 'host', 'vm', 'storage' ] },
        'include-name:s'   => { name => 'include_name', default => '' },
        'exclude-name:s'   => { name => 'exclude_name', default => '' },
        'include-status:s' => { name => 'include_status', default => '' },
        'exclude-status:s' => { name => 'exclude_status', default => '' },
        'prettify'         => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats = { start_time => time() };

    $disco_stats->{results} = [];
    foreach my $entry (@{get_resources(custom => $options{custom}, type => $self->{option_results}->{resource_type})}) {
        next if is_excluded($entry->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        # the power state is used for the VMs, the status for the other resources
        my $status = $self->{option_results}->{resource_type} eq 'vm' ? $entry->{power_state} : $entry->{status};
        next if is_excluded($status, $self->{option_results}->{include_status}, $self->{option_results}->{exclude_status}, output => $self->{output});

        push @{$disco_stats->{results}}, { resource_type => $self->{option_results}->{resource_type}, %$entry };
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@{$disco_stats->{results}});

    my $encoded_data = json_encode(
        $disco_stats,
        prettify => $self->{option_results}->{prettify},
        errstr   => '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}',
        output   => $self->{output}
    );

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Discover Sangfor SCP resources (host discovery).

=over 8

=item B<--resource-type>

Define the type of resources to discover: C<resourcepool>, C<cluster>, C<host>, C<vm> or C<storage> (default: C<vm>).

=item B<--include-name>

Filter resources by name (can be a regexp).

=item B<--exclude-name>

Exclude resources by name (can be a regexp).

=item B<--include-status>

Filter resources by status (can be a regexp). The power state (C<on> or C<off>) is used for the VMs.

=item B<--exclude-status>

Exclude resources by status (can be a regexp). The power state (C<on> or C<off>) is used for the VMs.

=item B<--prettify>

Prettify the JSON output.

=back

=cut
