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
...                 --mode=discovery
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
...                 --client-secret=secret-123

${EXPECTED_RESULT}
...    SEPARATOR=
...    {"discovered_items":3,"duration":1,"end_time":1793492696,"results":[{"description":"","hostname":"12
...    7.0.0.1","id":"vpg-0002","name":"erp-database","protected_account":"111111111111","protected_region"
...    :"us-east-1","protected_vms":2,"protection_status":"RpoNotMeetingSLA","recovery_account":"2222222222
...    22","recovery_region":"eu-central-1","state":"Protecting"},{"description":"","hostname":"127.0.0.1",
...    "id":"vpg-0003","name":"file-server","protected_account":"111111111111","protected_region":"us-east-
...    1","protected_vms":1,"protection_status":"Initializing","recovery_account":"222222222222","recovery_
...    region":"eu-central-1","state":"NeedsConfiguration"},{"description":"","hostname":"127.0.0.1","id":"
...    vpg-0001","name":"web-frontend","protected_account":"111111111111","protected_region":"us-east-1","p
...    rotected_vms":3,"protection_status":"MeetingSLA","recovery_account":"222222222222","recovery_region"
...    :"eu-central-1","state":"Protecting"}],"start_time":1793492695}


*** Test Cases ***
Discovery
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${CMD}

    Ctn Run Command And Check Result As Json
    ...    ${command}
    ...    ${EXPECTED_RESULT}
