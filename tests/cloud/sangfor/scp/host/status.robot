*** Settings ***
Documentation       cloud::sangfor::scp::host::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::host::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Status ${tc}
    [Tags]    cloud    sangfor    host
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=status
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: Host '192.0.2.12' status: offline [ip: 192.0.2.12] | '192.0.2.11#host.alarms.count'=0;;;0; '192.0.2.12#host.alarms.count'=2;;;0;
    ...    2
    ...    --id=host-0a1b2c3d4e01
    ...    OK: Host '192.0.2.11' status: running [ip: 192.0.2.11], alarms: 0 | '192.0.2.11#host.alarms.count'=0;;;0;
    ...    3
    ...    --id=host-0a1b2c3d4e02 --critical-status='' --warning-alarms=1
    ...    WARNING: Host '192.0.2.12' alarms: 2 | '192.0.2.12#host.alarms.count'=2;0:1;;0;
