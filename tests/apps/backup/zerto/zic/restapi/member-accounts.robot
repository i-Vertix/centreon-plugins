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
...                 --mode=member-accounts
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Member Accounts ${tc}
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
    ...    CRITICAL: Member account '222222222222' (dr) status: NotReady (Cannot assume role ZertoInCloudRole) | 'memberaccounts.total.count'=2;;;0; 'memberaccounts.notready.count'=1;;;0;2 '111111111111#memberaccount.vms.protected.count'=6;;;0; '111111111111#memberaccount.vpgs.count'=3;;;0; '222222222222#memberaccount.vms.protected.count'=0;;;0; '222222222222#memberaccount.vpgs.count'=0;;;0;
    ...    2
    ...    --exclude-id=2222
    ...    OK: Member accounts not ready: 0 - Member account '111111111111' (prod) status: Ready, protected VMs: 6, VPGs: 3 | 'memberaccounts.total.count'=1;;;0; 'memberaccounts.notready.count'=0;;;0;1 '111111111111#memberaccount.vms.protected.count'=6;;;0; '111111111111#memberaccount.vpgs.count'=3;;;0;
    ...    3
    ...    --include-description=prod
    ...    OK: Member accounts not ready: 0 - Member account '111111111111' (prod) status: Ready, protected VMs: 6, VPGs: 3 | 'memberaccounts.total.count'=1;;;0; 'memberaccounts.notready.count'=0;;;0;1 '111111111111#memberaccount.vms.protected.count'=6;;;0; '111111111111#memberaccount.vpgs.count'=3;;;0;
    ...    4
    ...    --critical-status=''
    ...    OK: Member accounts not ready: 1 - All member accounts are ok | 'memberaccounts.total.count'=2;;;0; 'memberaccounts.notready.count'=1;;;0;2 '111111111111#memberaccount.vms.protected.count'=6;;;0; '111111111111#memberaccount.vpgs.count'=3;;;0; '222222222222#memberaccount.vms.protected.count'=0;;;0; '222222222222#memberaccount.vpgs.count'=0;;;0;
    ...    5
    ...    --critical-status='' --warning-protected-vms=5
    ...    WARNING: Member account '111111111111' (prod) protected VMs: 6 | 'memberaccounts.total.count'=2;;;0; 'memberaccounts.notready.count'=1;;;0;2 '111111111111#memberaccount.vms.protected.count'=6;0:5;;0; '111111111111#memberaccount.vpgs.count'=3;;;0; '222222222222#memberaccount.vms.protected.count'=0;0:5;;0; '222222222222#memberaccount.vpgs.count'=0;;;0;
    ...    6
    ...    --critical-accounts-not-ready=0
    ...    CRITICAL: Member accounts not ready: 1 - Member account '222222222222' (dr) status: NotReady (Cannot assume role ZertoInCloudRole) | 'memberaccounts.total.count'=2;;;0; 'memberaccounts.notready.count'=1;;0:0;0;2 '111111111111#memberaccount.vms.protected.count'=6;;;0; '111111111111#memberaccount.vpgs.count'=3;;;0; '222222222222#memberaccount.vms.protected.count'=0;;;0; '222222222222#memberaccount.vpgs.count'=0;;;0;
