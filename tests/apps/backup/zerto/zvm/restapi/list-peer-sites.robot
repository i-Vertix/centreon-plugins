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
...                 --mode=list-peer-sites
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
List Peer Sites ${tc}
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
    ...    List peer sites: [id: f2a1c3d4-2222-4a5b-8c6d-000000000002][name: site-b][hostname: zvm-b.example][port: 9071][location: Datacenter B][pairing_status: Paired][version: 10.9.0] [id: f2a1c3d4-3333-4a5b-8c6d-000000000003][name: site-c][hostname: 198.51.100.30][port: 9071][location: Datacenter C][pairing_status: Unpaired][version: 10.0.70]
    ...    2
    ...    --include-name=e
    ...    List peer sites: [id: f2a1c3d4-2222-4a5b-8c6d-000000000002][name: site-b][hostname: zvm-b.example][port: 9071][location: Datacenter B][pairing_status: Paired][version: 10.9.0] [id: f2a1c3d4-3333-4a5b-8c6d-000000000003][name: site-c][hostname: 198.51.100.30][port: 9071][location: Datacenter C][pairing_status: Unpaired][version: 10.0.70]
