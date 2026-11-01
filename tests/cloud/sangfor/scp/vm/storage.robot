*** Settings ***
Documentation       cloud::sangfor::scp::vm::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::vm::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Storage ${tc}
    [Tags]    cloud    sangfor    vm
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002
    ...    OK: VM 'db-01' Storage total: 100.00 GB used: 80.00 GB (80.00%) free: 20.00 GB (20.00%) | 'db-01#vm.storage.space.usage.bytes'=85899345920B;;;0;107374182400 'db-01#vm.storage.space.free.bytes'=21474836480B;;;0;107374182400 'db-01#vm.storage.space.usage.percentage'=80.00%;;;0;100
    ...    2
    ...    --include-name=web --warning-space-usage-prct=60
    ...    WARNING: VM 'web-01' Storage total: 2.00 GB used: 1.25 GB (62.52%) free: 767.69 MB (37.48%) | 'web-01#vm.storage.space.usage.bytes'=1342502338B;;;0;2147483648 'web-01#vm.storage.space.free.bytes'=804981309B;;;0;2147483648 'web-01#vm.storage.space.usage.percentage'=62.52%;0:60;;0;100
