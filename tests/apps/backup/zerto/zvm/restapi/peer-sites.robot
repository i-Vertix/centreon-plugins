*** Settings ***
Documentation       apps::backup::zerto::zvm::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}zvm.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::zerto::zvm::restapi::plugin
...                 --mode=peer-sites
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123
${BASE}             ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::zerto::zvm::restapi::plugin
...                 --mode=peer-sites
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Peer Sites ${tc}
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: Peer site 'site-c' pairing status: Unpaired, version: 10.0.70 | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;
    ...    2
    ...    --include-name=site-b
    ...    OK: Peer sites total: 1 - Peer site 'site-b' pairing status: Paired, version: 10.9.0, incoming throughput: 25.50 Mb/s, used storage: 170.00 GB | 'peersites.total.count'=1;;;0; 'peersites.paired.count'=1;;;0;1 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0;
    ...    3
    ...    --critical-status=''
    ...    OK: Peer sites total: 2 - All peer sites are ok | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;
    ...    4
    ...    --critical-status='' --warning-status='%\\\{version\\\} !~ /^10[.]9/'
    ...    WARNING: Peer site 'site-c' pairing status: Unpaired, version: 10.0.70 | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;
    ...    5
    ...    --warning-incoming-throughput=20000000
    ...    CRITICAL: Peer site 'site-c' pairing status: Unpaired, version: 10.0.70 WARNING: Peer site 'site-b' incoming throughput: 25.50 Mb/s | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;0:20000000;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;0:20000000;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;
    ...    6
    ...    --critical-sites-paired=2:
    ...    CRITICAL: Peer sites paired: 1 - Peer site 'site-c' pairing status: Unpaired, version: 10.0.70 | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;2:;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;

Authentication ${tc}
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${BASE}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --auth-type=session --username=monitor --password=pass-123
    ...    CRITICAL: Peer site 'site-c' pairing status: Unpaired, version: 10.0.70 | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;
    ...    2
    ...    --client-id=zvm-monitoring --username=monitor --password=pass-123
    ...    CRITICAL: Peer site 'site-c' pairing status: Unpaired, version: 10.0.70 | 'peersites.total.count'=2;;;0; 'peersites.paired.count'=1;;;0;2 'site-b#peersite.throughput.incoming.bitspersecond'=25500000b/s;;;0; 'site-b#peersite.storage.provisioned.bytes'=429496729600B;;;0; 'site-b#peersite.storage.used.bytes'=182536110080B;;;0; 'site-c#peersite.throughput.incoming.bitspersecond'=0b/s;;;0; 'site-c#peersite.storage.provisioned.bytes'=0B;;;0; 'site-c#peersite.storage.used.bytes'=0B;;;0;
    ...    3
    ...    --auth-type=session --username=monitor --password=wrong
    ...    UNKNOWN: Cannot get session [code: '401'] [message: 'Unauthorized']
    ...    4
    ...    --client-id=zvm-monitoring --client-secret=wrong
    ...    UNKNOWN: Authentication endpoint returns error 'unauthorized_client' (add --debug option for detailed message)
    ...    5
    ...    --auth-type=session
    ...    UNKNOWN: Need to specify --username and --password options.
    ...    6
    ...    --client-id=zvm-monitoring
    ...    UNKNOWN: Need to specify --client-secret option (or --username and --password).
    ...    7
    ...    --auth-type=other --client-id=zvm-monitoring --client-secret=secret-123
    ...    UNKNOWN: Bad value provided for option auth-type: 'other'. Constraint 'other' is_in 'keycloak, session' is not verified.
