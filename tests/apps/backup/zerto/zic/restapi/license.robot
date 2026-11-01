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
...                 --mode=license
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
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
    ...    2
    ...    --warning-expires=@0:30
    ...    WARNING: License expires in 19 days | 'license.expires.days'=19d;@0:30;;; 'license.vms.usage.count'=41;;;0;50 'license.vms.free.count'=9;;;0;50 'license.vms.usage.percentage'=82.00%;;;0;100
    ...    3
    ...    --critical-expires=@0:30
    ...    CRITICAL: License expires in 19 days | 'license.expires.days'=19d;;@0:30;; 'license.vms.usage.count'=41;;;0;50 'license.vms.free.count'=9;;;0;50 'license.vms.usage.percentage'=82.00%;;;0;100
    ...    4
    ...    --warning-vms-usage-prct=80
    ...    WARNING: License protected VMs total: 50 used: 41 (82.00%) free: 9 (18.00%) | 'license.expires.days'=19d;;;; 'license.vms.usage.count'=41;;;0;50 'license.vms.free.count'=9;;;0;50 'license.vms.usage.percentage'=82.00%;0:80;;0;100
    ...    5
    ...    --critical-vms-usage-free=10:
    ...    CRITICAL: License protected VMs total: 50 used: 41 (82.00%) free: 9 (18.00%) | 'license.expires.days'=19d;;;; 'license.vms.usage.count'=41;;;0;50 'license.vms.free.count'=9;;10:;0;50 'license.vms.usage.percentage'=82.00%;;;0;100
    ...    7
    ...    --client-secret=wrong
    ...    UNKNOWN: Authentication endpoint returns error 'unauthorized_client' (add --debug option for detailed message)

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
    ...    1
    ...    ${EMPTY}
    ...    ^OK:\\ License\\ type:\\ Subscription,\\ expired:\\ false,\\ expiry\\ date:\\ \\d{4}-\\d{2}-\\d{2},\\ expires\\ in\\ 19\\ days,\\ protected\\ VMs\\ total:\\ 50\\ used:\\ 41\\ \\(82\\.00%\\)\\ free:\\ 9\\ \\(18\\.00%\\)\\ \\|\\ 'license\\.expires\\.days'=19d;;;;\\ 'license\\.vms\\.usage\\.count'=41;;;0;50\\ 'license\\.vms\\.free\\.count'=9;;;0;50\\ 'license\\.vms\\.usage\\.percentage'=82\\.00%;;;0;100$
    ...    6
    ...    --critical-status='%\\\{type\\\} =~ /Subscription/'
    ...    ^CRITICAL:\\ License\\ type:\\ Subscription,\\ expired:\\ false,\\ expiry\\ date:\\ \\d{4}-\\d{2}-\\d{2}\\ \\|\\ 'license\\.expires\\.days'=19d;;;;\\ 'license\\.vms\\.usage\\.count'=41;;;0;50\\ 'license\\.vms\\.free\\.count'=9;;;0;50\\ 'license\\.vms\\.usage\\.percentage'=82\\.00%;;;0;100$
