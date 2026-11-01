*** Settings ***
Documentation       cloud::sangfor::scp::cluster::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::cluster::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Memory ${tc}
    [Tags]    cloud    sangfor    cluster
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
    ...    --id=c1d2e3f4-0000-4000-8000-000000000001
    ...    OK: Cluster 'cluster-prod' Memory total: 384.00 GB used: 103.16 GB (26.86%) free: 280.84 GB (73.14%) | 'cluster-prod#cluster.memory.usage.bytes'=110766420131B;;;0;412316860416 'cluster-prod#cluster.memory.free.bytes'=301550440284B;;;0;412316860416 'cluster-prod#cluster.memory.usage.percentage'=26.86%;;;0;100
    ...    2
    ...    --include-name=lab --critical-memory-usage-prct=45
    ...    CRITICAL: Cluster 'cluster-lab' Memory total: 256.00 GB used: 128.00 GB (50.00%) free: 128.00 GB (50.00%) | 'cluster-lab#cluster.memory.usage.bytes'=137438953472B;;;0;274877906944 'cluster-lab#cluster.memory.free.bytes'=137438953472B;;;0;274877906944 'cluster-lab#cluster.memory.usage.percentage'=50.00%;;0:45;0;100
