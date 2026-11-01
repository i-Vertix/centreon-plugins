*** Settings ***
Documentation       apps::backup::zerto::zic::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}zic.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::zerto::zic::restapi::plugin
...                 --mode=list-member-accounts
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
List Member Accounts ${tc}
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    List member accounts: [id: 111111111111][description: prod][status: Ready] [id: 222222222222][description: dr][status: NotReady]
    ...    2
    ...    --include-description=prod
    ...    List member accounts: [id: 111111111111][description: prod][status: Ready]
