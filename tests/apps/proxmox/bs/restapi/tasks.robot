*** Settings ***
Documentation       apps::proxmox::bs::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}pbs.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::proxmox::bs::restapi::plugin
...                 --mode=tasks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123


*** Test Cases ***
Tasks ${tc}
    [Tags]    apps    proxmox    restapi
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
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=8;;;0; 'tasks.running.count'=1;;;0;8 'tasks.ok.count'=5;;;0;8 'tasks.warning.count'=1;;;0;8 'tasks.error.count'=1;;;0;8 'tasks.problems.current.count'=2;;;0;
    ...    2
    ...    --include-type='^backup$'
    ...    CRITICAL: 1 problem(s) detected | 'tasks.total.count'=4;;;0; 'tasks.running.count'=1;;;0;4 'tasks.ok.count'=2;;;0;4 'tasks.warning.count'=0;;;0;4 'tasks.error.count'=1;;;0;4 'tasks.problems.current.count'=1;;;0;
    ...    3
    ...    --exclude-type=backup
    ...    WARNING: 1 problem(s) detected | 'tasks.total.count'=4;;;0; 'tasks.running.count'=0;;;0;4 'tasks.ok.count'=3;;;0;4 'tasks.warning.count'=1;;;0;4 'tasks.error.count'=0;;;0;4 'tasks.problems.current.count'=1;;;0;
    ...    4
    ...    --include-id='store01:vm/10[01]'
    ...    OK: Tasks total: 2, running: 0, ok: 2, with warnings: 0, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=2;;;0; 'tasks.running.count'=0;;;0;2 'tasks.ok.count'=2;;;0;2 'tasks.warning.count'=0;;;0;2 'tasks.error.count'=0;;;0;2 'tasks.problems.current.count'=0;;;0;
    ...    5
    ...    --include-user=sync
    ...    OK: Tasks total: 1, running: 0, ok: 1, with warnings: 0, failed: 0 - 0 problem(s) detected | 'tasks.total.count'=1;;;0; 'tasks.running.count'=0;;;0;1 'tasks.ok.count'=1;;;0;1 'tasks.warning.count'=0;;;0;1 'tasks.error.count'=0;;;0;1 'tasks.problems.current.count'=0;;;0;
    ...    6
    ...    --timeframe=''
    ...    CRITICAL: 2 problem(s) detected | 'tasks.total.count'=9;;;0; 'tasks.running.count'=1;;;0;9 'tasks.ok.count'=6;;;0;9 'tasks.warning.count'=1;;;0;9 'tasks.error.count'=1;;;0;9 'tasks.problems.current.count'=2;;;0;
    ...    7
    ...    --timeframe=9000
    ...    CRITICAL: 1 problem(s) detected | 'tasks.total.count'=3;;;0; 'tasks.running.count'=1;;;0;3 'tasks.ok.count'=1;;;0;3 'tasks.warning.count'=0;;;0;3 'tasks.error.count'=1;;;0;3 'tasks.problems.current.count'=1;;;0;
    ...    8
    ...    --warning-status='' --critical-status='' --warning-tasks-running=0
    ...    WARNING: Tasks running: 1 | 'tasks.total.count'=8;;;0; 'tasks.running.count'=1;0:0;;0;8 'tasks.ok.count'=5;;;0;8 'tasks.warning.count'=1;;;0;8 'tasks.error.count'=1;;;0;8 'tasks.problems.current.count'=0;;;0;
    ...    9
    ...    --warning-status='' --critical-status='' --critical-tasks-error=0
    ...    CRITICAL: Tasks failed: 1 | 'tasks.total.count'=8;;;0; 'tasks.running.count'=1;;;0;8 'tasks.ok.count'=5;;;0;8 'tasks.warning.count'=1;;;0;8 'tasks.error.count'=1;;0:0;0;8 'tasks.problems.current.count'=0;;;0;
    ...    10
    ...    --critical-status='' --warning-status='%\\\{type\\\} eq "prunejob" and %\\\{state\\\} eq "warning"'
    ...    WARNING: 1 problem(s) detected | 'tasks.total.count'=8;;;0; 'tasks.running.count'=1;;;0;8 'tasks.ok.count'=5;;;0;8 'tasks.warning.count'=1;;;0;8 'tasks.error.count'=1;;;0;8 'tasks.problems.current.count'=1;;;0;
