*** Settings ***
Documentation       cloud::sangfor::scp::vm::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::vm::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Status ${tc}
    [Tags]    cloud    sangfor    vm
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
    ...    CRITICAL: VM 'test-01' status: stopped, power state: off, alarm: no | 'web-01#vm.uptime.seconds'=5797965s;;;0; 'db-01#vm.uptime.seconds'=86400s;;;0; 'test-01#vm.uptime.seconds'=0s;;;0;
    ...    2
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002
    ...    OK: VM 'db-01' status: running, power state: on, alarm: yes, uptime: 1d | 'db-01#vm.uptime.seconds'=86400s;;;0;
    ...    3
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002 --warning-status='\\\%{alarm} eq "yes"'
    ...    WARNING: VM 'db-01' status: running, power state: on, alarm: yes | 'db-01#vm.uptime.seconds'=86400s;;;0;
    ...    4
    ...    --include-name=web --warning-status='\\\%{warning} ne "no"'
    ...    WARNING: VM 'web-01' status: running, power state: on, alarm: no, warning: vmTools is not installed on the VM | 'web-01#vm.uptime.seconds'=5797965s;;;0;
    ...    5
    ...    --id=unknown
    ...    UNKNOWN: No VM found.
