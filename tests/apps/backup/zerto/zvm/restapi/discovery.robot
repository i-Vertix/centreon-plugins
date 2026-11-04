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
...                 --mode=discovery
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123

${EXPECTED_RESULT}
...    SEPARATOR=
...    {"discovered_items":4,"duration":0,"end_time":1793783806,"results":[{"configured_rpo":600,"hostname"
...    :"127.0.0.1","id":"b7e4a2c1-0000-4d3e-9f10-000000000004","name":"archive","organization":"","priorit
...    y":"Low","protected_site_id":"f2a1c3d4-1111-4a5b-8c6d-000000000001","protected_vms":1,"recovery_site
...    _id":"f2a1c3d4-2222-4a5b-8c6d-000000000002","service_profile":"","status":"Initializing"},{"configur
...    ed_rpo":300,"hostname":"127.0.0.1","id":"b7e4a2c1-0000-4d3e-9f10-000000000002","name":"erp-database"
...    ,"organization":"","priority":"High","protected_site_id":"f2a1c3d4-1111-4a5b-8c6d-000000000001","pro
...    tected_vms":2,"recovery_site_id":"f2a1c3d4-2222-4a5b-8c6d-000000000002","service_profile":"","status
...    ":"RpoNotMeetingSLA"},{"configured_rpo":300,"hostname":"127.0.0.1","id":"b7e4a2c1-0000-4d3e-9f10-000
...    000000003","name":"file-server","organization":"","priority":"Low","protected_site_id":"f2a1c3d4-111
...    1-4a5b-8c6d-000000000001","protected_vms":1,"recovery_site_id":"f2a1c3d4-2222-4a5b-8c6d-000000000002
...    ","service_profile":"","status":"NotMeetingSLA"},{"configured_rpo":300,"hostname":"127.0.0.1","id":"
...    b7e4a2c1-0000-4d3e-9f10-000000000001","name":"web-frontend","organization":"","priority":"Medium","p
...    rotected_site_id":"f2a1c3d4-1111-4a5b-8c6d-000000000001","protected_vms":3,"recovery_site_id":"f2a1c
...    3d4-2222-4a5b-8c6d-000000000002","service_profile":"","status":"MeetingSLA"}],"start_time":179378380
...    6}


*** Test Cases ***
Discovery
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${CMD}

    Ctn Run Command And Check Result As Json
    ...    ${command}
    ...    ${EXPECTED_RESULT}
