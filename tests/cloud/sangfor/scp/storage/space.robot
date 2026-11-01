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
Space ${tc}
    [Tags]    cloud    sangfor    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=space
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All storages space usages are ok | 'iscsi-01#storage.space.usage.bytes'=1932735283200B;;;0;2361158270976 'iscsi-01#storage.space.free.bytes'=428422987776B;;;0;2361158270976 'iscsi-01#storage.space.usage.percentage'=81.86%;;;0;100 'datastore-vs#storage.space.usage.bytes'=1433403392B;;;0;545460846592 'datastore-vs#storage.space.free.bytes'=544027443200B;;;0;545460846592 'datastore-vs#storage.space.usage.percentage'=0.26%;;;0;100
    ...    2
    ...    --include-name=iscsi --warning-space-usage-prct=80
    ...    WARNING: Storage 'iscsi-01' Space total: 2.15 TB used: 1.76 TB (81.86%) free: 399.00 GB (18.14%) | 'iscsi-01#storage.space.usage.bytes'=1932735283200B;;;0;2361158270976 'iscsi-01#storage.space.free.bytes'=428422987776B;;;0;2361158270976 'iscsi-01#storage.space.usage.percentage'=81.86%;0:80;;0;100
