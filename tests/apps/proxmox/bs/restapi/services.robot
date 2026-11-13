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
...                 --mode=services
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123


*** Test Cases ***
Services ${tc}
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
    ...    CRITICAL: Service 'postfix' state: dead [unit state: enabled] | 'services.running.count'=6;;;0;8 'services.stopped.count'=2;;;0;8
    ...    2
    ...    --include-name='^proxmox'
    ...    OK: Services running: 2, not running: 0 - All services are ok | 'services.running.count'=2;;;0;2 'services.stopped.count'=0;;;0;2
    ...    3
    ...    --exclude-name=postfix
    ...    OK: Services running: 6, not running: 1 - All services are ok | 'services.running.count'=6;;;0;7 'services.stopped.count'=1;;;0;7
    ...    4
    ...    --exclude-name=postfix --critical-status='%\\\{state\\\} ne "running"'
    ...    CRITICAL: Service 'smartmontools' state: dead [unit state: disabled] | 'services.running.count'=6;;;0;7 'services.stopped.count'=1;;;0;7
    ...    5
    ...    --critical-status='' --warning-services-stopped=0
    ...    WARNING: Services not running: 2 | 'services.running.count'=6;;;0;8 'services.stopped.count'=2;0:0;;0;8
