*** Settings ***
Documentation       cloud::sangfor::scp::storage::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::storage::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Status ${tc}
    [Tags]    cloud    sangfor    storage
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
    ...    CRITICAL: Storage 'node1_local' status: offline [type: local] WARNING: Storage 'iscsi-01' status: alarm [type: iscsi]
    ...    2
    ...    --include-type=vs
    ...    OK: Storage 'datastore-vs' status: ok [type: vs]
    ...    3
    ...    --include-name=iscsi --warning-status=''
    ...    OK: Storage 'iscsi-01' status: alarm [type: iscsi]
