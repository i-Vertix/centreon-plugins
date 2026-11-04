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
...                 --mode=tasks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Tasks ${tc}
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
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=4;;;0; 'tasks.running.count'=1;;;0;4 'tasks.completed.count'=1;;;0;4 'tasks.failed.count'=1;;;0;4 'tasks.problems.current.count'=2;;;0;
    ...    2
    ...    --timeframe=''
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=5;;;0; 'tasks.running.count'=1;;;0;5 'tasks.completed.count'=2;;;0;5 'tasks.failed.count'=1;;;0;5 'tasks.problems.current.count'=2;;;0;
    ...    3
    ...    --include-type=FailOverTest
    ...    OK: Tasks total: 1, running: 1, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=1;;;0; 'tasks.running.count'=1;;;0;1 'tasks.completed.count'=0;;;0;1 'tasks.failed.count'=0;;;0;1 'tasks.problems.current.count'=0;;;0;
    ...    4
    ...    --exclude-type='InstallVra|InitFullSync'
    ...    OK: Tasks total: 2, running: 1, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=2;;;0; 'tasks.running.count'=1;;;0;2 'tasks.completed.count'=1;;;0;2 'tasks.failed.count'=0;;;0;2 'tasks.problems.current.count'=0;;;0;
    ...    5
    ...    --include-vpg-id=0003
    ...    WARNING: 1 problem(s) detected | 'tasks.total.count'=1;;;0; 'tasks.running.count'=0;;;0;1 'tasks.completed.count'=0;;;0;1 'tasks.failed.count'=0;;;0;1 'tasks.problems.current.count'=1;;;0;
    ...    6
    ...    --warning-tasks-running=0
    ...    CRITICAL: 2 problem(s) detected WARNING: Tasks running: 1 | 'tasks.total.count'=4;;;0; 'tasks.running.count'=1;0:0;;0;4 'tasks.completed.count'=1;;;0;4 'tasks.failed.count'=1;;;0;4 'tasks.problems.current.count'=2;;;0;
    ...    7
    ...    --warning-status='' --critical-status='%\\\{state\\\} =~ /InProgress/'
    ...    CRITICAL: 1 problem(s) detected | 'tasks.total.count'=4;;;0; 'tasks.running.count'=1;;;0;4 'tasks.completed.count'=1;;;0;4 'tasks.failed.count'=1;;;0;4 'tasks.problems.current.count'=1;;;0;
    ...    8
    ...    --memory --statefile-dir=/dev/shm/
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=4;;;0; 'tasks.running.count'=1;;;0;4 'tasks.completed.count'=1;;;0;4 'tasks.failed.count'=1;;;0;4 'tasks.problems.current.count'=2;;;0;
    ...    9
    ...    --memory --statefile-dir=/dev/shm/
    ...    OK: Tasks total: 1, running: 1, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=1;;;0; 'tasks.running.count'=1;;;0;1 'tasks.completed.count'=0;;;0;1 'tasks.failed.count'=0;;;0;1 'tasks.problems.current.count'=0;;;0;
