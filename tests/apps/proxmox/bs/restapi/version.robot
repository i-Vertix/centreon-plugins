*** Settings ***
Documentation       apps::proxmox::bs::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}pbs.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::proxmox::bs::restapi::plugin
...                 --mode=version
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Version ${tc}
    [Tags]    apps    proxmox    restapi
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
    ...    --api-token-id='monitor@pbs!centreon' --api-token-secret=token-123
    ...    OK: Version: 4.0 [release: 18] [repository id: 0123456789abcdef0123456789abcdef01234567]
    ...    2
    ...    --api-token-id='monitor@pbs!centreon' --api-token-secret=wrong
    ...    UNKNOWN: 401 Unauthorized
    ...    3
    ...    --api-username=monitor --api-password=pass-123 --statefile-dir=/dev/shm/
    ...    OK: Version: 4.0 [release: 18] [repository id: 0123456789abcdef0123456789abcdef01234567]
    ...    4
    ...    --api-username=monitor@pbs --api-password=pass-123 --statefile-dir=/dev/shm/
    ...    OK: Version: 4.0 [release: 18] [repository id: 0123456789abcdef0123456789abcdef01234567]
    ...    5
    ...    --api-username=monitor@pbs --api-password=wrong --statefile-dir=/dev/shm/
    ...    UNKNOWN: Authentication failed [code: '401'] [message: 'Unauthorized']
    ...    6
    ...    --api-username=monitor --realm=pam --api-password=pass-123 --statefile-dir=/dev/shm/
    ...    UNKNOWN: Authentication failed [code: '401'] [message: 'Unauthorized']
    ...    7
    ...    --api-password=pass-123
    ...    UNKNOWN: Need to specify --api-token-id and --api-token-secret options (or --api-username and --api-password).
