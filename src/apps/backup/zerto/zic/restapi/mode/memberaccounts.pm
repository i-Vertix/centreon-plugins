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

package apps::backup::zerto::zic::restapi::mode::memberaccounts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_excluded);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status: ' . $self->{result_values}->{status};
    $msg .= ' (' . $self->{result_values}->{status_description} . ')' if ($self->{result_values}->{status_description} ne '');

    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Member accounts ';
}

sub prefix_account_output {
    my ($self, %options) = @_;

    my $msg = "Member account '" . $options{instance_value}->{id} . "'";
    $msg .= ' (' . $options{instance_value}->{description} . ')' if ($options{instance_value}->{description} ne '');

    return $msg . ' ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name             => 'accounts',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_account_output',
            message_multiple => 'All member accounts are ok',
            skipped_code     => { NO_VALUE() => 1 }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'accounts-total', nlabel => 'memberaccounts.total.count', display_ok => 0, set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'accounts-not-ready', nlabel => 'memberaccounts.notready.count', set => {
                key_values      => [ { name => 'not_ready' }, { name => 'total' } ],
                output_template => 'not ready: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{accounts} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{status} !~ /^Ready$/i',
            set              => {
                key_values                     => [
                    { name => 'id' }, { name => 'description' }, { name => 'status' }, { name => 'status_description' }
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'protected-vms', nlabel => 'memberaccount.vms.protected.count', set => {
                key_values      => [ { name => 'protected_vms' }, { name => 'id' } ],
                output_template => 'protected VMs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        },
        { label => 'vpgs', nlabel => 'memberaccount.vpgs.count', set => {
                key_values      => [ { name => 'vpgs' }, { name => 'id' } ],
                output_template => 'VPGs: %s',
                perfdatas       => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'id' }
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
        'include-id:s'          => { name => 'include_id', default => '' },
        'exclude-id:s'          => { name => 'exclude_id', default => '' },
        'include-description:s' => { name => 'include_description', default => '' },
        'exclude-description:s' => { name => 'exclude_description', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $accounts = $options{custom}->get_member_accounts();
    my $statistics = $options{custom}->get_member_accounts_statistics();

    $self->{global} = { total => 0, not_ready => 0 };
    $self->{accounts} = {};
    foreach my $account (@$accounts) {
        my $id = ref($account->{accountId}) eq 'HASH' ? $account->{accountId}->{id} : $account->{accountId};
        my $description = $account->{description} // '';

        next if is_excluded($id, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output});
        next if is_excluded($description, $self->{option_results}->{include_description}, $self->{option_results}->{exclude_description}, output => $self->{output});

        my $status = $account->{status} // 'unknown';
        $self->{accounts}->{$id} = {
            id                 => $id,
            description        => $description,
            status             => $status,
            status_description => $account->{statusDescription} // ''
        };

        $self->{global}->{total}++;
        $self->{global}->{not_ready}++ if $status ne 'Ready';
    }

    foreach my $statistic (@$statistics) {
        my $id = ref($statistic->{accountId}) eq 'HASH' ? $statistic->{accountId}->{id} : $statistic->{accountId};
        next unless defined($id) && defined($self->{accounts}->{$id});

        $self->{accounts}->{$id}->{protected_vms} = $statistic->{protectedVms};
        $self->{accounts}->{$id}->{vpgs} = $statistic->{totalVpgs};
    }

    $self->{output}->option_exit(short_msg => 'No member account found.')
        unless %{$self->{accounts}};
}

1;

__END__

=head1 MODE

Check Zerto In-Cloud AWS member accounts: status, protected VMs and VPGs.

=over 8

=item B<--include-id>

Filter member accounts by AWS account ID (can be a regexp).

=item B<--exclude-id>

Exclude member accounts by AWS account ID (can be a regexp).

=item B<--include-description>

Filter member accounts by description (can be a regexp).

=item B<--exclude-description>

Exclude member accounts by description (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{id}>, C<%{description}>, C<%{status}>, C<%{status_description}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{id}>, C<%{description}>, C<%{status}>, C<%{status_description}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: C<'%{status} !~ /^Ready$/i'>).
You can use the following variables: C<%{id}>, C<%{description}>, C<%{status}>, C<%{status_description}>.
C<%{status}> can be: C<Ready>, C<NotReady>.

=item B<--warning-accounts-total>

Threshold for the number of member accounts.

=item B<--critical-accounts-total>

Threshold for the number of member accounts.

=item B<--warning-accounts-not-ready>

Threshold for the number of member accounts that are not ready.

=item B<--critical-accounts-not-ready>

Threshold for the number of member accounts that are not ready.

=item B<--warning-protected-vms>

Threshold for the number of protected VMs of the member account.

=item B<--critical-protected-vms>

Threshold for the number of protected VMs of the member account.

=item B<--warning-vpgs>

Threshold for the number of VPGs of the member account.

=item B<--critical-vpgs>

Threshold for the number of VPGs of the member account.

=back

=cut
