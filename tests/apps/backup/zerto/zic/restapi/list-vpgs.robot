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
...                 --mode=list-vpgs
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
List Vpgs ${tc}
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
    ...    List VPGs: [id: vpg-0002][name: erp-database][state: Protecting][protection_status: RpoNotMeetingSLA][protected_account: 111111111111][protected_region: us-east-1][recovery_account: 222222222222][recovery_region: eu-central-1] [id: vpg-0003][name: file-server][state: NeedsConfiguration][protection_status: Initializing][protected_account: 111111111111][protected_region: us-east-1][recovery_account: 222222222222][recovery_region: eu-central-1] [id: vpg-0001][name: web-frontend][state: Protecting][protection_status: MeetingSLA][protected_account: 111111111111][protected_region: us-east-1][recovery_account: 222222222222][recovery_region: eu-central-1]
    ...    2
    ...    --exclude-name=web
    ...    List VPGs: [id: vpg-0002][name: erp-database][state: Protecting][protection_status: RpoNotMeetingSLA][protected_account: 111111111111][protected_region: us-east-1][recovery_account: 222222222222][recovery_region: eu-central-1] [id: vpg-0003][name: file-server][state: NeedsConfiguration][protection_status: Initializing][protected_account: 111111111111][protected_region: us-east-1][recovery_account: 222222222222][recovery_region: eu-central-1]
