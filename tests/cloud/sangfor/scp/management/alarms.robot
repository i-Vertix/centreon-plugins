*** Settings ***
Documentation       cloud::sangfor::scp::management::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::management::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Alarms ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=alarms
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: Alarm 'Host CPU usage' [severity: critical] [status: open] [object: host '192.0.2.12'] [since: 2026-10-30 17:30:46] The CPU usage of the node (192.0.2.12) is 96.35%, higher than 95%. WARNING: Alarm 'Virtual storage network bandwidth detection' [severity: low] [status: open] [object: storage 'datastore-vs'] [since: 2026-10-17 12:00:20] The storage network interface of the virtual datastore uses a gigabit network. | 'alarms.total.count'=3;;;0; 'alarms.critical.count'=1;;;0; 'alarms.medium.count'=1;;;0; 'alarms.low.count'=1;;;0;
    ...    2
    ...    --include-status=open --exclude-severity=low
    ...    CRITICAL: Alarm 'Host CPU usage' [severity: critical] [status: open] [object: host '192.0.2.12'] [since: 2026-10-30 17:30:46] The CPU usage of the node (192.0.2.12) is 96.35%, higher than 95%. | 'alarms.total.count'=1;;;0; 'alarms.critical.count'=1;;;0; 'alarms.medium.count'=0;;;0; 'alarms.low.count'=0;;;0;
    ...    3
    ...    --include-object-type=storage
    ...    WARNING: Alarm 'Virtual storage network bandwidth detection' [severity: low] [status: open] [object: storage 'datastore-vs'] [since: 2026-10-17 12:00:20] The storage network interface of the virtual datastore uses a gigabit network. | 'alarms.total.count'=1;;;0; 'alarms.critical.count'=0;;;0; 'alarms.medium.count'=0;;;0; 'alarms.low.count'=1;;;0;
    ...    4
    ...    --exclude-severity=critical --critical-alarms-total=1
    ...    CRITICAL: Alarms total: 2 WARNING: Alarm 'Virtual storage network bandwidth detection' [severity: low] [status: open] [object: storage 'datastore-vs'] [since: 2026-10-17 12:00:20] The storage network interface of the virtual datastore uses a gigabit network. | 'alarms.total.count'=2;;0:1;0; 'alarms.critical.count'=0;;;0; 'alarms.medium.count'=1;;;0; 'alarms.low.count'=1;;;0;
