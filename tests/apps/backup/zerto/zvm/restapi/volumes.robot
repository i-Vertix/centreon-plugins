*** Settings ***
Documentation       apps::backup::zerto::zvm::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}zvm.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::zerto::zvm::restapi::plugin
...                 --mode=volumes
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Volumes ${tc}
    [Tags]    apps    backup    zerto    restapi
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
    ...    OK: All volume types are ok - All volumes are ok | 'Appliances#volumes.total.count'=1;;;0; 'Appliances#volumes.space.used.bytes'=13422821376B;;;0; 'Appliances#volumes.space.provisioned.bytes'=13422821376B;;;0; 'Journal#volumes.total.count'=1;;;0; 'Journal#volumes.space.used.bytes'=2147483648B;;;0; 'Journal#volumes.space.provisioned.bytes'=4294967296B;;;0; 'Protected#volumes.total.count'=2;;;0; 'Protected#volumes.space.used.bytes'=128849018880B;;;0; 'Protected#volumes.space.provisioned.bytes'=257698037760B;;;0; 'Recovery#volumes.total.count'=1;;;0; 'Recovery#volumes.space.used.bytes'=21474836480B;;;0; 'Recovery#volumes.space.provisioned.bytes'=42949672960B;;;0; '[ds-prod-01] Z-VRA-esx01/Z-VRA-esx01.vmdk#volume.space.used.bytes'=13422821376B;;;0; '[ds-prod-01] Z-VRA-esx01/Z-VRA-esx01.vmdk#volume.space.provisioned.bytes'=13422821376B;;;0; '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk#volume.space.used.bytes'=2147483648B;;;0; '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk#volume.space.provisioned.bytes'=4294967296B;;;0; '[ds-prod-01] web01/web01.vmdk#volume.space.used.bytes'=21474836480B;;;0; '[ds-prod-01] web01/web01.vmdk#volume.space.provisioned.bytes'=42949672960B;;;0; '[ds-prod-02] erp-db01/erp-db01.vmdk#volume.space.used.bytes'=107374182400B;;;0; '[ds-prod-02] erp-db01/erp-db01.vmdk#volume.space.provisioned.bytes'=214748364800B;;;0; '[ds-dr-01] Z-VRA-esx02/web01-recovery.vmdk#volume.space.used.bytes'=21474836480B;;;0; '[ds-dr-01] Z-VRA-esx02/web01-recovery.vmdk#volume.space.provisioned.bytes'=42949672960B;;;0;
    ...    2
    ...    --volume-type=Journal
    ...    OK: Volume type 'Journal' volumes: 1, used: 2.00 GB, provisioned: 4.00 GB - Volume '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk' [type: Journal] used: 2.00 GB | 'Journal#volumes.total.count'=1;;;0; 'Journal#volumes.space.used.bytes'=2147483648B;;;0; 'Journal#volumes.space.provisioned.bytes'=4294967296B;;;0; '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk#volume.space.used.bytes'=2147483648B;;;0; '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk#volume.space.provisioned.bytes'=4294967296B;;;0;
    ...    3
    ...    --skip-volumes
    ...    OK: All volume types are ok | 'Appliances#volumes.total.count'=1;;;0; 'Appliances#volumes.space.used.bytes'=13422821376B;;;0; 'Appliances#volumes.space.provisioned.bytes'=13422821376B;;;0; 'Journal#volumes.total.count'=1;;;0; 'Journal#volumes.space.used.bytes'=2147483648B;;;0; 'Journal#volumes.space.provisioned.bytes'=4294967296B;;;0; 'Protected#volumes.total.count'=2;;;0; 'Protected#volumes.space.used.bytes'=128849018880B;;;0; 'Protected#volumes.space.provisioned.bytes'=257698037760B;;;0; 'Recovery#volumes.total.count'=1;;;0; 'Recovery#volumes.space.used.bytes'=21474836480B;;;0; 'Recovery#volumes.space.provisioned.bytes'=42949672960B;;;0;
    ...    4
    ...    --include-vm=web01
    ...    OK: All volume types are ok - All volumes are ok | 'Journal#volumes.total.count'=1;;;0; 'Journal#volumes.space.used.bytes'=2147483648B;;;0; 'Journal#volumes.space.provisioned.bytes'=4294967296B;;;0; 'Protected#volumes.total.count'=1;;;0; 'Protected#volumes.space.used.bytes'=21474836480B;;;0; 'Protected#volumes.space.provisioned.bytes'=42949672960B;;;0; 'Recovery#volumes.total.count'=1;;;0; 'Recovery#volumes.space.used.bytes'=21474836480B;;;0; 'Recovery#volumes.space.provisioned.bytes'=42949672960B;;;0; '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk#volume.space.used.bytes'=2147483648B;;;0; '[ds-dr-01] Z-VRA-esx02/journal-web01.vmdk#volume.space.provisioned.bytes'=4294967296B;;;0; '[ds-prod-01] web01/web01.vmdk#volume.space.used.bytes'=21474836480B;;;0; '[ds-prod-01] web01/web01.vmdk#volume.space.provisioned.bytes'=42949672960B;;;0; '[ds-dr-01] Z-VRA-esx02/web01-recovery.vmdk#volume.space.used.bytes'=21474836480B;;;0; '[ds-dr-01] Z-VRA-esx02/web01-recovery.vmdk#volume.space.provisioned.bytes'=42949672960B;;;0;
    ...    5
    ...    --include-datastore=ds-dr --skip-volumes
    ...    OK: All volume types are ok | 'Journal#volumes.total.count'=1;;;0; 'Journal#volumes.space.used.bytes'=2147483648B;;;0; 'Journal#volumes.space.provisioned.bytes'=4294967296B;;;0; 'Recovery#volumes.total.count'=1;;;0; 'Recovery#volumes.space.used.bytes'=21474836480B;;;0; 'Recovery#volumes.space.provisioned.bytes'=42949672960B;;;0;
    ...    6
    ...    --skip-volumes --critical-type-used=100000000000
    ...    CRITICAL: Volume type 'Protected' used: 120.00 GB | 'Appliances#volumes.total.count'=1;;;0; 'Appliances#volumes.space.used.bytes'=13422821376B;;0:100000000000;0; 'Appliances#volumes.space.provisioned.bytes'=13422821376B;;;0; 'Journal#volumes.total.count'=1;;;0; 'Journal#volumes.space.used.bytes'=2147483648B;;0:100000000000;0; 'Journal#volumes.space.provisioned.bytes'=4294967296B;;;0; 'Protected#volumes.total.count'=2;;;0; 'Protected#volumes.space.used.bytes'=128849018880B;;0:100000000000;0; 'Protected#volumes.space.provisioned.bytes'=257698037760B;;;0; 'Recovery#volumes.total.count'=1;;;0; 'Recovery#volumes.space.used.bytes'=21474836480B;;0:100000000000;0; 'Recovery#volumes.space.provisioned.bytes'=42949672960B;;;0;
    ...    7
    ...    --include-name=erp --warning-used=50000000000
    ...    WARNING: Volume '[ds-prod-02] erp-db01/erp-db01.vmdk' [type: Protected] used: 100.00 GB | 'Protected#volumes.total.count'=1;;;0; 'Protected#volumes.space.used.bytes'=107374182400B;;;0; 'Protected#volumes.space.provisioned.bytes'=214748364800B;;;0; '[ds-prod-02] erp-db01/erp-db01.vmdk#volume.space.used.bytes'=107374182400B;0:50000000000;;0; '[ds-prod-02] erp-db01/erp-db01.vmdk#volume.space.provisioned.bytes'=214748364800B;;;0;
    ...    8
    ...    --volume-type=Other
    ...    UNKNOWN: Unknown volume type 'Other'. Accepted values: Protected, Recovery, Journal, Scratch, Appliances, Unknown.
