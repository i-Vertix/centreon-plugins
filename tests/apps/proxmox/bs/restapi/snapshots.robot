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
...                 --mode=snapshots
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123
...                 --filter-perfdata='count|size'


*** Test Cases ***
Snapshots ${tc}
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
    ...    CRITICAL: Backup group 'vm/101' [datastore: store01] [comment: vm-101] last snapshot verification: failed | 'backupgroups.total.count'=6;;;0; 'snapshots.total.count'=10;;;0; 's3store01~vm/300#backupgroup.snapshot.last.size.bytes'=21474837325B;;;0; 's3store01~vm/300#backupgroup.snapshots.count'=2;;;0; 's3store01~vm/300#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~ct/200#backupgroup.snapshot.last.size.bytes'=2147484500B;;;0; 'store01~ct/200#backupgroup.snapshots.count'=1;;;0; 'store01~ct/200#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~host/srv01#backupgroup.snapshot.last.size.bytes'=53687091200B;;;0; 'store01~host/srv01#backupgroup.snapshots.count'=1;;;0; 'store01~host/srv01#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/100#backupgroup.snapshot.last.size.bytes'=118111601493B;;;0; 'store01~vm/100#backupgroup.snapshots.count'=2;;;0; 'store01~vm/100#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/101#backupgroup.snapshot.last.size.bytes'=4831839092B;;;0; 'store01~vm/101#backupgroup.snapshots.count'=2;;;0; 'store01~vm/101#backupgroup.snapshots.verify.failed.count'=1;;;0; 'store01~vm/102#backupgroup.snapshot.last.size.bytes'=34359739226B;;;0; 'store01~vm/102#backupgroup.snapshots.count'=2;;;0; 'store01~vm/102#backupgroup.snapshots.verify.failed.count'=1;;;0;
    ...    2
    ...    --include-datastore=store01 --include-type=vm
    ...    CRITICAL: Backup group 'vm/101' [datastore: store01] [comment: vm-101] last snapshot verification: failed | 'backupgroups.total.count'=4;;;0; 'snapshots.total.count'=8;;;0; 's3store01~vm/300#backupgroup.snapshot.last.size.bytes'=21474837325B;;;0; 's3store01~vm/300#backupgroup.snapshots.count'=2;;;0; 's3store01~vm/300#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/100#backupgroup.snapshot.last.size.bytes'=118111601493B;;;0; 'store01~vm/100#backupgroup.snapshots.count'=2;;;0; 'store01~vm/100#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/101#backupgroup.snapshot.last.size.bytes'=4831839092B;;;0; 'store01~vm/101#backupgroup.snapshots.count'=2;;;0; 'store01~vm/101#backupgroup.snapshots.verify.failed.count'=1;;;0; 'store01~vm/102#backupgroup.snapshot.last.size.bytes'=34359739226B;;;0; 'store01~vm/102#backupgroup.snapshots.count'=2;;;0; 'store01~vm/102#backupgroup.snapshots.verify.failed.count'=1;;;0;
    ...    3
    ...    --include-type='ct|host'
    ...    OK: Backup groups total: 2, snapshots: 2 - All backup groups are ok | 'backupgroups.total.count'=2;;;0; 'snapshots.total.count'=2;;;0; 'store01~ct/200#backupgroup.snapshot.last.size.bytes'=2147484500B;;;0; 'store01~ct/200#backupgroup.snapshots.count'=1;;;0; 'store01~ct/200#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~host/srv01#backupgroup.snapshot.last.size.bytes'=53687091200B;;;0; 'store01~host/srv01#backupgroup.snapshots.count'=1;;;0; 'store01~host/srv01#backupgroup.snapshots.verify.failed.count'=0;;;0;
    ...    4
    ...    --exclude-datastore='^store01$' --warning-snapshots=:1
    ...    WARNING: Backup group 'vm/300' [datastore: s3store01] [comment: vm-300] snapshots: 2 | 'backupgroups.total.count'=1;;;0; 'snapshots.total.count'=2;;;0; 's3store01~vm/300#backupgroup.snapshot.last.size.bytes'=21474837325B;;;0; 's3store01~vm/300#backupgroup.snapshots.count'=2;0:1;;0; 's3store01~vm/300#backupgroup.snapshots.verify.failed.count'=0;;;0;
    ...    5
    ...    --include-id='^102$' --critical-verify-failed=0
    ...    CRITICAL: Backup group 'vm/102' [datastore: store01] [comment: vm-102] snapshots with failed verification: 1 | 'backupgroups.total.count'=1;;;0; 'snapshots.total.count'=2;;;0; 'store01~vm/102#backupgroup.snapshot.last.size.bytes'=34359739226B;;;0; 'store01~vm/102#backupgroup.snapshots.count'=2;;;0; 'store01~vm/102#backupgroup.snapshots.verify.failed.count'=1;;0:0;0;
    ...    6
    ...    --include-comment='vm-10[01]' --critical-status=''
    ...    OK: Backup groups total: 2, snapshots: 4 - All backup groups are ok | 'backupgroups.total.count'=2;;;0; 'snapshots.total.count'=4;;;0; 'store01~vm/100#backupgroup.snapshot.last.size.bytes'=118111601493B;;;0; 'store01~vm/100#backupgroup.snapshots.count'=2;;;0; 'store01~vm/100#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/101#backupgroup.snapshot.last.size.bytes'=4831839092B;;;0; 'store01~vm/101#backupgroup.snapshots.count'=2;;;0; 'store01~vm/101#backupgroup.snapshots.verify.failed.count'=1;;;0;
    ...    7
    ...    --critical-status='' --warning-status='%\\\{last_verify_state\\\} eq "none"'
    ...    WARNING: Backup group 'ct/200' [datastore: store01] [comment: ct-200] last snapshot verification: none - Backup group 'vm/102' [datastore: store01] [comment: vm-102] last snapshot verification: none | 'backupgroups.total.count'=6;;;0; 'snapshots.total.count'=10;;;0; 's3store01~vm/300#backupgroup.snapshot.last.size.bytes'=21474837325B;;;0; 's3store01~vm/300#backupgroup.snapshots.count'=2;;;0; 's3store01~vm/300#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~ct/200#backupgroup.snapshot.last.size.bytes'=2147484500B;;;0; 'store01~ct/200#backupgroup.snapshots.count'=1;;;0; 'store01~ct/200#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~host/srv01#backupgroup.snapshot.last.size.bytes'=53687091200B;;;0; 'store01~host/srv01#backupgroup.snapshots.count'=1;;;0; 'store01~host/srv01#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/100#backupgroup.snapshot.last.size.bytes'=118111601493B;;;0; 'store01~vm/100#backupgroup.snapshots.count'=2;;;0; 'store01~vm/100#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/101#backupgroup.snapshot.last.size.bytes'=4831839092B;;;0; 'store01~vm/101#backupgroup.snapshots.count'=2;;;0; 'store01~vm/101#backupgroup.snapshots.verify.failed.count'=1;;;0; 'store01~vm/102#backupgroup.snapshot.last.size.bytes'=34359739226B;;;0; 'store01~vm/102#backupgroup.snapshots.count'=2;;;0; 'store01~vm/102#backupgroup.snapshots.verify.failed.count'=1;;;0;
    ...    8
    ...    --include-type=host --critical-last-size=:1000000000
    ...    CRITICAL: Backup group 'host/srv01' [datastore: store01] [comment: host-srv01] last snapshot size: 50.00 GB | 'backupgroups.total.count'=1;;;0; 'snapshots.total.count'=1;;;0; 'store01~host/srv01#backupgroup.snapshot.last.size.bytes'=53687091200B;;0:1000000000;0; 'store01~host/srv01#backupgroup.snapshots.count'=1;;;0; 'store01~host/srv01#backupgroup.snapshots.verify.failed.count'=0;;;0;
    ...    9
    ...    --include-id=nomatch
    ...    UNKNOWN: No backup group found. skipping datastore 'store02': cannot read its snapshots
    ...    10
    ...    --warning-snapshots-total=:5 --critical-groups-total=:4
    ...    CRITICAL: Backup groups total: 6, snapshots: 10 - Backup group 'vm/101' [datastore: store01] [comment: vm-101] last snapshot verification: failed | 'backupgroups.total.count'=6;;0:4;0; 'snapshots.total.count'=10;0:5;;0; 's3store01~vm/300#backupgroup.snapshot.last.size.bytes'=21474837325B;;;0; 's3store01~vm/300#backupgroup.snapshots.count'=2;;;0; 's3store01~vm/300#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~ct/200#backupgroup.snapshot.last.size.bytes'=2147484500B;;;0; 'store01~ct/200#backupgroup.snapshots.count'=1;;;0; 'store01~ct/200#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~host/srv01#backupgroup.snapshot.last.size.bytes'=53687091200B;;;0; 'store01~host/srv01#backupgroup.snapshots.count'=1;;;0; 'store01~host/srv01#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/100#backupgroup.snapshot.last.size.bytes'=118111601493B;;;0; 'store01~vm/100#backupgroup.snapshots.count'=2;;;0; 'store01~vm/100#backupgroup.snapshots.verify.failed.count'=0;;;0; 'store01~vm/101#backupgroup.snapshot.last.size.bytes'=4831839092B;;;0; 'store01~vm/101#backupgroup.snapshots.count'=2;;;0; 'store01~vm/101#backupgroup.snapshots.verify.failed.count'=1;;;0; 'store01~vm/102#backupgroup.snapshot.last.size.bytes'=34359739226B;;;0; 'store01~vm/102#backupgroup.snapshots.count'=2;;;0; 'store01~vm/102#backupgroup.snapshots.verify.failed.count'=1;;;0;

Snapshots Age ${tc}
    [Tags]    apps    proxmox    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --include-id='^100$' --filter-perfdata=age
    ...    ^OK: Backup groups total: 1, snapshots: 2 - Backup group 'vm/100' .datastore: store01. .comment: vm-100. last snapshot verification: ok, last snapshot: 2h ([1-5]s )?ago [|] 'store01~vm/100#backupgroup.snapshot.last.age.seconds'=720[0-5]s;;;0;$
    ...    2
    ...    --include-id='^102$' --filter-perfdata=age --critical-status='' --warning-last-age=93600
    ...    ^WARNING: Backup group 'vm/102' .datastore: store01. .comment: vm-102. last snapshot: 2d 2h ([1-5]s )?ago [|] 'store01~vm/102#backupgroup.snapshot.last.age.seconds'=18000[0-5]s;0:93600;;0;$
