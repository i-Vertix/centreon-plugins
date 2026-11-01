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
Storage ${tc}
    [Tags]    cloud    sangfor    resourcepool
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All resource pools storage usages are ok | 'pool-prod#resourcepool.storage.space.usage.bytes'=181777989632B;;;0;3285649981440 'pool-prod#resourcepool.storage.space.free.bytes'=3103871991808B;;;0;3285649981440 'pool-prod#resourcepool.storage.space.usage.percentage'=5.53%;;;0;100 'pool-lab#resourcepool.storage.space.usage.bytes'=163919691776B;;;0;2993562845184 'pool-lab#resourcepool.storage.space.free.bytes'=2829643153408B;;;0;2993562845184 'pool-lab#resourcepool.storage.space.usage.percentage'=5.48%;;;0;100
    ...    2
    ...    --id=a1b2c3d4-0000-4000-8000-000000000002 --warning-space-usage-prct=5
    ...    WARNING: Resource pool 'pool-lab' Storage total: 2.72 TB used: 152.66 GB (5.48%) free: 2.57 TB (94.52%) | 'pool-lab#resourcepool.storage.space.usage.bytes'=163919691776B;;;0;2993562845184 'pool-lab#resourcepool.storage.space.free.bytes'=2829643153408B;;;0;2993562845184 'pool-lab#resourcepool.storage.space.usage.percentage'=5.48%;0:5;;0;100
