*** Settings ***
Documentation       cloud::sangfor::scp::resourcepool::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::resourcepool::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Cpu ${tc}
    [Tags]    cloud    sangfor    resourcepool
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
    ...    OK: All resource pools CPU usages are ok | 'pool-prod#resourcepool.cpu.utilization.percentage'=26.33%;;;0;100 'pool-prod#resourcepool.cpu.utilization.mhz'=27743.74MHz;;;0;105355.97 'pool-lab#resourcepool.cpu.utilization.percentage'=46.67%;;;0;100 'pool-lab#resourcepool.cpu.utilization.mhz'=29051.74MHz;;;0;62253.72
    ...    2
    ...    --id=a1b2c3d4-0000-4000-8000-000000000002
    ...    OK: Resource pool 'pool-lab' CPU usage: 46.67 %, CPU used: 29051.74 MHz | 'pool-lab#resourcepool.cpu.utilization.percentage'=46.67%;;;0;100 'pool-lab#resourcepool.cpu.utilization.mhz'=29051.74MHz;;;0;62253.72
    ...    3
    ...    --id=a1b2c3d4-0000-4000-8000-000000000001 --warning-cpu-usage-prct=20
    ...    WARNING: Resource pool 'pool-prod' CPU usage: 26.33 % | 'pool-prod#resourcepool.cpu.utilization.percentage'=26.33%;0:20;;0;100 'pool-prod#resourcepool.cpu.utilization.mhz'=27743.74MHz;;;0;105355.97
    ...    4
    ...    --id=a1b2c3d4-0000-4000-8000-000000000001 --critical-cpu-usage=20000
    ...    CRITICAL: Resource pool 'pool-prod' CPU used: 27743.74 MHz | 'pool-prod#resourcepool.cpu.utilization.percentage'=26.33%;;;0;100 'pool-prod#resourcepool.cpu.utilization.mhz'=27743.74MHz;;0:20000;0;105355.97
