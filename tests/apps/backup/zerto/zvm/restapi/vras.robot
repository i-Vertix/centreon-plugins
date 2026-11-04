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
...                 --mode=vras
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Vras ${tc}
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
    ...    CRITICAL: VRA 'Z-VRA-esx03.example' status: HostPasswordChanged, alert status: Error, version: 10.9.0 WARNING: VRA 'Z-VRA-esx02.example' status: HostInMaintenanceMode, alert status: Warning, version: 10.9.0 | 'vras.total.count'=3;;;0; 'Z-VRA-esx01.example#vra.vms.protected.count'=4;;;0; 'Z-VRA-esx01.example#vra.vpgs.protected.count'=3;;;0; 'Z-VRA-esx01.example#vra.volumes.protected.count'=9;;;0; 'Z-VRA-esx01.example#vra.vms.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.vpgs.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.volumes.recovery.count'=0;;;0; 'Z-VRA-esx02.example#vra.vms.protected.count'=2;;;0; 'Z-VRA-esx02.example#vra.vpgs.protected.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.protected.count'=4;;;0; 'Z-VRA-esx02.example#vra.vms.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.vpgs.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.vms.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vpgs.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.volumes.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vms.recovery.count'=3;;;0; 'Z-VRA-esx03.example#vra.vpgs.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.volumes.recovery.count'=6;;;0;
    ...    2
    ...    --include-group=dr
    ...    CRITICAL: VRA 'Z-VRA-esx03.example' status: HostPasswordChanged, alert status: Error, version: 10.9.0 | 'vras.total.count'=1;;;0; 'Z-VRA-esx03.example#vra.vms.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vpgs.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.volumes.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vms.recovery.count'=3;;;0; 'Z-VRA-esx03.example#vra.vpgs.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.volumes.recovery.count'=6;;;0;
    ...    3
    ...    --exclude-name=esx03
    ...    WARNING: VRA 'Z-VRA-esx02.example' status: HostInMaintenanceMode, alert status: Warning, version: 10.9.0 | 'vras.total.count'=2;;;0; 'Z-VRA-esx01.example#vra.vms.protected.count'=4;;;0; 'Z-VRA-esx01.example#vra.vpgs.protected.count'=3;;;0; 'Z-VRA-esx01.example#vra.volumes.protected.count'=9;;;0; 'Z-VRA-esx01.example#vra.vms.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.vpgs.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.volumes.recovery.count'=0;;;0; 'Z-VRA-esx02.example#vra.vms.protected.count'=2;;;0; 'Z-VRA-esx02.example#vra.vpgs.protected.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.protected.count'=4;;;0; 'Z-VRA-esx02.example#vra.vms.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.vpgs.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.recovery.count'=2;;;0;
    ...    4
    ...    --warning-status='' --critical-status=''
    ...    OK: VRAs total: 3 - All VRAs are ok | 'vras.total.count'=3;;;0; 'Z-VRA-esx01.example#vra.vms.protected.count'=4;;;0; 'Z-VRA-esx01.example#vra.vpgs.protected.count'=3;;;0; 'Z-VRA-esx01.example#vra.volumes.protected.count'=9;;;0; 'Z-VRA-esx01.example#vra.vms.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.vpgs.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.volumes.recovery.count'=0;;;0; 'Z-VRA-esx02.example#vra.vms.protected.count'=2;;;0; 'Z-VRA-esx02.example#vra.vpgs.protected.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.protected.count'=4;;;0; 'Z-VRA-esx02.example#vra.vms.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.vpgs.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.vms.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vpgs.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.volumes.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vms.recovery.count'=3;;;0; 'Z-VRA-esx03.example#vra.vpgs.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.volumes.recovery.count'=6;;;0;
    ...    5
    ...    --warning-status='' --critical-status='%\\\{alert_status\\\} ne "Normal"'
    ...    CRITICAL: VRA 'Z-VRA-esx02.example' status: HostInMaintenanceMode, alert status: Warning, version: 10.9.0 - VRA 'Z-VRA-esx03.example' status: HostPasswordChanged, alert status: Error, version: 10.9.0 | 'vras.total.count'=3;;;0; 'Z-VRA-esx01.example#vra.vms.protected.count'=4;;;0; 'Z-VRA-esx01.example#vra.vpgs.protected.count'=3;;;0; 'Z-VRA-esx01.example#vra.volumes.protected.count'=9;;;0; 'Z-VRA-esx01.example#vra.vms.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.vpgs.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.volumes.recovery.count'=0;;;0; 'Z-VRA-esx02.example#vra.vms.protected.count'=2;;;0; 'Z-VRA-esx02.example#vra.vpgs.protected.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.protected.count'=4;;;0; 'Z-VRA-esx02.example#vra.vms.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.vpgs.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.vms.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vpgs.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.volumes.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vms.recovery.count'=3;;;0; 'Z-VRA-esx03.example#vra.vpgs.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.volumes.recovery.count'=6;;;0;
    ...    6
    ...    --critical-recovery-vms=2
    ...    CRITICAL: VRA 'Z-VRA-esx03.example' status: HostPasswordChanged, alert status: Error, version: 10.9.0, recovery VMs: 3 WARNING: VRA 'Z-VRA-esx02.example' status: HostInMaintenanceMode, alert status: Warning, version: 10.9.0 | 'vras.total.count'=3;;;0; 'Z-VRA-esx01.example#vra.vms.protected.count'=4;;;0; 'Z-VRA-esx01.example#vra.vpgs.protected.count'=3;;;0; 'Z-VRA-esx01.example#vra.volumes.protected.count'=9;;;0; 'Z-VRA-esx01.example#vra.vms.recovery.count'=0;;0:2;0; 'Z-VRA-esx01.example#vra.vpgs.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.volumes.recovery.count'=0;;;0; 'Z-VRA-esx02.example#vra.vms.protected.count'=2;;;0; 'Z-VRA-esx02.example#vra.vpgs.protected.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.protected.count'=4;;;0; 'Z-VRA-esx02.example#vra.vms.recovery.count'=1;;0:2;0; 'Z-VRA-esx02.example#vra.vpgs.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.vms.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vpgs.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.volumes.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vms.recovery.count'=3;;0:2;0; 'Z-VRA-esx03.example#vra.vpgs.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.volumes.recovery.count'=6;;;0;
    ...    7
    ...    --warning-vras-total=2
    ...    CRITICAL: VRA 'Z-VRA-esx03.example' status: HostPasswordChanged, alert status: Error, version: 10.9.0 WARNING: VRAs total: 3 - VRA 'Z-VRA-esx02.example' status: HostInMaintenanceMode, alert status: Warning, version: 10.9.0 | 'vras.total.count'=3;0:2;;0; 'Z-VRA-esx01.example#vra.vms.protected.count'=4;;;0; 'Z-VRA-esx01.example#vra.vpgs.protected.count'=3;;;0; 'Z-VRA-esx01.example#vra.volumes.protected.count'=9;;;0; 'Z-VRA-esx01.example#vra.vms.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.vpgs.recovery.count'=0;;;0; 'Z-VRA-esx01.example#vra.volumes.recovery.count'=0;;;0; 'Z-VRA-esx02.example#vra.vms.protected.count'=2;;;0; 'Z-VRA-esx02.example#vra.vpgs.protected.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.protected.count'=4;;;0; 'Z-VRA-esx02.example#vra.vms.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.vpgs.recovery.count'=1;;;0; 'Z-VRA-esx02.example#vra.volumes.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.vms.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vpgs.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.volumes.protected.count'=0;;;0; 'Z-VRA-esx03.example#vra.vms.recovery.count'=3;;;0; 'Z-VRA-esx03.example#vra.vpgs.recovery.count'=2;;;0; 'Z-VRA-esx03.example#vra.volumes.recovery.count'=6;;;0;
