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
Cpu ${tc}
    [Tags]    cloud    sangfor    cluster
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
    ...    OK: All clusters CPU usages are ok | 'cluster-prod#cluster.cpu.utilization.percentage'=10.34%;;;0;100 'cluster-prod#cluster.cpu.utilization.mhz'=29710.45MHz;;;0;287462.28 'cluster-lab#cluster.cpu.utilization.percentage'=46.00%;;;0;100 'cluster-lab#cluster.cpu.utilization.mhz'=44062.61MHz;;;0;95788.28
    ...    2
    ...    --id=c1d2e3f4-0000-4000-8000-000000000001 --warning-cpu-usage-prct=5
    ...    WARNING: Cluster 'cluster-prod' CPU usage: 10.34 % | 'cluster-prod#cluster.cpu.utilization.percentage'=10.34%;0:5;;0;100 'cluster-prod#cluster.cpu.utilization.mhz'=29710.45MHz;;;0;287462.28
