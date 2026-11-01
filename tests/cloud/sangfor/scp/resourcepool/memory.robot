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
Memory ${tc}
    [Tags]    cloud    sangfor    resourcepool
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
    ...    --id=a1b2c3d4-0000-4000-8000-000000000001
    ...    OK: Resource pool 'pool-prod' Memory total: 96.00 GB used: 45.62 GB (47.52%) free: 50.38 GB (52.48%) | 'pool-prod#resourcepool.memory.usage.bytes'=48986838794B;;;0;103079215104 'pool-prod#resourcepool.memory.free.bytes'=54092376309B;;;0;103079215104 'pool-prod#resourcepool.memory.usage.percentage'=47.52%;;;0;100
    ...    2
    ...    --id=a1b2c3d4-0000-4000-8000-000000000002 --warning-memory-usage-prct=30
    ...    WARNING: Resource pool 'pool-lab' Memory total: 120.00 GB used: 48.88 GB (40.73%) free: 71.12 GB (59.27%) | 'pool-lab#resourcepool.memory.usage.bytes'=52485444075B;;;0;128849018880 'pool-lab#resourcepool.memory.free.bytes'=76363574804B;;;0;128849018880 'pool-lab#resourcepool.memory.usage.percentage'=40.73%;0:30;;0;100
    ...    3
    ...    --id=a1b2c3d4-0000-4000-8000-000000000001 --critical-memory-usage-free=60000000000:
    ...    CRITICAL: Resource pool 'pool-prod' Memory total: 96.00 GB used: 45.62 GB (47.52%) free: 50.38 GB (52.48%) | 'pool-prod#resourcepool.memory.usage.bytes'=48986838794B;;;0;103079215104 'pool-prod#resourcepool.memory.free.bytes'=54092376309B;;60000000000:;0;103079215104 'pool-prod#resourcepool.memory.usage.percentage'=47.52%;;;0;100
