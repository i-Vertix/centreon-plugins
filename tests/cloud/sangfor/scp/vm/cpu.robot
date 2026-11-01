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
Cpu ${tc}
    [Tags]    cloud    sangfor    vm
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=cpu
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002
    ...    OK: VM 'db-01' CPU usage: 75.00 %, CPU used: 3301.50 MHz | 'db-01#vm.cpu.utilization.percentage'=75.00%;;;0;100 'db-01#vm.cpu.utilization.mhz'=3301.50MHz;;;0;4402
    ...    2
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002 --warning-cpu-usage-prct=70
    ...    WARNING: VM 'db-01' CPU usage: 75.00 % | 'db-01#vm.cpu.utilization.percentage'=75.00%;0:70;;0;100 'db-01#vm.cpu.utilization.mhz'=3301.50MHz;;;0;4402
    ...    3
    ...    --include-name=test
    ...    OK: VM 'test-01' CPU usage: 0.00 %, CPU used: 0.00 MHz | 'test-01#vm.cpu.utilization.percentage'=0.00%;;;0;100 'test-01#vm.cpu.utilization.mhz'=0.00MHz;;;0;2201
