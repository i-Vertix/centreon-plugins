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
Disk Io ${tc}
    [Tags]    cloud    sangfor    vm
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=disk-io
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002
    ...    OK: VM 'db-01' read: 5.00 MB/s, write: 10.00 MB/s, read IOPS: 150.00, write IOPS: 420.00 | 'db-01#vm.disk.io.read.usage.bytespersecond'=5242880B/s;;;0; 'db-01#vm.disk.io.write.usage.bytespersecond'=10485760B/s;;;0; 'db-01#vm.disk.io.read.usage.iops'=150.00iops;;;0; 'db-01#vm.disk.io.write.usage.iops'=420.00iops;;;0;
    ...    2
    ...    --id=f1e2d3c4-0000-4000-8000-000000000002 --critical-write-iops=400
    ...    CRITICAL: VM 'db-01' write IOPS: 420.00 | 'db-01#vm.disk.io.read.usage.bytespersecond'=5242880B/s;;;0; 'db-01#vm.disk.io.write.usage.bytespersecond'=10485760B/s;;;0; 'db-01#vm.disk.io.read.usage.iops'=150.00iops;;;0; 'db-01#vm.disk.io.write.usage.iops'=420.00iops;;0:400;0;
