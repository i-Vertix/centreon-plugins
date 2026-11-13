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
...                 --mode=list-datastores
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123


*** Test Cases ***
List Datastores ${tc}
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
    ...    ${EMPTY}
    ...    List datastores: [name: s3store01][backend_type: s3][mount_status: nonremovable][maintenance: read-only][comment: offsite copy] [name: store01][backend_type: filesystem][mount_status: nonremovable][maintenance: ][comment: main datastore] [name: store02][backend_type: filesystem][mount_status: nonremovable][maintenance: ][comment: ] [name: usb01][backend_type: filesystem][mount_status: notmounted][maintenance: ][comment: rotating USB disk]
    ...    2
    ...    --include-backend-type=s3
    ...    List datastores: [name: s3store01][backend_type: s3][mount_status: nonremovable][maintenance: read-only][comment: offsite copy]
    ...    3
    ...    --exclude-name='^s3|usb'
    ...    List datastores: [name: store01][backend_type: filesystem][mount_status: nonremovable][maintenance: ][comment: main datastore] [name: store02][backend_type: filesystem][mount_status: nonremovable][maintenance: ][comment: ]
    ...    4
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>backend_type</element> <element>mount_status</element> <element>maintenance</element> <element>comment</element> </data>
    ...    5
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label backend_type="s3" comment="offsite copy" maintenance="read-only" mount_status="nonremovable" name="s3store01"/> <label backend_type="filesystem" comment="main datastore" maintenance="" mount_status="nonremovable" name="store01"/> <label backend_type="filesystem" comment="" maintenance="" mount_status="nonremovable" name="store02"/> <label backend_type="filesystem" comment="rotating USB disk" maintenance="" mount_status="notmounted" name="usb01"/> </data>
