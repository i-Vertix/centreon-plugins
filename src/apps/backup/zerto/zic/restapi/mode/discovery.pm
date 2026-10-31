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

package apps::backup::zerto::zic::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(json_encode is_excluded);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-name:s'              => { name => 'include_name', default => '' },
        'exclude-name:s'              => { name => 'exclude_name', default => '' },
        'include-protected-account:s' => { name => 'include_protected_account', default => '' },
        'exclude-protected-account:s' => { name => 'exclude_protected_account', default => '' },
        'prettify'                    => { name => 'prettify' }
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

    my $response = $options{custom}->get_vpgs();

    my @disco_data;
    foreach my $vpg (@{$response->{vpgs} // []}) {
        my $general = $vpg->{vpgInfo}->{general} // {};
        my $name = $general->{name} || $vpg->{vpgId};
        my $protected_account = $general->{protectedAccount}->{accountId} // '';

        next if is_excluded($name, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}, output => $self->{output});
        next if is_excluded($protected_account, $self->{option_results}->{include_protected_account}, $self->{option_results}->{exclude_protected_account}, output => $self->{output});

        push @disco_data, {
            id                => $vpg->{vpgId},
            name              => $name,
            description       => $general->{description} // '',
            state             => ref($vpg->{vpgState}) eq 'ARRAY' ? join(',', @{$vpg->{vpgState}}) : ($vpg->{vpgState} // ''),
            protection_status => $vpg->{replicationInfo}->{replicationStatistics}->{protectionStatus} // '',
            protected_account => $protected_account,
            protected_region  => $general->{protectedRegion}->{name} // '',
            recovery_account  => $general->{recoveryAccount}->{accountId} // '',
            recovery_region   => $general->{recoveryRegion}->{name} // '',
            protected_vms     => ref($vpg->{vpgInfo}->{protectedResources}->{vms}) eq 'ARRAY'
                ? scalar(@{$vpg->{vpgInfo}->{protectedResources}->{vms}}) : 0,
            # the host discovery takes the host address from the results: every VPG is checked through the ZIC appliance
            hostname          => $self->{option_results}->{hostname}
        };
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@disco_data);
    $disco_stats->{results} = [ sort { $a->{name} cmp $b->{name} } @disco_data ];

    my $encoded_data = json_encode($disco_stats, prettify => $self->{option_results}->{prettify}, output => $self->{output}, no_exit => 1);

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Zerto In-Cloud VPG discovery for the host discovery: one result per VPG, with the address of the ZIC appliance as C<hostname>.

=over 8

=item B<--include-name>

Only discover VPGs whose name matches (can be a regexp).

=item B<--exclude-name>

Exclude VPGs whose name matches (can be a regexp).

=item B<--include-protected-account>

Only discover VPGs whose protected member account ID matches (can be a regexp).

=item B<--exclude-protected-account>

Exclude VPGs whose protected member account ID matches (can be a regexp).

=item B<--prettify>

Prettify the JSON output.

=back

=cut
