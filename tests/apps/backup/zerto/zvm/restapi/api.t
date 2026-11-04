use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Mock qw(mock);
use FindBin;
use lib "$FindBin::RealBin/../../../../../../src";
use apps::backup::zerto::zvm::restapi::custom::api;
use apps::backup::zerto::zvm::restapi::mode::resources qw(enum_name $map_vpg_status $map_vpg_substatus $map_task_state $map_volume_type);

# in-memory statefile
{
    package MockCache;
    sub new { bless { data => {} }, shift }
    sub read { return 1 }
    sub get { my ($self, %options) = @_; return $self->{data}->{$options{name}} }
    sub write { my ($self, %options) = @_; $self->{data} = $options{data} }
}

sub new_api {
    my (%options) = @_;

    return bless {
        cache          => MockCache->new(),
        hostname       => 'zvm-a.example',
        auth_type      => $options{auth_type} // 'keycloak',
        client_id      => 'zvm-monitoring',
        client_secret  => $options{client_secret} // 'secret-123',
        username       => $options{username} // '',
        password       => $options{password} // '',
        option_results => { port => 443 }
    }, 'apps::backup::zerto::zvm::restapi::custom::api';
}

subtest 'date_to_epoch' => sub {
    my $api = new_api();

    is($api->date_to_epoch(value => '/Date(1520423877045)/'), 1520423877, 'Microsoft JSON date');
    is($api->date_to_epoch(value => '/Date(928142400000+0300)/'), 928142400, 'Microsoft JSON date with offset (already UTC)');
    is($api->date_to_epoch(value => '\/Date(1479047837000)\/'), 1479047837, 'escaped Microsoft JSON date');
    ok($api->date_to_epoch(value => '/Date(-62135596800000)/') < 0, 'minimal date of a running task is before 1970');
    is($api->date_to_epoch(value => '2021-01-01T00:00:00.000Z'), 1609459200, 'ISO 8601 UTC');
    is($api->date_to_epoch(value => '2021-01-01T01:00:00+01:00'), 1609459200, 'ISO 8601 with offset');
    is($api->date_to_epoch(value => '2021-01-01'), 1609459200, 'date only');
    is($api->date_to_epoch(value => undef), undef, 'undefined date');
    is($api->date_to_epoch(value => ''), undef, 'empty date');
    is($api->date_to_epoch(value => 'NA'), undef, 'invalid date');
};

subtest 'enum_name' => sub {
    is(enum_name(value => 1, map => $map_vpg_status), 'MeetingSLA', 'VPG status number');
    is(enum_name(value => 'RpoNotMeetingSLA', map => $map_vpg_status), 'RpoNotMeetingSLA', 'VPG status name is kept');
    is(enum_name(value => 31, map => $map_vpg_substatus), 'JournalStorageError', 'VPG substatus number');
    is(enum_name(value => 4, map => $map_task_state), 'Failed', 'task state number');
    is(enum_name(value => 6, map => $map_volume_type), 'Appliances', 'volume type number');
    is(enum_name(value => 99, map => $map_vpg_status), 'unknown(99)', 'unknown number');
    is(enum_name(value => undef, map => $map_vpg_status), 'unknown', 'undefined value');
    is(enum_name(value => '', map => $map_vpg_status, default => '-'), '-', 'empty value with default');
};

subtest 'auth header' => sub {
    is(new_api()->get_auth_header(token => 'abc'), 'Authorization: Bearer abc', 'Keycloak bearer token');
    is(new_api(auth_type => 'session')->get_auth_header(token => 'abc'), 'x-zerto-session: abc', 'Zerto session');
};

subtest 'token cache' => sub {
    my $mock = mock 'apps::backup::zerto::zvm::restapi::custom::api' => (
        override => [
            get_keycloak_token => sub { $main::keycloak_calls++; return ('kc-token', 300) },
            get_session_token  => sub { $main::session_calls++; return ('zerto-session', 1500) }
        ]
    );

    our ($keycloak_calls, $session_calls) = (0, 0);
    my $api = new_api();
    is($api->get_token(), 'kc-token', 'Keycloak token requested');
    is($api->get_token(), 'kc-token', 'Keycloak token read from the cache');
    is($keycloak_calls, 1, 'one Keycloak request');
    ok($api->{cache}->{data}->{expires_on} - time() > 240, 'token lifetime from expires_in');

    $api->{client_secret} = 'other-secret';
    $api->get_token();
    is($keycloak_calls, 2, 'a new secret invalidates the cached token');

    $api->{cache}->{data}->{expires_on} = time() + 30;
    $api->get_token();
    is($keycloak_calls, 3, 'a token expiring within a minute is renewed');

    $api->clean_token();
    $api->get_token();
    is($keycloak_calls, 4, 'a cleaned token is renewed');

    my $session_api = new_api(auth_type => 'session', username => 'monitor', password => 'pass-123');
    is($session_api->get_token(), 'zerto-session', 'Zerto session requested');
    is($session_api->get_token(), 'zerto-session', 'Zerto session read from the cache');
    is($session_api->{cache}->{data}->{expires_on} - time(), within(1500, 2), 'session kept less than the 30 minutes idle timeout');
    is($session_calls, 1, 'one session request');
};

done_testing();
