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
...                 --mode=license
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
License ${tc}
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
    ...    --filter-counters='^(?!status)'
    ...    OK: License expires in 45 days, protected VMs total: 50 used: 7 (14.00%) free: 43 (86.00%) - All sites are ok | 'license.expires.days'=45d;;;; 'license.vms.usage.count'=7;;;0;50 'license.vms.free.count'=43;;;0;50 'license.vms.usage.percentage'=14.00%;;;0;100 'site-a#license.site.vms.protected.count'=7;;;0; 'site-b#license.site.vms.protected.count'=0;;;0;
    ...    2
    ...    --filter-counters='^(?!status)' --warning-expires=60: --critical-expires=30:
    ...    WARNING: License expires in 45 days | 'license.expires.days'=45d;60:;30:;; 'license.vms.usage.count'=7;;;0;50 'license.vms.free.count'=43;;;0;50 'license.vms.usage.percentage'=14.00%;;;0;100 'site-a#license.site.vms.protected.count'=7;;;0; 'site-b#license.site.vms.protected.count'=0;;;0;
    ...    3
    ...    --filter-counters='^(?!status)' --critical-vms-usage-prct=10
    ...    CRITICAL: License protected VMs total: 50 used: 7 (14.00%) free: 43 (86.00%) | 'license.expires.days'=45d;;;; 'license.vms.usage.count'=7;;;0;50 'license.vms.free.count'=43;;;0;50 'license.vms.usage.percentage'=14.00%;;0:10;0;100 'site-a#license.site.vms.protected.count'=7;;;0; 'site-b#license.site.vms.protected.count'=0;;;0;
    ...    4
    ...    --filter-counters='^(?!status)' --warning-vms-usage-free=50:
    ...    WARNING: License protected VMs total: 50 used: 7 (14.00%) free: 43 (86.00%) | 'license.expires.days'=45d;;;; 'license.vms.usage.count'=7;;;0;50 'license.vms.free.count'=43;50:;;0;50 'license.vms.usage.percentage'=14.00%;;;0;100 'site-a#license.site.vms.protected.count'=7;;;0; 'site-b#license.site.vms.protected.count'=0;;;0;
    ...    5
    ...    --filter-counters='^(?!status)' --warning-site-protected-vms=5
    ...    WARNING: Site 'site-a' protected VMs: 7 | 'license.expires.days'=45d;;;; 'license.vms.usage.count'=7;;;0;50 'license.vms.free.count'=43;;;0;50 'license.vms.usage.percentage'=14.00%;;;0;100 'site-a#license.site.vms.protected.count'=7;0:5;;0; 'site-b#license.site.vms.protected.count'=0;0:5;;0;

License regexp ${tc}
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    6
    ...    ${EMPTY}
    ...    ^OK: License type: EnterpriseCloud, expired: false, expiry date: [0-9TZ:.-]+, expires in 45 days, protected VMs total: 50 used: 7 [(]14[.]00%[)] free: 43 [(]86[.]00%[)] - All sites are ok [|] 'license[.]expires[.]days'=45d;;;; 'license[.]vms[.]usage[.]count'=7;;;0;50 'license[.]vms[.]free[.]count'=43;;;0;50 'license[.]vms[.]usage[.]percentage'=14[.]00%;;;0;100 'site-a#license[.]site[.]vms[.]protected[.]count'=7;;;0; 'site-b#license[.]site[.]vms[.]protected[.]count'=0;;;0;$
    ...    7
    ...    --critical-status='%\\\{type\\\} =~ /Enterprise/'
    ...    ^CRITICAL: License type: EnterpriseCloud, expired: false, expiry date: [0-9TZ:.-]+ [|] 'license[.]expires[.]days'=45d;;;; 'license[.]vms[.]usage[.]count'=7;;;0;50 'license[.]vms[.]free[.]count'=43;;;0;50 'license[.]vms[.]usage[.]percentage'=14[.]00%;;;0;100 'site-a#license[.]site[.]vms[.]protected[.]count'=7;;;0; 'site-b#license[.]site[.]vms[.]protected[.]count'=0;;;0;$
