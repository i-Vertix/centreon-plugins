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
Storage ${tc}
    [Tags]    cloud    sangfor    cluster
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
    ...    OK: All clusters storage usages are ok | 'cluster-prod#cluster.storage.space.usage.bytes'=1609958424576B;;;0;24687427977216 'cluster-prod#cluster.storage.space.free.bytes'=23077469552640B;;;0;24687427977216 'cluster-prod#cluster.storage.space.usage.percentage'=6.52%;;;0;100 'cluster-lab#cluster.storage.space.usage.bytes'=3088649814016B;;;0;4088855003136 'cluster-lab#cluster.storage.space.free.bytes'=1000205189120B;;;0;4088855003136 'cluster-lab#cluster.storage.space.usage.percentage'=75.54%;;;0;100
    ...    2
    ...    --include-name=prod --warning-space-usage-prct=5
    ...    WARNING: Cluster 'cluster-prod' Storage total: 22.45 TB used: 1.46 TB (6.52%) free: 20.99 TB (93.48%) | 'cluster-prod#cluster.storage.space.usage.bytes'=1609958424576B;;;0;24687427977216 'cluster-prod#cluster.storage.space.free.bytes'=23077469552640B;;;0;24687427977216 'cluster-prod#cluster.storage.space.usage.percentage'=6.52%;0:5;;0;100
