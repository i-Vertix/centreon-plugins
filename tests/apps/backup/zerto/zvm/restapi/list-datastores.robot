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
...                 --mode=list-datastores
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
List Datastores ${tc}
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
    ...    List datastores: [id: srv-0001.datastore-21][name: ds-dr-01][cluster: ][health_status: Normal][availability_status: InMaintenance] [id: srv-0001.datastore-11][name: ds-prod-01][cluster: dsc-prod][health_status: Normal][availability_status: Normal] [id: srv-0001.datastore-12][name: ds-prod-02][cluster: dsc-prod][health_status: Error][availability_status: Normal]
    ...    2
    ...    --include-name=e
    ...    List datastores:
