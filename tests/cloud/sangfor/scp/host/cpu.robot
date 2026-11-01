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
Cpu ${tc}
    [Tags]    cloud    sangfor    host
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All hosts CPU usages are ok | '192.0.2.11#host.cpu.utilization.percentage'=45.00%;;;0;100 '192.0.2.11#host.cpu.utilization.mhz'=11883.60MHz;;;0;26408 '192.0.2.12#host.cpu.utilization.percentage'=49.00%;;;0;100 '192.0.2.12#host.cpu.utilization.mhz'=12939.92MHz;;;0;26408
    ...    2
    ...    --id=host-0a1b2c3d4e01 --critical-cpu-usage-prct=40
    ...    CRITICAL: Host '192.0.2.11' CPU usage: 45.00 % | '192.0.2.11#host.cpu.utilization.percentage'=45.00%;;0:40;0;100 '192.0.2.11#host.cpu.utilization.mhz'=11883.60MHz;;;0;26408
