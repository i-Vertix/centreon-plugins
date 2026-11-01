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
Status ${tc}
    [Tags]    cloud    sangfor    resourcepool
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
    ...    CRITICAL: Resource pool 'pool-lab' status: offline [type: hci] [tag: public] [version: 6.8.0]
    ...    2
    ...    --include-name=prod
    ...    OK: Resource pool 'pool-prod' status: normal [type: hci] [tag: private] [version: 6.9.0]
    ...    3
    ...    --id=a1b2c3d4-0000-4000-8000-000000000002
    ...    CRITICAL: Resource pool 'pool-lab' status: offline [type: hci] [tag: public] [version: 6.8.0]
    ...    4
    ...    --include-name=prod --warning-status='\\\%{tag} eq "private"'
    ...    WARNING: Resource pool 'pool-prod' status: normal [type: hci] [tag: private] [version: 6.9.0]
