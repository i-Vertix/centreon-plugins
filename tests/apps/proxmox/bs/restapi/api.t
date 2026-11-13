use strict;
use warnings;
use Test2::V0;
use Test2::Tools::Mock qw(mock);
use FindBin;
use lib "$FindBin::RealBin/../../../../../src";
use apps::proxmox::bs::restapi::custom::api;
use apps::proxmox::bs::restapi::mode::resources qw(maintenance_type upid_starttime task_state);

# in-memory statefile
{
    package MockCache;
    sub new { bless { data => {} }, shift }
    sub check_options { return 1 }
    sub read { return 1 }
    sub get { my ($self, %options) = @_; return $self->{data}->{$options{name}} }
    sub write { my ($self, %options) = @_; $self->{data} = $options{data} }
}

# HTTP client returning queued responses ([code, content]) and recording the requests
{
    package MockHttp;
    sub new { my ($class, @responses) = @_; bless { responses => [ @responses ], requests => [], code => 200 }, $class }
    sub set_options { return 1 }
    sub add_header { return 1 }
    sub request {
        my ($self, %options) = @_;
        push @{$self->{requests}}, { %options };
        my $response = shift(@{$self->{responses}}) // [ 500, '' ];
        $self->{code} = $response->[0];
        return $response->[1];
    }
    sub get_code { return $_[0]->{code} }
    sub get_message { return 'message' }
}

# output object: option_exit dies with the message
{
    package MockOutput;
    sub new { bless { long => [] }, shift }
    sub option_exit { my ($self, %options) = @_; die 'option_exit: ' . $options{short_msg} . "\n" }
    sub output_add { my ($self, %options) = @_; push @{$self->{long}}, $options{long_msg} if defined($options{long_msg}) }
}

sub new_api {
    my (%options) = @_;

    my $api = bless {
        output => MockOutput->new(),
        http   => MockHttp->new(@{$options{responses} // []}),
        cache  => MockCache->new()
    }, 'apps::proxmox::bs::restapi::custom::api';
    $api->set_options(option_results => {
        hostname             => 'pbs.example',
        port                 => 8007,
        node                 => 'localhost',
        realm                => 'pbs',
        ticket_lifetime      => 5400,
        api_token_id         => '',
        api_token_secret     => '',
        api_username         => '',
        api_password         => '',
        unknown_http_status  => '%{http_code} < 200 or %{http_code} >= 300',
        %{$options{option_results} // {}}
    });
    $api->check_options();

    return $api;
}

my $data = '{"data":{"version":"4.0","release":"18"}}';

subtest 'maintenance_type' => sub {
    is(maintenance_type(value => 'type=read-only,message=migration'), 'read-only', 'property string');
    is(maintenance_type(value => 'message=x,type=offline'), 'offline', 'type not first');
    is(maintenance_type(value => 'unmount'), 'unmount', 'default key');
    is(maintenance_type(value => undef), '', 'no maintenance');
};

subtest 'upid_starttime' => sub {
    is(upid_starttime(value => 'UPID:pbs01:00000371:000001DA:000187A6:6A40F0A0:garbage_collection:store01:root@pam:'), 0x6A40F0A0, 'start time of the UPID');
    is(upid_starttime(value => 'not an upid'), undef, 'invalid UPID');
    is(upid_starttime(value => ''), undef, 'empty UPID');
};

subtest 'task_state' => sub {
    is(task_state(endtime => undef, status => undef), 'running', 'no end time');
    is(task_state(endtime => 1, status => 'OK'), 'ok', 'OK');
    is(task_state(endtime => 1, status => 'WARNINGS: 2'), 'warning', 'warnings');
    is(task_state(endtime => 1, status => 'unknown'), 'unknown', 'unknown');
    is(task_state(endtime => 1, status => 'backup failed: connection reset'), 'error', 'error message');
};

subtest 'options' => sub {
    my $api = new_api(option_results => { api_username => 'monitor', api_password => 'pass-123' });
    is($api->{api_username}, 'monitor@pbs', 'realm appended to the user');
    is($api->{auth_type}, 'ticket', 'ticket authentication');

    $api = new_api(option_results => { api_username => 'monitor@pam', api_password => 'pass-123' });
    is($api->{api_username}, 'monitor@pam', 'user with realm kept');

    $api = new_api(option_results => { api_token_id => 'monitor@pbs!centreon', api_token_secret => 'token-123' });
    is($api->{auth_type}, 'token', 'token authentication');
    is($api->get_auth_header(), 'Authorization: PBSAPIToken=monitor@pbs!centreon:token-123', 'token header');

    like(dies { new_api(option_results => { api_token_id => 'x' }) }, qr/--api-token-secret/, 'token without secret');
    like(dies { new_api(option_results => { api_username => 'x' }) }, qr/--api-password/, 'user without password');
    like(dies { new_api() }, qr/--api-token-id/, 'no credentials');
};

subtest 'ticket cache' => sub {
    our $ticket_calls = 0;
    my $mock = mock 'apps::proxmox::bs::restapi::custom::api' => (
        override => [ request_ticket => sub { $ticket_calls++; return 'PBS:monitor@pbs:ticket-' . $ticket_calls } ]
    );

    my $api = new_api(option_results => { api_username => 'monitor', api_password => 'pass-123' });
    is($api->get_ticket(), 'PBS:monitor@pbs:ticket-1', 'ticket requested');
    is($api->get_ticket(), 'PBS:monitor@pbs:ticket-1', 'ticket read from the cache');
    is($ticket_calls, 1, 'one ticket request');
    is($api->{cache}->{data}->{expires_on} - time(), within(5400, 2), 'ticket kept for --ticket-lifetime');

    $api->{api_password} = 'other';
    $api->get_ticket();
    is($ticket_calls, 2, 'a new password invalidates the cached ticket');

    $api->{cache}->{data}->{expires_on} = time() - 1;
    $api->get_ticket();
    is($ticket_calls, 3, 'an expired ticket is renewed');

    is($api->get_auth_header(), 'Cookie: PBSAuthCookie=PBS:monitor@pbs:ticket-3', 'ticket cookie');
    $api->clean_ticket();
    is($api->get_auth_header(), 'Cookie: PBSAuthCookie=PBS:monitor@pbs:ticket-4', 'a cleaned ticket is renewed');
};

subtest 'request_ticket' => sub {
    my $api = new_api(
        option_results => { api_username => 'monitor', api_password => 'p&ss' },
        responses      => [ [ 200, '{"data":{"ticket":"PBS:monitor@pbs:abc","CSRFPreventionToken":"x"}}' ] ]
    );
    is($api->request_ticket(), 'PBS:monitor@pbs:abc', 'ticket from the response');
    is($api->{http}->{requests}->[0]->{query_form_post}, 'username=monitor%40pbs&password=p%26ss', 'credentials are URL-encoded');

    $api = new_api(option_results => { api_username => 'monitor', api_password => 'bad' }, responses => [ [ 401, '{"data":null}' ] ]);
    like(dies { $api->request_ticket() }, qr/Authentication failed \[code: '401'\]/, 'wrong credentials');
};

subtest 'request_api' => sub {
    my $api = new_api(
        option_results => { api_token_id => 'monitor@pbs!centreon', api_token_secret => 'token-123' },
        responses      => [ [ 200, $data ] ]
    );
    is($api->request_api(endpoint => '/version', expect => 'HASH'), { version => '4.0', release => '18' }, 'data attribute returned');
    is($api->{http}->{requests}->[0]->{url_path}, '/api2/json/version', 'API path');

    # expired ticket: the cache is cleaned and the request is sent again with a new ticket
    our $ticket_calls = 0;
    my $mock = mock 'apps::proxmox::bs::restapi::custom::api' => (
        override => [ request_ticket => sub { $ticket_calls++; return 'ticket-' . $ticket_calls } ]
    );
    $api = new_api(option_results => { api_username => 'monitor', api_password => 'pass-123' }, responses => [ [ 401, '' ], [ 200, $data ] ]);
    is($api->request_api(endpoint => '/version')->{version}, '4.0', 'retry after 401');
    is($ticket_calls, 2, 'new ticket after 401');
    is($api->{http}->{requests}->[1]->{header}, [ 'Cookie: PBSAuthCookie=ticket-2' ], 'retry with the new ticket');

    $api = new_api(option_results => { api_token_id => 'a', api_token_secret => 'b' }, responses => [ [ 400, '' ], [ 400, '{"data":null}' ] ]);
    is($api->request_api(endpoint => '/admin/datastore/store02/snapshots', ignore_error => 1), undef, 'ignored error returns undef');

    $api = new_api(option_results => { api_token_id => 'a', api_token_secret => 'b' }, responses => [ [ 200, '{"data":{}}' ] ]);
    like(dies { $api->request_api(endpoint => '/nodes/localhost/services', expect => 'ARRAY') }, qr/unexpected response/, 'unexpected data type');

    $api = new_api(option_results => { api_token_id => 'a', api_token_secret => 'b' }, responses => [ [ 200, 'not json' ] ]);
    like(dies { $api->request_api(endpoint => '/version') }, qr/Cannot decode response/, 'invalid JSON');
};

subtest 'get_tasks parameters' => sub {
    my $api = new_api(option_results => { api_token_id => 'a', api_token_secret => 'b' }, responses => [ [ 200, '{"data":[]}' ] ]);
    $api->get_tasks(since => 1000, store => 'store01');
    is($api->{http}->{requests}->[0]->{get_param}, [ 'limit=0', 'since=1000', 'store=store01' ], 'no limit, since and store');
    is($api->{http}->{requests}->[0]->{url_path}, '/api2/json/nodes/localhost/tasks', 'tasks of the node');
};

done_testing();
