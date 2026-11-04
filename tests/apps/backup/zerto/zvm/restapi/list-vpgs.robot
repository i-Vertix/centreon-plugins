*** Settings ***
Documentation       apps::backup::zerto::zvm::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}zvm.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::zerto::zvm::restapi::plugin
...                 --mode=list-vpgs
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
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
    ...    List VPGs: [id: b7e4a2c1-0000-4d3e-9f10-000000000004][name: archive][status: Initializing][substatus: InitialSync][priority: Low][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 1] [id: b7e4a2c1-0000-4d3e-9f10-000000000002][name: erp-database][status: RpoNotMeetingSLA][substatus: DeltaSync][priority: High][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 2] [id: b7e4a2c1-0000-4d3e-9f10-000000000003][name: file-server][status: NotMeetingSLA][substatus: JournalStorageError][priority: Low][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 1] [id: b7e4a2c1-0000-4d3e-9f10-000000000001][name: web-frontend][status: MeetingSLA][substatus: None][priority: Medium][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 3]
    ...    2
    ...    --include-name=e
    ...    List VPGs: [id: b7e4a2c1-0000-4d3e-9f10-000000000004][name: archive][status: Initializing][substatus: InitialSync][priority: Low][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 1] [id: b7e4a2c1-0000-4d3e-9f10-000000000002][name: erp-database][status: RpoNotMeetingSLA][substatus: DeltaSync][priority: High][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 2] [id: b7e4a2c1-0000-4d3e-9f10-000000000003][name: file-server][status: NotMeetingSLA][substatus: JournalStorageError][priority: Low][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 1] [id: b7e4a2c1-0000-4d3e-9f10-000000000001][name: web-frontend][status: MeetingSLA][substatus: None][priority: Medium][protected_site_id: f2a1c3d4-1111-4a5b-8c6d-000000000001][recovery_site_id: f2a1c3d4-2222-4a5b-8c6d-000000000002][protected_vms: 3]
