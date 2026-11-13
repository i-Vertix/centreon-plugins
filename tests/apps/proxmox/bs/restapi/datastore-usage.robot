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
...                 --mode=datastore-usage
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123
...                 --filter-perfdata='usage|free|days|factor|pending|chunks'


*** Test Cases ***
Datastore Usage ${tc}
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
    ...    CRITICAL: Datastore 'store02' mount status: nonremovable, error: unable to open chunk store at "/mnt/datastore/store02/.chunks" - No such file or directory WARNING: Datastore 's3store01' mount status: nonremovable, maintenance: read-only - Datastore 'usb01' mount status: notmounted | 's3store01#datastore.space.usage.bytes'=4488000000000B;;;0;5000000000000 's3store01#datastore.space.free.bytes'=512000000000B;;;0;5000000000000 's3store01#datastore.space.usage.percentage'=89.76%;;;0;100 's3store01#datastore.deduplication.factor.count'=3.00;;;0; 's3store01#datastore.gc.pending.bytes'=21474836480B;;;0; 's3store01#datastore.chunks.bad.count'=3;;;0; 'store01#datastore.space.usage.bytes'=11891364593664B;;;0;16000000983040 'store01#datastore.space.free.bytes'=4108636389376B;;;0;16000000983040 'store01#datastore.space.usage.percentage'=74.32%;;;0;100 'store01#datastore.space.full.estimated.days'=400d;;;0; 'store01#datastore.deduplication.factor.count'=11.26;;;0; 'store01#datastore.gc.pending.bytes'=0B;;;0; 'store01#datastore.chunks.bad.count'=0;;;0;
    ...    2
    ...    --include-name='^store01$'
    ...    OK: Datastore 'store01' mount status: nonremovable, space usage total: 14.55 TB used: 10.82 TB (74.32%) free: 3.74 TB (25.68%), estimated full in: 400 days, deduplication factor: 11.26, bad chunks: 0 | 'store01#datastore.space.usage.bytes'=11891364593664B;;;0;16000000983040 'store01#datastore.space.free.bytes'=4108636389376B;;;0;16000000983040 'store01#datastore.space.usage.percentage'=74.32%;;;0;100 'store01#datastore.space.full.estimated.days'=400d;;;0; 'store01#datastore.deduplication.factor.count'=11.26;;;0; 'store01#datastore.gc.pending.bytes'=0B;;;0; 'store01#datastore.chunks.bad.count'=0;;;0;
    ...    3
    ...    --exclude-name='store02|usb01' --warning-status=''
    ...    OK: All datastores are ok | 's3store01#datastore.space.usage.bytes'=4488000000000B;;;0;5000000000000 's3store01#datastore.space.free.bytes'=512000000000B;;;0;5000000000000 's3store01#datastore.space.usage.percentage'=89.76%;;;0;100 's3store01#datastore.deduplication.factor.count'=3.00;;;0; 's3store01#datastore.gc.pending.bytes'=21474836480B;;;0; 's3store01#datastore.chunks.bad.count'=3;;;0; 'store01#datastore.space.usage.bytes'=11891364593664B;;;0;16000000983040 'store01#datastore.space.free.bytes'=4108636389376B;;;0;16000000983040 'store01#datastore.space.usage.percentage'=74.32%;;;0;100 'store01#datastore.space.full.estimated.days'=400d;;;0; 'store01#datastore.deduplication.factor.count'=11.26;;;0; 'store01#datastore.gc.pending.bytes'=0B;;;0; 'store01#datastore.chunks.bad.count'=0;;;0;
    ...    4
    ...    --include-backend-type=s3 --warning-status='' --critical-usage-prct=85
    ...    CRITICAL: Datastore 's3store01' space usage total: 4.55 TB used: 4.08 TB (89.76%) free: 476.84 GB (10.24%) | 's3store01#datastore.space.usage.bytes'=4488000000000B;;;0;5000000000000 's3store01#datastore.space.free.bytes'=512000000000B;;;0;5000000000000 's3store01#datastore.space.usage.percentage'=89.76%;;0:85;0;100 's3store01#datastore.deduplication.factor.count'=3.00;;;0; 's3store01#datastore.gc.pending.bytes'=21474836480B;;;0; 's3store01#datastore.chunks.bad.count'=3;;;0;
    ...    5
    ...    --exclude-backend-type=s3 --include-name=store01 --warning-estimated-full=500:
    ...    WARNING: Datastore 'store01' estimated full in: 400 days | 'store01#datastore.space.usage.bytes'=11891364593664B;;;0;16000000983040 'store01#datastore.space.free.bytes'=4108636389376B;;;0;16000000983040 'store01#datastore.space.usage.percentage'=74.32%;;;0;100 'store01#datastore.space.full.estimated.days'=400d;500:;;0; 'store01#datastore.deduplication.factor.count'=11.26;;;0; 'store01#datastore.gc.pending.bytes'=0B;;;0; 'store01#datastore.chunks.bad.count'=0;;;0;
    ...    6
    ...    --include-name=s3store01 --warning-status='' --critical-chunks-bad=0 --warning-gc-pending=10000000000
    ...    CRITICAL: Datastore 's3store01' garbage collection pending: 20.00 GB, bad chunks: 3 | 's3store01#datastore.space.usage.bytes'=4488000000000B;;;0;5000000000000 's3store01#datastore.space.free.bytes'=512000000000B;;;0;5000000000000 's3store01#datastore.space.usage.percentage'=89.76%;;;0;100 's3store01#datastore.deduplication.factor.count'=3.00;;;0; 's3store01#datastore.gc.pending.bytes'=21474836480B;0:10000000000;;0; 's3store01#datastore.chunks.bad.count'=3;;0:0;0;
    ...    7
    ...    --include-name='^store01$' --critical-deduplication-factor=20:
    ...    CRITICAL: Datastore 'store01' deduplication factor: 11.26 | 'store01#datastore.space.usage.bytes'=11891364593664B;;;0;16000000983040 'store01#datastore.space.free.bytes'=4108636389376B;;;0;16000000983040 'store01#datastore.space.usage.percentage'=74.32%;;;0;100 'store01#datastore.space.full.estimated.days'=400d;;;0; 'store01#datastore.deduplication.factor.count'=11.26;;20:;0; 'store01#datastore.gc.pending.bytes'=0B;;;0; 'store01#datastore.chunks.bad.count'=0;;;0;
    ...    8
    ...    --include-name=usb01 --warning-status='' --critical-status='%\\\{mount_status\\\} eq "notmounted"'
    ...    CRITICAL: Datastore 'usb01' mount status: notmounted
    ...    9
    ...    --include-name=store02 --critical-status=''
    ...    OK: Datastore 'store02' mount status: nonremovable, error: unable to open chunk store at "/mnt/datastore/store02/.chunks" - No such file or directory
    ...    10
    ...    --include-name=nomatch
    ...    UNKNOWN: No datastore found.
