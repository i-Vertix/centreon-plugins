*** Settings ***
Documentation       cloud::sangfor::scp::storage::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::storage::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
Io ${tc}
    [Tags]    cloud    sangfor    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=io
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All storages IO are ok | 'iscsi-01#storage.io.read.usage.bytespersecond'=35479552B/s;;;0; 'iscsi-01#storage.io.write.usage.bytespersecond'=15659008B/s;;;0; 'node1_local#storage.io.read.usage.bytespersecond'=0B/s;;;0; 'node1_local#storage.io.write.usage.bytespersecond'=0B/s;;;0; 'datastore-vs#storage.io.read.usage.bytespersecond'=1048576B/s;;;0; 'datastore-vs#storage.io.write.usage.bytespersecond'=524288B/s;;;0;
    ...    2
    ...    --include-type=iscsi --warning-read=30000000
    ...    WARNING: Storage 'iscsi-01' read: 33.84 MB/s | 'iscsi-01#storage.io.read.usage.bytespersecond'=35479552B/s;0:30000000;;0; 'iscsi-01#storage.io.write.usage.bytespersecond'=15659008B/s;;;0;
