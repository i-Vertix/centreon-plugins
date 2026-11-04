use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../../../src";
use apps::backup::zerto::zic::restapi::custom::api;

my $api = bless {}, 'apps::backup::zerto::zic::restapi::custom::api';

subtest 'date_to_epoch' => sub {
    is($api->date_to_epoch(value => '2021-01-01T00:00:00.000Z'), 1609459200, 'ISO 8601 UTC');
    is($api->date_to_epoch(value => '2021-01-01T01:00:00+01:00'), 1609459200, 'ISO 8601 with offset');
    is($api->date_to_epoch(value => '2021-01-01T01:00:00+0100'), 1609459200, 'ISO 8601 with offset without colon');
    is($api->date_to_epoch(value => '2020-12-31T19:00:00-05:00'), 1609459200, 'ISO 8601 with negative offset');
    is($api->date_to_epoch(value => '2021-01-01'), 1609459200, 'date only');
    is($api->date_to_epoch(value => undef), undef, 'undefined date');
    is($api->date_to_epoch(value => ''), undef, 'empty date');
    is($api->date_to_epoch(value => 'NA'), undef, 'invalid date');
};

subtest 'timespan_to_seconds' => sub {
    is($api->timespan_to_seconds(value => '00:15:00'), 900, 'hh:mm:ss');
    is($api->timespan_to_seconds(value => '1.02:03:04.500'), 93784, 'd.hh:mm:ss.fff');
    is($api->timespan_to_seconds(value => '-00:01:00'), -60, 'negative span');
    is($api->timespan_to_seconds(value => 'PT15M'), 900, 'ISO 8601 duration');
    is($api->timespan_to_seconds(value => 'P1DT2H'), 93600, 'ISO 8601 duration with days');
    is($api->timespan_to_seconds(value => undef), undef, 'undefined span');
    is($api->timespan_to_seconds(value => 'soon'), undef, 'invalid span');
};

done_testing();
