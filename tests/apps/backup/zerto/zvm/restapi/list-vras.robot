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
...                 --mode=list-vras
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
List Vras ${tc}
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
    ...    List VRAs: [id: 1001][name: Z-VRA-esx01.example][status: Installed][alert_status: Normal][group: default_group][ip_address: 192.0.2.21][vra_version: 10.9.0][host_version: 8.0.3] [id: 1002][name: Z-VRA-esx02.example][status: HostInMaintenanceMode][alert_status: Warning][group: default_group][ip_address: 192.0.2.22][vra_version: 10.9.0][host_version: 8.0.3] [id: 1003][name: Z-VRA-esx03.example][status: HostPasswordChanged][alert_status: Error][group: dr_group][ip_address: 192.0.2.23][vra_version: 10.9.0][host_version: 8.0.3]
    ...    2
    ...    --include-name=e
    ...    List VRAs: [id: 1001][name: Z-VRA-esx01.example][status: Installed][alert_status: Normal][group: default_group][ip_address: 192.0.2.21][vra_version: 10.9.0][host_version: 8.0.3] [id: 1002][name: Z-VRA-esx02.example][status: HostInMaintenanceMode][alert_status: Warning][group: default_group][ip_address: 192.0.2.22][vra_version: 10.9.0][host_version: 8.0.3] [id: 1003][name: Z-VRA-esx03.example][status: HostPasswordChanged][alert_status: Error][group: dr_group][ip_address: 192.0.2.23][vra_version: 10.9.0][host_version: 8.0.3]
