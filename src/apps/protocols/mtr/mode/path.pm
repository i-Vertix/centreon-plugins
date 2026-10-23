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

package apps::protocols::mtr::mode::path;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters :values MSG_JSON_DECODE_ERROR);
use centreon::plugins::misc qw/is_excluded/;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::SHA qw(sha256_hex);

# mtr prints this host for a hop that did not answer
use constant NO_REPLY_HOST => '???';

sub prefix_destination_output {
    my ($self, %options) = @_;

    return "Destination '" . $options{instance_value}->{display} . "' ";
}

sub prefix_hop_output {
    my ($self, %options) = @_;

    return "Hop '" . $options{instance_value}->{hop} . "' [" . $options{instance_value}->{host} . "] ";
}

# Build the packet loss and round-trip time counters shared by the destination and the hops
sub build_probe_counters {
    my ($self, %options) = @_;

    my @counters = (
        { label => $options{prefix} . '-packet-loss', nlabel => $options{prefix} . '.packets.loss.percentage', set => {
                key_values      => [ { name => 'loss' } ],
                output_template => 'packet loss: %.2f %%',
                perfdatas       => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => $options{per_instance} }
                ]
            }
        }
    );

    foreach my $rtt ('last', 'average', 'best', 'worst', 'stdev') {
        push @counters, { label => $options{prefix} . '-rtt-' . $rtt, nlabel => $options{prefix} . '.rtt.' . $rtt . '.milliseconds', set => {
                key_values      => [ { name => 'rtt_' . $rtt } ],
                output_template => 'rtt ' . $rtt . ': %.2f ms',
                perfdatas       => [
                    { template => '%.2f', unit => 'ms', min => 0, label_extra_instance => $options{per_instance} }
                ]
            }
        };
    }

    return @counters;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'path', type => COUNTER_TYPE_GLOBAL },
        { name => 'destination', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_destination_output',
          skipped_code => { NO_VALUE() => 1 } },
        { name => 'hops', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_hop_output',
          message_multiple => 'All hops are ok', sort_attribute => 'hop', sort_method => 'num',
          skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{path} = [
        {
            label            => 'path-status',
            type             => COUNTER_KIND_TEXT,
            warning_default  => '%{path_changed} == 1',
            set              => {
                key_values => [
                    { name => 'hop_count' }, { name => 'hop_count_last' }, { name => 'hop_count_changed' },
                    { name => 'ip_changed' }, { name => 'path_changed' }, { name => 'changed_hops' },
                    { name => 'added_hops' }, { name => 'removed_hops' }
                ],
                output_template                => 'path has %{hop_count} hop(s) (last: %{hop_count_last}), changed hops: %{changed_hops}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'hop-count', nlabel => 'path.hops.count', set => {
                key_values      => [ { name => 'hop_count' } ],
                output_template => 'hops: %s',
                perfdatas       => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{destination} = [
        {
            label            => 'destination-status',
            type             => COUNTER_KIND_TEXT,
            critical_default => '%{status} ne "reached"',
            set              => {
                key_values                     => [ { name => 'status' }, { name => 'host' }, { name => 'display' } ],
                output_template                => 'status: %{status}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        $self->build_probe_counters(prefix => 'destination', per_instance => 0)
    ];

    $self->{maps_counters}->{hops} = [
        $self->build_probe_counters(prefix => 'hop', per_instance => 1)
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'        => { name => 'hostname', not_empty => 1, regexp_match => '^[\w.:-]+$',
                                 error_message => 'Option --hostname must be a host name or an IP address.' },
        'count:s'           => { name => 'count', default => 10, numeric => 1, greater_than => 0 },
        'interval:s'        => { name => 'interval', default => 1, greater_than => 0 },
        'max-hops:s'        => { name => 'max_hops', default => 30, numeric => 1, greater_than => 0, less_than_or_equal => 255 },
        'packet-size:s'     => { name => 'packet_size', numeric => 1, greater_than => 0 },
        'protocol:s'        => { name => 'protocol', default => 'icmp', is_in => [ 'icmp', 'udp', 'tcp' ] },
        'port:s'            => { name => 'port', type => 'port' },
        'timeout:s'         => { name => 'timeout', default => 30, numeric => 1, greater_than => 0 },
        'command:s'         => { name => 'command', default => '' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'include-hop:s'     => { name => 'include_hop' },
        'exclude-hop:s'     => { name => 'exclude_hop' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => 'Option --port can only be used with --protocol set to udp or tcp.')
        if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne ''
            && $self->{option_results}->{protocol} eq 'icmp');

    centreon::plugins::misc::check_security_command(
        output          => $self->{output},
        command         => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path    => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'mtr'
        if ($self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '--json --no-dns'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');

    my @arguments = (
        $self->{option_results}->{command_options},
        '--report-cycles', $self->{option_results}->{count},
        '--interval', $self->{option_results}->{interval},
        '--max-ttl', $self->{option_results}->{max_hops}
    );
    push @arguments, '--psize', $self->{option_results}->{packet_size}
        if (defined($self->{option_results}->{packet_size}) && $self->{option_results}->{packet_size} ne '');
    push @arguments, '--' . $self->{option_results}->{protocol}
        if ($self->{option_results}->{protocol} ne 'icmp');
    push @arguments, '--port', $self->{option_results}->{port}
        if (defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne '');
    push @arguments, $self->{option_results}->{hostname};
    $self->{mtr_command_options} = join(' ', @arguments);

    $self->{statefile_cache}->check_options(%options);
}

# Addresses of 'path' that are not in 'other', unless 'other' has a hop not answering at the same position
sub hops_missing_from {
    my ($self, %options) = @_;

    my %other_hosts = map { $_ => 1 } @{$options{other}};
    my @missing;
    for my $i (0 .. $#{$options{path}}) {
        my $host = $options{path}->[$i];
        next if ($host eq NO_REPLY_HOST || $other_hosts{$host});
        next if (($options{other}->[$i] // '') eq NO_REPLY_HOST);
        push @missing, $host;
    }

    return @missing;
}

sub compare_path {
    my ($self, %options) = @_;

    my ($previous, $current) = ($options{previous}, $options{current});
    my $hop_count = scalar(@$current);

    # first check: nothing to compare with yet
    if (!defined($previous)) {
        $self->{output}->output_add(long_msg => 'Path cache created, the path will be compared from the next check on.');
        $previous = $current;
    }

    # compare the sets of addresses rather than positions: a hop inserted in the middle of the path
    # must not be reported as a change of every following hop. A hop that did not answer is never a change.
    my @added_hops = $self->hops_missing_from(path => $current, other => $previous);
    my @removed_hops = $self->hops_missing_from(path => $previous, other => $current);

    my $hop_count_last = scalar(@$previous);
    my $hop_count_changed = $hop_count != $hop_count_last ? 1 : 0;
    my $ip_changed = (@added_hops || @removed_hops) ? 1 : 0;

    return {
        hop_count         => $hop_count,
        hop_count_last    => $hop_count_last,
        hop_count_changed => $hop_count_changed,
        ip_changed        => $ip_changed,
        path_changed      => $hop_count_changed || $ip_changed ? 1 : 0,
        added_hops        => @added_hops ? join(', ', @added_hops) : 'none',
        removed_hops      => @removed_hops ? join(', ', @removed_hops) : 'none',
        changed_hops      => $ip_changed ? join(', ', (map { '+' . $_ } @added_hops), (map { '-' . $_ } @removed_hops)) : 'none'
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(
        output          => $self->{output},
        options         => $self->{option_results},
        command         => $self->{option_results}->{command},
        command_path    => $self->{option_results}->{command_path},
        command_options => $self->{mtr_command_options}
    );
    $self->{output}->output_add(long_msg => $stdout, debug => 1);

    my $result = centreon::plugins::misc::json_decode($stdout, output => $self->{output}, errstr => MSG_JSON_DECODE_ERROR);
    my $hubs = $result->{report}->{hubs} // [];
    $self->{output}->option_exit(short_msg => 'No hop returned by mtr.')
        unless (ref($hubs) eq 'ARRAY' && @$hubs);

    my @hubs = sort { $a->{count} <=> $b->{count} } @$hubs;
    my @path;
    $self->{hops} = {};
    foreach my $hub (@hubs) {
        my $host = $hub->{host} // NO_REPLY_HOST;
        push @path, $host;

        next if ($host eq NO_REPLY_HOST);
        next if (is_excluded($host, $self->{option_results}->{include_hop}, $self->{option_results}->{exclude_hop}, output => $self->{output}));

        $self->{hops}->{$hub->{count}} = {
            hop  => $hub->{count},
            host => $host,
            $self->probe_values(hub => $hub)
        };
    }

    # the destination is the last hop: when it did not answer, the target was not reached
    my $last_hub = $hubs[-1];
    my $reached = ($path[-1] ne NO_REPLY_HOST && ($last_hub->{'Loss%'} // 100) < 100) ? 1 : 0;
    $self->{destination} = {
        display => $self->{option_results}->{hostname},
        host    => $path[-1],
        status  => $reached ? 'reached' : 'unreachable',
        loss    => $last_hub->{'Loss%'} // 100
    };
    $self->{destination} = { %{$self->{destination}}, $self->probe_values(hub => $last_hub) }
        if ($reached);

    $self->{statefile_cache}->read(
        statefile => 'mtr_' . sha256_hex(join('_',
            $self->{option_results}->{hostname},
            $self->{option_results}->{protocol},
            $self->{option_results}->{port} // ''
        ))
    );
    $self->{path} = $self->compare_path(previous => $self->{statefile_cache}->get(name => 'path'), current => \@path);
    $self->{statefile_cache}->write(data => { path => \@path, timestamp => time() });
}

sub probe_values {
    my ($self, %options) = @_;

    return (
        loss        => $options{hub}->{'Loss%'},
        rtt_last    => $options{hub}->{Last},
        rtt_average => $options{hub}->{Avg},
        rtt_best    => $options{hub}->{Best},
        rtt_worst   => $options{hub}->{Wrst},
        rtt_stdev   => $options{hub}->{StDev}
    );
}

1;

__END__

=head1 MODE

Check the network path to a target with C<mtr>: packet loss and round-trip times of the destination and of each hop,
and changes of the path since the previous check.

The C<mtr> command is executed locally and must be allowed to send raw packets (it usually relies on the
C<mtr-packet> helper with the C<cap_net_raw> capability). C<mtr> 0.92 or later is required for the C<--json> output.

The path (the list of hop IP addresses) is stored in a cache file and compared with the one of the previous check:
the number of hops, and the IP addresses that appeared or disappeared, whatever their position in the path.
A hop that did not answer (C<???>) is never considered as a change.

=over 8

=item B<--hostname>

Target to trace (host name or IP address).

=item B<--count>

Number of packets sent to each hop (C<mtr --report-cycles>). Packet loss and round-trip times are computed
over these packets (default: C<10>).

=item B<--interval>

Number of seconds between two packets (C<mtr --interval>, default: C<1>). The check lasts about
C<count> x C<interval> seconds, so B<--timeout> must be greater than this duration.

=item B<--max-hops>

Maximum number of hops to probe (C<mtr --max-ttl>, default: C<30>).

=item B<--packet-size>

Size of the packets in bytes (C<mtr --psize>).

=item B<--protocol>

Protocol used to probe the path. Can be: C<icmp>, C<udp>, C<tcp> (default: C<icmp>).

=item B<--port>

Destination port, only with B<--protocol> set to C<udp> or C<tcp>.

=item B<--timeout>

Timeout in seconds for the command execution (default: C<30>).

=item B<--command>

Command to execute (default: C<mtr>).

=item B<--command-path>

Path of the command.

=item B<--command-options>

Base options of the command (default: C<--json --no-dns>). The other C<mtr> options and the target are appended
to them. B<Keep> C<--json> or the output cannot be parsed. Keep C<--no-dns> to compare IP addresses:
without it, a change of reverse DNS name is reported as a path change.

=item B<--include-hop>

Only check the hops whose IP address matches this regular expression. The path comparison always uses all the hops.

=item B<--exclude-hop>

Exclude the hops whose IP address matches this regular expression. The path comparison always uses all the hops.

=item B<--warning-path-status>

Define the conditions to match for the status to be WARNING (default: C<%{path_changed} == 1>).
You can use the following variables: C<%{hop_count}>, C<%{hop_count_last}>, C<%{hop_count_changed}>,
C<%{ip_changed}>, C<%{path_changed}>, C<%{changed_hops}>,
C<%{added_hops}>, C<%{removed_hops}>.
To only alert when the number of hops changes (for instance with load balancing on the path),
use C<%{hop_count_changed} == 1>.

=item B<--critical-path-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: C<%{hop_count}>, C<%{hop_count_last}>, C<%{hop_count_changed}>,
C<%{ip_changed}>, C<%{path_changed}>, C<%{changed_hops}>,
C<%{added_hops}>, C<%{removed_hops}>.

=item B<--warning-destination-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: C<%{status}>, C<%{host}>, C<%{display}>.

=item B<--critical-destination-status>

Define the conditions to match for the status to be CRITICAL (default: C<%{status} ne "reached">).
You can use the following variables: C<%{status}>, C<%{host}>, C<%{display}>.

=item B<--warning-hop-count>

Threshold for the number of hops.

=item B<--critical-hop-count>

Threshold for the number of hops.

=item B<--warning-destination-packet-loss>

Threshold for the packet loss of the destination (in %).

=item B<--critical-destination-packet-loss>

Threshold for the packet loss of the destination (in %).

=item B<--warning-destination-rtt-last>

Threshold for the round-trip time of the last packet sent to the destination (in ms).

=item B<--critical-destination-rtt-last>

Threshold for the round-trip time of the last packet sent to the destination (in ms).

=item B<--warning-destination-rtt-average>

Threshold for the average round-trip time of the destination (in ms).

=item B<--critical-destination-rtt-average>

Threshold for the average round-trip time of the destination (in ms).

=item B<--warning-destination-rtt-best>

Threshold for the best round-trip time of the destination (in ms).

=item B<--critical-destination-rtt-best>

Threshold for the best round-trip time of the destination (in ms).

=item B<--warning-destination-rtt-worst>

Threshold for the worst round-trip time of the destination (in ms).

=item B<--critical-destination-rtt-worst>

Threshold for the worst round-trip time of the destination (in ms).

=item B<--warning-destination-rtt-stdev>

Threshold for the standard deviation of the round-trip times of the destination (in ms).

=item B<--critical-destination-rtt-stdev>

Threshold for the standard deviation of the round-trip times of the destination (in ms).

=item B<--warning-hop-packet-loss>

Threshold for the packet loss of each hop (in %). B<Note>: many routers limit their ICMP replies,
so an intermediate hop can show packet loss while the destination has none.

=item B<--critical-hop-packet-loss>

Threshold for the packet loss of each hop (in %).

=item B<--warning-hop-rtt-last>

Threshold for the round-trip time of the last packet sent to each hop (in ms).

=item B<--critical-hop-rtt-last>

Threshold for the round-trip time of the last packet sent to each hop (in ms).

=item B<--warning-hop-rtt-average>

Threshold for the average round-trip time of each hop (in ms).

=item B<--critical-hop-rtt-average>

Threshold for the average round-trip time of each hop (in ms).

=item B<--warning-hop-rtt-best>

Threshold for the best round-trip time of each hop (in ms).

=item B<--critical-hop-rtt-best>

Threshold for the best round-trip time of each hop (in ms).

=item B<--warning-hop-rtt-worst>

Threshold for the worst round-trip time of each hop (in ms).

=item B<--critical-hop-rtt-worst>

Threshold for the worst round-trip time of each hop (in ms).

=item B<--warning-hop-rtt-stdev>

Threshold for the standard deviation of the round-trip times of each hop (in ms).

=item B<--critical-hop-rtt-stdev>

Threshold for the standard deviation of the round-trip times of each hop (in ms).

=back

=cut
