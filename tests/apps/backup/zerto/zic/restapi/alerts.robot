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
...                 --mode=alerts
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
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
    ...    WARNING: 3 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.vpg.count'=2;;;0;3 'alerts.zic.count'=1;;;0;3 'alerts.problems.current.count'=3;;;0;
    ...    2
    ...    --include-entity=ZIC
    ...    WARNING: 1 problem(s) detected | 'alerts.total.count'=1;;;0; 'alerts.vpg.count'=0;;;0;1 'alerts.zic.count'=1;;;0;1 'alerts.problems.current.count'=1;;;0;
    ...    3
    ...    --exclude-type=RPO
    ...    WARNING: 2 problem(s) detected | 'alerts.total.count'=2;;;0; 'alerts.vpg.count'=1;;;0;2 'alerts.zic.count'=1;;;0;2 'alerts.problems.current.count'=2;;;0;
    ...    4
    ...    --include-vpg-id='^vpg-0003\\\\z'
    ...    WARNING: 1 problem(s) detected | 'alerts.total.count'=1;;;0; 'alerts.vpg.count'=1;;;0;1 'alerts.zic.count'=0;;;0;1 'alerts.problems.current.count'=1;;;0;
    ...    5
    ...    --warning-status=''
    ...    OK: Alerts total: 3 - 0 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.vpg.count'=2;;;0;3 'alerts.zic.count'=1;;;0;3 'alerts.problems.current.count'=0;;;0;
    ...    6
    ...    --warning-status='' --critical-status='%\\\{type\\\} =~ /NeedsConfig/'
    ...    CRITICAL: 1 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.vpg.count'=2;;;0;3 'alerts.zic.count'=1;;;0;3 'alerts.problems.current.count'=1;;;0;
    ...    7
    ...    --critical-alerts-total=2
    ...    CRITICAL: Alerts total: 3 WARNING: 3 problem(s) detected | 'alerts.total.count'=3;;0:2;0; 'alerts.vpg.count'=2;;;0;3 'alerts.zic.count'=1;;;0;3 'alerts.problems.current.count'=3;;;0;
    ...    8
    ...    --warning-alerts-zic=0
    ...    WARNING: Alerts ZIC: 1 - 3 problem(s) detected | 'alerts.total.count'=3;;;0; 'alerts.vpg.count'=2;;;0;3 'alerts.zic.count'=1;0:0;;0;3 'alerts.problems.current.count'=3;;;0;
