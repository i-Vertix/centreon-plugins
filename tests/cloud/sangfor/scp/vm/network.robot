*** Settings ***
Documentation       cloud::sangfor::scp::vm::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::vm::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Network ${tc}
    [Tags]    cloud    sangfor    vm
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=network
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002
    ...    OK: VM 'db-01' traffic in: 12.00 Mb/s, traffic out: 8.00 Mb/s | 'db-01#vm.network.traffic.in.bitspersecond'=12000000b/s;;;0; 'db-01#vm.network.traffic.out.bitspersecond'=8000000b/s;;;0;
    ...    2
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002 --warning-traffic-in=10000000
    ...    WARNING: VM 'db-01' traffic in: 12.00 Mb/s | 'db-01#vm.network.traffic.in.bitspersecond'=12000000b/s;0:10000000;;0; 'db-01#vm.network.traffic.out.bitspersecond'=8000000b/s;;;0;
