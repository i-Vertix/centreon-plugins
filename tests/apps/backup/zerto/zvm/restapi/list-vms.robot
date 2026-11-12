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
...                 --mode=list-vms
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
List Vms ${tc}
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
    ...    List VMs: [id: srv-0001.vm-201][name: erp-db01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000002][vpg_name: erp-database][status: RpoNotMeetingSLA][substatus: DeltaSync][priority: Medium] [id: srv-0001.vm-301][name: fs01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000003][vpg_name: file-server][status: NotMeetingSLA][substatus: JournalStorageError][priority: Medium] [id: srv-0001.vm-101][name: web01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000001][vpg_name: web-frontend][status: MeetingSLA][substatus: None][priority: Medium] [id: srv-0001.vm-102][name: web02][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000001][vpg_name: web-frontend][status: MeetingSLA][substatus: None][priority: Medium]
    ...    2
    ...    --include-name=web
    ...    List VMs: [id: srv-0001.vm-101][name: web01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000001][vpg_name: web-frontend][status: MeetingSLA][substatus: None][priority: Medium] [id: srv-0001.vm-102][name: web02][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000001][vpg_name: web-frontend][status: MeetingSLA][substatus: None][priority: Medium]
    ...    3
    ...    --include-vpg-id=b7e4a2c1-0000-4d3e-9f10-000000000002
    ...    List VMs: [id: srv-0001.vm-201][name: erp-db01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000002][vpg_name: erp-database][status: RpoNotMeetingSLA][substatus: DeltaSync][priority: Medium]
    ...    4
    ...    --exclude-vpg=web
    ...    List VMs: [id: srv-0001.vm-201][name: erp-db01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000002][vpg_name: erp-database][status: RpoNotMeetingSLA][substatus: DeltaSync][priority: Medium] [id: srv-0001.vm-301][name: fs01][vpg_id: b7e4a2c1-0000-4d3e-9f10-000000000003][vpg_name: file-server][status: NotMeetingSLA][substatus: JournalStorageError][priority: Medium]
