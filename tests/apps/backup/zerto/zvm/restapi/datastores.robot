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
...                 --mode=datastores
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Datastores ${tc}
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
    ...    CRITICAL: Datastore 'ds-prod-02' health: Error, availability: Normal WARNING: Datastore 'ds-dr-01' health: Normal, availability: InMaintenance | 'datastores.total.count'=3;;;0; 'ds-prod-01#datastore.space.usage.bytes'=213157675008B;;;0;536870912000 'ds-prod-01#datastore.space.free.bytes'=323713236992B;;;0;536870912000 'ds-prod-01#datastore.space.usage.percentage'=39.70%;;;0;100 'ds-prod-01#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-01#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-01#datastore.vms.incoming.count'=0;;;0; 'ds-prod-01#datastore.vms.outgoing.count'=4;;;0; 'ds-prod-01#datastore.vras.count'=1;;;0; 'ds-prod-02#datastore.space.usage.bytes'=1044536046388B;;;0;1099511627776 'ds-prod-02#datastore.space.free.bytes'=54975581388B;;;0;1099511627776 'ds-prod-02#datastore.space.usage.percentage'=95.00%;;;0;100 'ds-prod-02#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-02#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-02#datastore.vms.incoming.count'=0;;;0; 'ds-prod-02#datastore.vms.outgoing.count'=2;;;0; 'ds-prod-02#datastore.vras.count'=0;;;0; 'ds-dr-01#datastore.space.usage.bytes'=549755813888B;;;0;2199023255552 'ds-dr-01#datastore.space.free.bytes'=1649267441664B;;;0;2199023255552 'ds-dr-01#datastore.space.usage.percentage'=25.00%;;;0;100 'ds-dr-01#datastore.zerto.journal.used.bytes'=2147483648B;;;0; 'ds-dr-01#datastore.zerto.recovery.used.bytes'=21474836480B;;;0; 'ds-dr-01#datastore.vms.incoming.count'=7;;;0; 'ds-dr-01#datastore.vms.outgoing.count'=0;;;0; 'ds-dr-01#datastore.vras.count'=2;;;0;
    ...    2
    ...    --include-cluster=dsc-prod
    ...    CRITICAL: Datastore 'ds-prod-02' health: Error, availability: Normal | 'datastores.total.count'=2;;;0; 'ds-prod-01#datastore.space.usage.bytes'=213157675008B;;;0;536870912000 'ds-prod-01#datastore.space.free.bytes'=323713236992B;;;0;536870912000 'ds-prod-01#datastore.space.usage.percentage'=39.70%;;;0;100 'ds-prod-01#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-01#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-01#datastore.vms.incoming.count'=0;;;0; 'ds-prod-01#datastore.vms.outgoing.count'=4;;;0; 'ds-prod-01#datastore.vras.count'=1;;;0; 'ds-prod-02#datastore.space.usage.bytes'=1044536046388B;;;0;1099511627776 'ds-prod-02#datastore.space.free.bytes'=54975581388B;;;0;1099511627776 'ds-prod-02#datastore.space.usage.percentage'=95.00%;;;0;100 'ds-prod-02#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-02#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-02#datastore.vms.incoming.count'=0;;;0; 'ds-prod-02#datastore.vms.outgoing.count'=2;;;0; 'ds-prod-02#datastore.vras.count'=0;;;0;
    ...    3
    ...    --exclude-name=prod-02
    ...    WARNING: Datastore 'ds-dr-01' health: Normal, availability: InMaintenance | 'datastores.total.count'=2;;;0; 'ds-prod-01#datastore.space.usage.bytes'=213157675008B;;;0;536870912000 'ds-prod-01#datastore.space.free.bytes'=323713236992B;;;0;536870912000 'ds-prod-01#datastore.space.usage.percentage'=39.70%;;;0;100 'ds-prod-01#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-01#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-01#datastore.vms.incoming.count'=0;;;0; 'ds-prod-01#datastore.vms.outgoing.count'=4;;;0; 'ds-prod-01#datastore.vras.count'=1;;;0; 'ds-dr-01#datastore.space.usage.bytes'=549755813888B;;;0;2199023255552 'ds-dr-01#datastore.space.free.bytes'=1649267441664B;;;0;2199023255552 'ds-dr-01#datastore.space.usage.percentage'=25.00%;;;0;100 'ds-dr-01#datastore.zerto.journal.used.bytes'=2147483648B;;;0; 'ds-dr-01#datastore.zerto.recovery.used.bytes'=21474836480B;;;0; 'ds-dr-01#datastore.vms.incoming.count'=7;;;0; 'ds-dr-01#datastore.vms.outgoing.count'=0;;;0; 'ds-dr-01#datastore.vras.count'=2;;;0;
    ...    4
    ...    --warning-status='' --critical-status='' --warning-usage-prct=80
    ...    WARNING: Datastore 'ds-prod-02' space usage total: 1.00 TB used: 972.80 GB (95.00%) free: 51.20 GB (5.00%) | 'datastores.total.count'=3;;;0; 'ds-prod-01#datastore.space.usage.bytes'=213157675008B;;;0;536870912000 'ds-prod-01#datastore.space.free.bytes'=323713236992B;;;0;536870912000 'ds-prod-01#datastore.space.usage.percentage'=39.70%;0:80;;0;100 'ds-prod-01#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-01#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-01#datastore.vms.incoming.count'=0;;;0; 'ds-prod-01#datastore.vms.outgoing.count'=4;;;0; 'ds-prod-01#datastore.vras.count'=1;;;0; 'ds-prod-02#datastore.space.usage.bytes'=1044536046388B;;;0;1099511627776 'ds-prod-02#datastore.space.free.bytes'=54975581388B;;;0;1099511627776 'ds-prod-02#datastore.space.usage.percentage'=95.00%;0:80;;0;100 'ds-prod-02#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-02#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-02#datastore.vms.incoming.count'=0;;;0; 'ds-prod-02#datastore.vms.outgoing.count'=2;;;0; 'ds-prod-02#datastore.vras.count'=0;;;0; 'ds-dr-01#datastore.space.usage.bytes'=549755813888B;;;0;2199023255552 'ds-dr-01#datastore.space.free.bytes'=1649267441664B;;;0;2199023255552 'ds-dr-01#datastore.space.usage.percentage'=25.00%;0:80;;0;100 'ds-dr-01#datastore.zerto.journal.used.bytes'=2147483648B;;;0; 'ds-dr-01#datastore.zerto.recovery.used.bytes'=21474836480B;;;0; 'ds-dr-01#datastore.vms.incoming.count'=7;;;0; 'ds-dr-01#datastore.vms.outgoing.count'=0;;;0; 'ds-dr-01#datastore.vras.count'=2;;;0;
    ...    5
    ...    --warning-status='' --critical-status='' --critical-journal-used=1073741824
    ...    CRITICAL: Datastore 'ds-dr-01' journal used: 2.00 GB | 'datastores.total.count'=3;;;0; 'ds-prod-01#datastore.space.usage.bytes'=213157675008B;;;0;536870912000 'ds-prod-01#datastore.space.free.bytes'=323713236992B;;;0;536870912000 'ds-prod-01#datastore.space.usage.percentage'=39.70%;;;0;100 'ds-prod-01#datastore.zerto.journal.used.bytes'=0B;;0:1073741824;0; 'ds-prod-01#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-01#datastore.vms.incoming.count'=0;;;0; 'ds-prod-01#datastore.vms.outgoing.count'=4;;;0; 'ds-prod-01#datastore.vras.count'=1;;;0; 'ds-prod-02#datastore.space.usage.bytes'=1044536046388B;;;0;1099511627776 'ds-prod-02#datastore.space.free.bytes'=54975581388B;;;0;1099511627776 'ds-prod-02#datastore.space.usage.percentage'=95.00%;;;0;100 'ds-prod-02#datastore.zerto.journal.used.bytes'=0B;;0:1073741824;0; 'ds-prod-02#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-02#datastore.vms.incoming.count'=0;;;0; 'ds-prod-02#datastore.vms.outgoing.count'=2;;;0; 'ds-prod-02#datastore.vras.count'=0;;;0; 'ds-dr-01#datastore.space.usage.bytes'=549755813888B;;;0;2199023255552 'ds-dr-01#datastore.space.free.bytes'=1649267441664B;;;0;2199023255552 'ds-dr-01#datastore.space.usage.percentage'=25.00%;;;0;100 'ds-dr-01#datastore.zerto.journal.used.bytes'=2147483648B;;0:1073741824;0; 'ds-dr-01#datastore.zerto.recovery.used.bytes'=21474836480B;;;0; 'ds-dr-01#datastore.vms.incoming.count'=7;;;0; 'ds-dr-01#datastore.vms.outgoing.count'=0;;;0; 'ds-dr-01#datastore.vras.count'=2;;;0;
    ...    6
    ...    --warning-status='' --critical-status='%\\\{availability_status\\\} =~ /Maintenance/'
    ...    CRITICAL: Datastore 'ds-dr-01' health: Normal, availability: InMaintenance | 'datastores.total.count'=3;;;0; 'ds-prod-01#datastore.space.usage.bytes'=213157675008B;;;0;536870912000 'ds-prod-01#datastore.space.free.bytes'=323713236992B;;;0;536870912000 'ds-prod-01#datastore.space.usage.percentage'=39.70%;;;0;100 'ds-prod-01#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-01#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-01#datastore.vms.incoming.count'=0;;;0; 'ds-prod-01#datastore.vms.outgoing.count'=4;;;0; 'ds-prod-01#datastore.vras.count'=1;;;0; 'ds-prod-02#datastore.space.usage.bytes'=1044536046388B;;;0;1099511627776 'ds-prod-02#datastore.space.free.bytes'=54975581388B;;;0;1099511627776 'ds-prod-02#datastore.space.usage.percentage'=95.00%;;;0;100 'ds-prod-02#datastore.zerto.journal.used.bytes'=0B;;;0; 'ds-prod-02#datastore.zerto.recovery.used.bytes'=0B;;;0; 'ds-prod-02#datastore.vms.incoming.count'=0;;;0; 'ds-prod-02#datastore.vms.outgoing.count'=2;;;0; 'ds-prod-02#datastore.vras.count'=0;;;0; 'ds-dr-01#datastore.space.usage.bytes'=549755813888B;;;0;2199023255552 'ds-dr-01#datastore.space.free.bytes'=1649267441664B;;;0;2199023255552 'ds-dr-01#datastore.space.usage.percentage'=25.00%;;;0;100 'ds-dr-01#datastore.zerto.journal.used.bytes'=2147483648B;;;0; 'ds-dr-01#datastore.zerto.recovery.used.bytes'=21474836480B;;;0; 'ds-dr-01#datastore.vms.incoming.count'=7;;;0; 'ds-dr-01#datastore.vms.outgoing.count'=0;;;0; 'ds-dr-01#datastore.vras.count'=2;;;0;
