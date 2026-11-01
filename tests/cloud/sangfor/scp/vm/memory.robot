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
Memory ${tc}
    [Tags]    cloud    sangfor    vm
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002
    ...    OK: VM 'db-01' Memory total: 8.00 GB used: 7.20 GB (90.00%) free: 819.20 MB (10.00%) | 'db-01#vm.memory.usage.bytes'=7730941132B;;;0;8589934592 'db-01#vm.memory.free.bytes'=858993459B;;;0;8589934592 'db-01#vm.memory.usage.percentage'=90.00%;;;0;100
    ...    2
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002 --critical-memory-usage-prct=80
    ...    CRITICAL: VM 'db-01' Memory total: 8.00 GB used: 7.20 GB (90.00%) free: 819.20 MB (10.00%) | 'db-01#vm.memory.usage.bytes'=7730941132B;;;0;8589934592 'db-01#vm.memory.free.bytes'=858993459B;;;0;8589934592 'db-01#vm.memory.usage.percentage'=90.00%;;0:80;0;100
