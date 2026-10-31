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

package apps::backup::zerto::zic::restapi::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(change_seconds is_excluded);
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "alert [level: %s] [type: %s] [entity: %s]%s %s (%s ago)",
        $self->{result_values}->{level},
        $self->{result_values}->{type},
        $self->{result_values}->{entity},
        $self->{result_values}->{vpg_id} ne '' ? ' [vpg: ' . $self->{result_values}->{vpg_id} . ']' : '',
        $self->{result_values}->{description},
        $self->{result_values}->{since} == 0 ? '0s' : change_seconds(value => $self->{result_values}->{since})
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alerts ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name                    => 'alarms',
            type                    => COUNTER_TYPE_GROUP,
            message_multiple        => '0 alert(s) detected',
            display_counter_problem => { nlabel => 'alerts.problems.current.count', min => 0 },
            group                   => [ { name => 'alarm', skipped_code => { -11 => 1 } } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alerts-total', nlabel => 'alerts.total.count', set => {
                key_values      => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'alerts-vpg', nlabel => 'alerts.vpg.count', display_ok => 0, set => {
                key_values      => [ { name => 'vpg' }, { name => 'total' } ],
                output_template => 'VPG: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'alerts-zic', nlabel => 'alerts.zic.count', display_ok => 0, set => {
                key_values      => [ { name => 'zic' }, { name => 'total' } ],
                output_template => 'ZIC: %s',
                perfdatas       => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{alarm} = [
        {
            label            => 'status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{level} =~ /warning/i',
            set              => {
                key_values                     => [
                    { name => 'level' }, { name => 'type' }, { name => 'entity' }, { name => 'help_id' },
                    { name => 'vpg_id' }, { name => 'description' }, { name => 'since' }
                ],
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
        'filter-type:s'     => { redirect => 'include_type' },
        'filter-entity:s'   => { redirect => 'include_entity' },
        'filter-vpg-id:s'   => { redirect => 'include_vpg_id' },
        'include-type:s'    => { name => 'include_type', default => '' },
        'exclude-type:s'    => { name => 'exclude_type', default => '' },
        'include-entity:s'  => { name => 'include_entity', default => '' },
        'exclude-entity:s'  => { name => 'exclude_entity', default => '' },
        'include-vpg-id:s'  => { name => 'include_vpg_id', default => '' },
        'exclude-vpg-id:s'  => { name => 'exclude_vpg_id', default => '' },
        'include-dismissed' => { name => 'include_dismissed' },
        'memory'            => { name => 'memory' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options)
        if $self->{option_results}->{memory};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $alerts = $options{custom}->get_alerts(include_dismissed => $self->{option_results}->{include_dismissed});

    my $last_time;
    if ($self->{option_results}->{memory}) {
        $self->{statefile_cache}->read(
            statefile => 'zerto_zic_' . $self->{mode} . '_' . sha256_hex(join('_', $options{custom}->get_connection_info(),
                map { $self->{option_results}->{$_} // '' } qw/include_type exclude_type include_entity exclude_entity include_vpg_id exclude_vpg_id/))
        );
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    $self->{global} = { total => 0, vpg => 0, zic => 0 };
    $self->{alarms} = { global => { alarm => {} } };
    my ($i, $current_time) = (1, time());
    foreach my $alert (@$alerts) {
        my $type = $alert->{alertKey}->{failureType} // '';
        my $entity = $alert->{alertEntity} // '';
        my $vpg_id = $alert->{vpgId} // '';

        next if is_excluded($type, $self->{option_results}->{include_type}, $self->{option_results}->{exclude_type}, output => $self->{output});
        next if is_excluded($entity, $self->{option_results}->{include_entity}, $self->{option_results}->{exclude_entity}, output => $self->{output});
        next if is_excluded($vpg_id, $self->{option_results}->{include_vpg_id}, $self->{option_results}->{exclude_vpg_id}, output => $self->{output});

        my $start_time = $options{custom}->date_to_epoch(value => $alert->{startTime}) // $current_time;
        next if defined($last_time) && $start_time < $last_time;

        $self->{alarms}->{global}->{alarm}->{$i} = {
            level       => $alert->{alertLevel} // '',
            type        => $type,
            entity      => $entity,
            help_id     => $alert->{alertHelpId} // '',
            vpg_id      => $vpg_id,
            description => $alert->{alertDescription} // '',
            since       => $current_time - $start_time
        };
        $self->{global}->{total}++;
        $self->{global}->{lc($entity)}++ if defined($self->{global}->{lc($entity)});
        $i++;
    }

    $self->{statefile_cache}->write(data => { last_time => $current_time })
        if $self->{option_results}->{memory};
}

1;

__END__

=head1 MODE

Check Zerto In-Cloud alerts. Dismissed alerts are ignored by default.

=over 8

=item B<--include-type>

Filter alerts by failure type (can be a regexp).
Types are: C<RPO>, C<History>, C<SLA>, C<NeedsConfig>, C<License>, C<NoRegionConnectivity>, C<LicenseIsAboutToReachVmLimit>, C<LicenseVmLimitReached>.

=item B<--exclude-type>

Exclude alerts by failure type (can be a regexp).

=item B<--include-entity>

Filter alerts by entity (can be a regexp). Entities are: C<ZIC>, C<VPG>.

=item B<--exclude-entity>

Exclude alerts by entity (can be a regexp).

=item B<--include-vpg-id>

Filter alerts by VPG ID (can be a regexp).

=item B<--exclude-vpg-id>

Exclude alerts by VPG ID (can be a regexp).

=item B<--include-dismissed>

Also check alerts that have been dismissed.

=item B<--memory>

Only check alerts that started since the last execution.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: C<%{level}>, C<%{type}>, C<%{entity}>, C<%{help_id}>, C<%{vpg_id}>, C<%{description}>, C<%{since}>.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: C<'%{level} =~ /warning/i'>).
You can use the following variables: C<%{level}>, C<%{type}>, C<%{entity}>, C<%{help_id}>, C<%{vpg_id}>, C<%{description}>, C<%{since}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{level}>, C<%{type}>, C<%{entity}>, C<%{help_id}>, C<%{vpg_id}>, C<%{description}>, C<%{since}>.

=item B<--warning-alerts-total>

Threshold for the number of alerts.

=item B<--critical-alerts-total>

Threshold for the number of alerts.

=item B<--warning-alerts-vpg>

Threshold for the number of VPG alerts.

=item B<--critical-alerts-vpg>

Threshold for the number of VPG alerts.

=item B<--warning-alerts-zic>

Threshold for the number of ZIC alerts.

=item B<--critical-alerts-zic>

Threshold for the number of ZIC alerts.

=back

=cut
