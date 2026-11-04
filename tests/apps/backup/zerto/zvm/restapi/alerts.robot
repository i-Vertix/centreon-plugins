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
...                 --mode=alerts
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Alerts ${tc}
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
    ...    CRITICAL: 3 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.warning.count'=2;;;0;3 'alerts.error.count'=1;;;0;3 'alerts.problems.current.count'=3;;;0;
    ...    2
    ...    --include-dismissed
    ...    CRITICAL: 4 problem(s) detected | 'alerts.total.count'=4;;;0; 'alerts.warning.count'=3;;;0;4 'alerts.error.count'=1;;;0;4 'alerts.problems.current.count'=4;;;0;
    ...    3
    ...    --include-entity=Vpg
    ...    WARNING: 1 problem(s) detected | 'alerts.total.count'=1;;;0; 'alerts.warning.count'=1;;;0;1 'alerts.error.count'=0;;;0;1 'alerts.problems.current.count'=1;;;0;
    ...    4
    ...    --exclude-help-id=ZVM0006
    ...    CRITICAL: 2 problem(s) detected | 'alerts.total.count'=2;;;0; 'alerts.warning.count'=1;;;0;2 'alerts.error.count'=1;;;0;2 'alerts.problems.current.count'=2;;;0;
    ...    5
    ...    --include-vpg-id=0002
    ...    WARNING: 1 problem(s) detected | 'alerts.total.count'=1;;;0; 'alerts.warning.count'=1;;;0;1 'alerts.error.count'=0;;;0;1 'alerts.problems.current.count'=1;;;0;
    ...    6
    ...    --warning-status='' --critical-status=''
    ...    OK: Alerts total: 3 - 0 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.warning.count'=2;;;0;3 'alerts.error.count'=1;;;0;3 'alerts.problems.current.count'=0;;;0;
    ...    7
    ...    --critical-status='' --warning-status='%\\\{help_id\\\} =~ /VRA/'
    ...    WARNING: 1 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.warning.count'=2;;;0;3 'alerts.error.count'=1;;;0;3 'alerts.problems.current.count'=1;;;0;
    ...    8
    ...    --critical-alerts-error=0
    ...    CRITICAL: Alerts error: 1 - 3 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.warning.count'=2;;;0;3 'alerts.error.count'=1;;0:0;0;3 'alerts.problems.current.count'=3;;;0;
    ...    9
    ...    --memory --statefile-dir=/dev/shm/
    ...    CRITICAL: 3 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.warning.count'=2;;;0;3 'alerts.error.count'=1;;;0;3 'alerts.problems.current.count'=3;;;0;
    ...    10
    ...    --memory --statefile-dir=/dev/shm/
    ...    OK: Alerts total: 0 - 0 problem(s) detected | 'alerts.total.count'=0;;;0; 'alerts.warning.count'=0;;;0;0 'alerts.error.count'=0;;;0;0 'alerts.problems.current.count'=0;;;0;
