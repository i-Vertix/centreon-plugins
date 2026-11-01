use strict;
use warnings;
use Test2::V0;
use FindBin;
use lib "$FindBin::RealBin/../../../../../src";
use cloud::sangfor::scp::custom::api;

{
    package MockOutput;
    sub new { bless { exits => [] }, shift }
    sub option_exit {
        my ($self, %options) = @_;
        push @{$self->{exits}}, $options{short_msg};
        die "option_exit: $options{short_msg}\n";
    }
    sub output_add { }
}

sub new_api {
    my (%options) = @_;
    return bless {
        output     => MockOutput->new(),
        access_key => 'my-access-key',
        secret_key => 'my-secret-key',
        region     => 'cn-south-1',
        service    => 'open-api',
        %options
    }, 'cloud::sangfor::scp::custom::api';
}

subtest 'EC2 signature' => sub {
    my $api = new_api();

    # reference signatures computed with an independent implementation of the documented algorithm
    my $headers = $api->get_ec2_headers(method => 'GET', path => '/janus/20180725/azs', time => 1793491200);
    is($headers, [
        'Authorization: AWS4-HMAC-SHA256 Credential=my-access-key/20261101/cn-south-1/open-api/aws4_request, SignedHeaders=path;x-amz-date, Signature=2b032e68900d1b880a1a308b2836c11d71d21022710c3ca1a9d0a8527061eb75',
        'X-Amz-Date: 20261101T000000Z'
    ], 'GET request without body');

    $headers = $api->get_ec2_headers(method => 'POST', path => '/janus/20190725/alarms/1/remark', body => '{"remark":"test"}', time => 1793491200);
    like($headers->[0], qr/Signature=c8c410d5d28a003ee6f086bfa2ef8d1d612bea7278b35b2ce8fae3f467096ce2$/, 'POST request with body');
};

subtest 'common response format' => sub {
    my $api = new_api();

    is($api->check_response(decoded => { code => 0, message => '', data => { a => 1 } }), { a => 1 }, 'code 0 returns data');
    is($api->check_response(decoded => { errcode => '', message => '', data => [ 1 ] }), [ 1 ], 'empty errcode returns data');
    is($api->check_response(decoded => [ 1, 2 ]), [ 1, 2 ], 'unwrapped response is returned as is');

    like(
        dies { $api->check_response(decoded => { errcode => '0x120090010063', message => 'Invalid parameter', data => {} }) },
        qr/API returns error code '0x120090010063': Invalid parameter/,
        'errcode raises an error'
    );
    like(
        dies { $api->check_response(decoded => { code => 1, message => 'failed', data => {} }) },
        qr/API returns error code '1': failed/,
        'code raises an error'
    );
};

subtest 'pagination' => sub {
    my $api = new_api();
    my @pages;
    my $mock = mock 'cloud::sangfor::scp::custom::api' => (
        override => [
            request_api => sub {
                my ($self, %options) = @_;
                my ($page) = map { /^page_num=(\d+)$/ ? $1 : () } @{$options{get_param}};
                push @pages, $page;
                return $options{endpoint} eq '/list'
                    ? [ { id => 'a' } ]
                    : { total_size => 3, page_num => $page, next_page_num => $page == 0 ? '1' : '', data => $page == 0 ? [ { id => 'a' }, { id => 'b' } ] : [ { id => 'c' } ] };
            }
        ]
    );

    is($api->request_api_list(endpoint => '/paginated', get_param => [ 'az_id=1' ]), [ { id => 'a' }, { id => 'b' }, { id => 'c' } ], 'pages are concatenated');
    is(\@pages, [ 0, 1 ], 'next_page_num is followed');

    @pages = ();
    is($api->request_api_list(endpoint => '/list'), [ { id => 'a' } ], 'a list response is returned as is');
    is(\@pages, [ 0 ], 'a list response is requested once');
};

subtest 'password encryption' => sub {
    skip_all 'Crypt::OpenSSL::RSA is not installed'
        unless eval { require Crypt::OpenSSL::RSA; require Crypt::OpenSSL::Bignum; 1 };

    my $rsa = Crypt::OpenSSL::RSA->generate_key(2048);
    my ($modulus) = $rsa->get_key_parameters();
    foreach my $version ('v1', 'v2') {
        my $api = new_api(api_password => 'C3POR2P2', auth_version => $version);
        my $encrypted = $api->encrypt_password(modulus => $modulus->to_hex());
        like($encrypted, qr/^[0-9a-f]{512}$/, "$version: encrypted password is hexadecimal");

        # recent Crypt::OpenSSL::RSA versions refuse the PKCS#1 v1.5 decryption (only needed by this test)
        my $decrypted = eval {
            $version eq 'v2' ? $rsa->use_pkcs1_oaep_padding() : $rsa->use_pkcs1_padding();
            $rsa->decrypt(pack('H*', $encrypted));
        };
        if (!defined($decrypted) && $version eq 'v1') {
            note "PKCS#1 v1.5 decryption not available: $@";
            next;
        }
        is($decrypted, 'C3POR2P2', "$version: password can be decrypted");
    }
};

done_testing();
