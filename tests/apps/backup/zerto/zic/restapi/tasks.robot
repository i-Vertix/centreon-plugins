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
...                 --mode=tasks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
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
    ...    CRITICAL: 1 problem(s) detected | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;;;0;3 'tasks.success.count'=1;;;0;3 'tasks.failed.count'=1;;;0;3 'tasks.problems.current.count'=1;;;0;
    ...    2
    ...    --timeframe=''
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=4;;;0; 'tasks.running.count'=1;;;0;4 'tasks.success.count'=1;;;0;4 'tasks.failed.count'=2;;;0;4 'tasks.problems.current.count'=2;;;0;
    ...    3
    ...    --timeframe='' --exclude-operation=CreateMemberAccount
    ...    CRITICAL: 1 problem(s) detected | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;;;0;3 'tasks.success.count'=1;;;0;3 'tasks.failed.count'=1;;;0;3 'tasks.problems.current.count'=1;;;0;
    ...    4
    ...    --include-operation=FailoverTest
    ...    OK: Tasks total: 1, running: 1, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=1;;;0; 'tasks.running.count'=1;;;0;1 'tasks.success.count'=0;;;0;1 'tasks.failed.count'=0;;;0;1 'tasks.problems.current.count'=0;;;0;
    ...    5
    ...    --include-vpg-id='^vpg-0002\\\\z'
    ...    OK: Tasks total: 1, running: 0, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=1;;;0; 'tasks.running.count'=0;;;0;1 'tasks.success.count'=1;;;0;1 'tasks.failed.count'=0;;;0;1 'tasks.problems.current.count'=0;;;0;
    ...    6
    ...    --warning-status='%\\\{status\\\} =~ /Running/ && %\\\{elapsed\\\} > 3600'
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;;;0;3 'tasks.success.count'=1;;;0;3 'tasks.failed.count'=1;;;0;3 'tasks.problems.current.count'=2;;;0;
    ...    7
    ...    --critical-status=''
    ...    OK: Tasks total: 3, running: 1, failed: 1 - 0 problem(s) detected | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;;;0;3 'tasks.success.count'=1;;;0;3 'tasks.failed.count'=1;;;0;3 'tasks.problems.current.count'=0;;;0;
    ...    8
    ...    --critical-tasks-failed=0
    ...    CRITICAL: Tasks failed: 1 - 1 problem(s) detected | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;;;0;3 'tasks.success.count'=1;;;0;3 'tasks.failed.count'=1;;0:0;0;3 'tasks.problems.current.count'=1;;;0;
    ...    9
    ...    --warning-tasks-running=0
    ...    CRITICAL: 1 problem(s) detected WARNING: Tasks running: 1 | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;0:0;;0;3 'tasks.success.count'=1;;;0;3 'tasks.failed.count'=1;;;0;3 'tasks.problems.current.count'=1;;;0;
