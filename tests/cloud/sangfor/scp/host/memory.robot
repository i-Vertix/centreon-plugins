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
Memory ${tc}
    [Tags]    cloud    sangfor    host
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --id=host-0a1b2c3d4e01
    ...    OK: Host '192.0.2.11' Memory total: 32.00 GB used: 16.64 GB (52.00%) free: 15.36 GB (48.00%) | '192.0.2.11#host.memory.usage.bytes'=17867063951B;;;0;34359738368 '192.0.2.11#host.memory.free.bytes'=16492674416B;;;0;34359738368 '192.0.2.11#host.memory.usage.percentage'=52.00%;;;0;100
    ...    2
    ...    --exclude-name=11 --warning-memory-usage-prct=50
    ...    WARNING: Host '192.0.2.12' Memory total: 32.00 GB used: 18.88 GB (59.00%) free: 13.12 GB (41.00%) | '192.0.2.12#host.memory.usage.bytes'=20272245637B;;;0;34359738368 '192.0.2.12#host.memory.free.bytes'=14087492730B;;;0;34359738368 '192.0.2.12#host.memory.usage.percentage'=59.00%;0:50;;0;100
