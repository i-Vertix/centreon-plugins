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

package network::paloalto::api::mode::sdwan;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded);

sub prefix_interface_output {
    my ($self, %options) = @_;
    return sprintf("interface '%s' ", $options{instance_value}->{name});
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "command '%s' status: %s",
        $self->{result_values}->{command_name},
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Interfaces ' },
        {
            name             => 'sdwan',
            type             => COUNTER_TYPE_INSTANCE,
            cb_prefix_output => 'prefix_interface_output',
            message_multiple => 'All SD-Wan interfaces are ok'
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'interfaces-count',
            nlabel => 'interfaces.count',
            set    => {
                key_values      => [ { name => 'interfaces_count' } ],
                output_template => 'count: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'state',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{state} ne "up"',
            set => {
                key_values => [ { name => 'state' }, { name => 'interface_name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'latency', nlabel => 'linkmonitor.latency.milliseconds', set => {
            key_values              =>
                [ { name => 'latency' }, { name => 'interface_name' }, { name => 'interface_id' } ],
            output_template         => 'latency: %sms',
            closure_custom_perfdata => $self->can('custom_signal_perfdata')
        }
        },
        { label => 'jitter', nlabel => 'linkmonitor.jitter.milliseconds', set => {
            key_values              =>
                [ { name => 'jitter' }, { name => 'interface_name' }, { name => 'interface_id' } ],
            output_template         => 'jitter: %sms',
            closure_custom_perfdata => $self->can('custom_signal_perfdata')
        }
        },
        { label => 'packet-loss', nlabel => 'linkmonitor.packet.loss.percentage', set => {
            key_values              =>
                [ { name => 'packet_loss' }, { name => 'interface_name' }, { name => 'interface_id' } ],
            output_template         => 'packet loss: %.3f%%',
            closure_custom_perfdata => $self->can('custom_signal_perfdata')
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-interface-id:s'           => { name => 'include_interface_id', default => '' },
        'exclude-interface-id:s'           => { name => 'exclude_interface_id', default => '' },
        'include-interface-name:s'         => { name => 'include_interface_name', default => '' },
        'exclude-interface-name:s'         => { name => 'exclude_interface_name', default => '' },
        'include-virtual-interface-name:s' => { name => 'include_virtual_interface_name', default => '' },
        'exclude-virtual-interface-name:s' => { name => 'exclude_virtual_interface_name', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><sdwan><path-monitor><stats></stats></path-monitor></sdwan></show>',
        ForceArray => [ 'entry' ]
    );

    $self->{sdwan} = {};
    $self->{global} = { interface_count => 0 };

    $self->{output}->option_exit(short_msg => "No matching interfaces !")
        unless ref $result->{stats_list} eq 'HASH';

    foreach my $entry (@{$result->{stats_list}->{entry}}) {
        my $interface_name = $entry->{if_name} // '';
        my $virtual_interface_name = $entry->{vif_name} // '';
        my $interface_id = $entry->{if_id} // '';

        next if is_excluded($interface_id,
            $self->{option_results}->{include_interface_id},
            $self->{option_results}->{exclude_interface_id},
            output =>
                $self->{output});
        next if is_excluded($interface_name,
            $self->{option_results}->{include_interface_name},
            $self->{option_results}->{exclude_interface_name},
            output =>
                $self->{output});
        next if is_excluded($virtual_interface_name,
            $self->{option_results}->{include_virtual_interface_name},
            $self->{option_results}->{exclude_virtual_interface_name},
            output =>
                $self->{output});

        $self->{interfaces}->{$interface_name} = {
            interface_id      => $interface_id,
            interface_name    => $interface_name,
            virtual_interface => $virtual_interface_name,
            latency           => $entry->{latency},
            jitter            => $entry->{jitter},
            packet_loss       => $entry->{loss},
            state             => $entry->{state}
        };
        $self->{global}->{interface_count}++;
    }
}

1;

__END__

=head1 MODE

Check Palo Alto SD-Wan interfaces status and metrics

=over 8

=item B<--include-interface-id>

Include interface id (regexp).

=item B<--exclude-interface-id>

Exclude interface id (regexp).

=item B<--include-interface-name>

Include interface names (regexp).

=item B<--exclude-interface-name>

Exclude interface names (regexp).

=item B<--include-virtual-interface-name>

Include virtual-interface names (regexp).

=item B<--exclude-virtual-interface-name>

Exclude virtual-interface names (regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{interface_name}, %{interface_id}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} ne "up"').
You can use the following variables: %{state}, %{interface_name}, %{interface_id}

=item B<--warning-interfaces-count>

Warning threshold for interfaces count.

=item B<--critical-interfaces-count>

Critical threshold for interfaces count.

=item B<--warning-jitter>

Threshold in ms.

=item B<--critical-jitter>

Threshold in ms.

=item B<--warning-latency>

Threshold in ms.

=item B<--critical-latency>

Threshold in ms.

=item B<--warning-packetloss>

Threshold in %.

=item B<--critical-packetloss>

Threshold in %.

=back

=cut
