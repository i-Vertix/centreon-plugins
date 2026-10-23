use strict;
use warnings;

package MockOptions;
sub new { bless { extra_arguments => [ ], option_results => {}, default => {}, custom => {} }, shift }
sub add_options { }
sub add_help { }

package MockOutput;
sub new { bless {}, shift }
sub add_option_msg { }
sub output_add { }
sub use_new_perfdata { }
sub option_exit { my ($self, %options) = @_; die "option_exit: " . ($options{short_msg} // '') . "\n" }

package main;

# Unit tests of the mtr path mode: parsing of the mtr JSON report and comparison with the cached path

use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::misc;
use apps::protocols::mtr::mode::path;

my $data_dir = "$FindBin::RealBin/data";
my $options = MockOptions->new();
my $output = MockOutput->new();

my $mode = apps::protocols::mtr::mode::path->new(options => $options, output => $output);
$mode->{option_results} = { hostname => 'path.example', protocol => 'icmp' };

# no command is run: the fixture of the test is returned instead
my $report;
my $misc = mock 'centreon::plugins::misc' => (override => [ execute => sub { return $report } ]);

# the cache file is kept in memory
my $cache = {};
my $statefile = mock 'centreon::plugins::statefile' => (override => [
    read  => sub { },
    get   => sub { my ($self, %options) = @_; return $cache->{ $options{name} } },
    write => sub { my ($self, %options) = @_; $cache = $options{data} }
]);

sub slurp {
    open(my $fh, '<', "$data_dir/$_[0]") or die "Cannot open $_[0]: $!";
    local $/;
    return <$fh>;
}

sub run_report {
    my (%options) = @_;
    $report = slurp($options{fixture});
    $mode->manage_selection();
}

subtest 'Report with count as strings' => sub {
    $cache = {};
    run_report(fixture => 'mtr_192.0.2.100.json');

    is([ sort { $a <=> $b } keys %{$mode->{hops}} ], [ 1 .. 6 ], 'all hops are kept');
    is($mode->{hops}->{4}, {
        hop => 4, host => '198.51.100.4', loss => 0, rtt_last => 1.81, rtt_average => 3.40,
        rtt_best => 1.81, rtt_worst => 12.04, rtt_stdev => 3.33
    }, 'hop values');
    is($mode->{destination}->{status}, 'reached', 'destination reached');
    is($mode->{destination}->{rtt_average}, 1.50, 'destination round-trip time');
    is($mode->{path}->{path_changed}, 0, 'first check is not a change');
    is($cache->{path}, [ '198.51.100.1', '198.51.100.2', '198.51.100.3', '198.51.100.4', '198.51.100.5', '192.0.2.100' ], 'path cached');
};

subtest 'Report with count as integers and a hop not answering' => sub {
    run_report(fixture => 'mtr_loss.example.json');

    is([ sort { $a <=> $b } keys %{$mode->{hops}} ], [ 1, 3, 4 ], 'hop not answering is skipped');
    is($mode->{destination}->{loss}, 30, 'destination packet loss');
};

subtest 'Unreachable destination' => sub {
    run_report(fixture => 'mtr_unreachable.example.json');

    is($mode->{destination}->{status}, 'unreachable', 'destination not reached');
    is($mode->{destination}->{loss}, 100, 'destination packet loss');
    ok(!defined($mode->{destination}->{rtt_average}), 'no round-trip time without reply');
};

subtest 'Path changes' => sub {
    my $previous = [ '192.0.2.1', '198.51.100.7', '203.0.113.50' ];

    my $result = $mode->compare_path(previous => $previous, current => [ @$previous ]);
    is($result->{path_changed}, 0, 'same path');

    $result = $mode->compare_path(previous => $previous, current => [ '192.0.2.1', '198.51.100.9', '203.0.113.50' ]);
    is([ @$result{qw/path_changed ip_changed hop_count_changed changed_hops/} ],
       [ 1, 1, 0, '+198.51.100.9, -198.51.100.7' ], 'replaced hop');

    $result = $mode->compare_path(previous => $previous, current => [ '192.0.2.1', '192.0.2.99', '198.51.100.7', '203.0.113.50' ]);
    is([ @$result{qw/hop_count hop_count_last hop_count_changed added_hops removed_hops/} ],
       [ 4, 3, 1, '192.0.2.99', 'none' ], 'inserted hop is reported once');

    $result = $mode->compare_path(previous => $previous, current => [ '192.0.2.1', '???', '203.0.113.50' ]);
    is($result->{path_changed}, 0, 'hop not answering is not a change');

    $result = $mode->compare_path(previous => undef, current => $previous);
    is([ @$result{qw/hop_count hop_count_last path_changed/} ], [ 3, 3, 0 ], 'no cache yet');
};

subtest 'Invalid report' => sub {
    $report = slurp('mtr_garbage.example.txt');
    like(dies { $mode->manage_selection() }, qr/^option_exit: Cannot decode response/, 'not a JSON report');

    $report = '{"report": {"mtr": {}, "hubs": []}}';
    like(dies { $mode->manage_selection() }, qr/^option_exit: No hop returned by mtr/, 'report without hop');
};

done_testing;
