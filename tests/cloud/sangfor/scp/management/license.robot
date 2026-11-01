*** Settings ***
Documentation       cloud::sangfor::scp::management::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::sangfor::scp::management::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --access-key=my-access-key
...                 --secret-key=my-secret-key


*** Test Cases ***
License ${tc}
    [Tags]    cloud    sangfor    management
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=license
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All licenses are ok | 'aCloud#license.software.expires.days'=67d;;;0; 'aCloud#license.service.expires.days'=23d;;;0; 'aSV#license.service.expires.days'=365d;;;0;
    ...    2
    ...    --include-name=aCloud --warning-service-expires=30:
    ...    WARNING: Product 'aCloud' service expires in 3w 2d 3h 33m 20s | 'aCloud#license.software.expires.days'=67d;;;0; 'aCloud#license.service.expires.days'=23d;30:;;0;
    ...    3
    ...    --include-name=aSV --unit=w
    ...    OK: Product 'aSV' activated: yes, disabled: no, service expires in 11M 4w 2d 4h 40m 27s | 'aSV#license.service.expires.weeks'=52w;;;0;
    ...    4
    ...    --include-not-activated --include-name=NGAF
    ...    OK: Product 'NGAF' activated: no, disabled: yes, software expires in 0s | 'NGAF#license.software.expires.days'=0d;;;0;
