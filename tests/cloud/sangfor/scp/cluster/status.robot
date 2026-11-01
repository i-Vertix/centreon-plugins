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
Status ${tc}
    [Tags]    cloud    sangfor    cluster
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
    ...    CRITICAL: Cluster 'cluster-lab' status: master_offline [type: hci] [version: 6.7.0]
    ...    2
    ...    --resource-pool-id=a1b2c3d4-0000-4000-8000-000000000002
    ...    CRITICAL: Cluster 'cluster-lab' status: master_offline [type: hci] [version: 6.7.0]
    ...    3
    ...    --include-name=prod
    ...    OK: Cluster 'cluster-prod' status: normal [type: hci] [version: 6.8.0]
    ...    4
    ...    --exclude-name=prod --critical-status='\\\%{status} eq "offline"'
    ...    OK: Cluster 'cluster-lab' status: master_offline [type: hci] [version: 6.7.0]
