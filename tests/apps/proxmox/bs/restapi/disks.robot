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
...                 --mode=disks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123


*** Test Cases ***
Disks ${tc}
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
    ...    CRITICAL: Disk 'sdc' SMART status: failed [type: hdd] [used: filesystem] [model: SAMPLE HDD 4TB] | 'disks.total.count'=4;;;0; 'nvme0n1#disk.life.remaining.percentage'=85.00%;;;0;100
    ...    2
    ...    --include-type=ssd --warning-life-remaining=90:
    ...    WARNING: Disk 'nvme0n1' life remaining: 85.00 % | 'disks.total.count'=1;;;0; 'nvme0n1#disk.life.remaining.percentage'=85.00%;90:;;0;100
    ...    3
    ...    --exclude-name=sdc
    ...    OK: All disks are ok | 'disks.total.count'=3;;;0; 'nvme0n1#disk.life.remaining.percentage'=85.00%;;;0;100
    ...    4
    ...    --include-name='^sd' --critical-status='' --warning-status='%\\\{status\\\} ne "passed"'
    ...    WARNING: Disk 'sdc' SMART status: failed [type: hdd] [used: filesystem] [model: SAMPLE HDD 4TB] | 'disks.total.count'=3;;;0;
    ...    5
    ...    --critical-disks-total=:3
    ...    CRITICAL: Disks total: 4 - Disk 'sdc' SMART status: failed [type: hdd] [used: filesystem] [model: SAMPLE HDD 4TB] | 'disks.total.count'=4;;0:3;0; 'nvme0n1#disk.life.remaining.percentage'=85.00%;;;0;100
    ...    6
    ...    --include-type=usb
    ...    UNKNOWN: No disk found.
