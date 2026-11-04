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
...                 --mode=vms
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Vms ${tc}
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
    ...    CRITICAL: VM 'fs01' [vpg: file-server] status: NotMeetingSLA, substatus: JournalStorageError WARNING: VM 'erp-db01' [vpg: erp-database] status: RpoNotMeetingSLA, substatus: DeltaSync | 'vms.total.count'=4;;;0; 'vms.sla.meeting.count'=2;;;0;4 'vms.sla.notmeeting.count'=2;;;0;4 'web01#vm.rpo.actual.seconds'=8s;;;0; 'web01#vm.journal.usage.bytes'=2147483648B;;;0; 'web01#vm.journal.usage.percentage'=1.33%;;;0;100 'web01#vm.io.operations.persecond'=12iops;;;0; 'web01#vm.throughput.bytespersecond'=524288B/s;;;0; 'web01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web01#vm.storage.used.bytes'=10737418240B;;;0; 'web02#vm.rpo.actual.seconds'=9s;;;0; 'web02#vm.journal.usage.bytes'=1073741824B;;;0; 'web02#vm.io.operations.persecond'=12iops;;;0; 'web02#vm.throughput.bytespersecond'=524288B/s;;;0; 'web02#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web02#vm.storage.used.bytes'=10737418240B;;;0; 'erp-db01#vm.rpo.actual.seconds'=840s;;;0; 'erp-db01#vm.journal.usage.bytes'=146800640000B;;;0; 'erp-db01#vm.journal.usage.percentage'=91.15%;;;0;100 'erp-db01#vm.io.operations.persecond'=12iops;;;0; 'erp-db01#vm.throughput.bytespersecond'=524288B/s;;;0; 'erp-db01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'erp-db01#vm.storage.used.bytes'=107374182400B;;;0; 'fs01#vm.rpo.actual.seconds'=4200s;;;0; 'fs01#vm.journal.usage.bytes'=0B;;;0; 'fs01#vm.io.operations.persecond'=12iops;;;0; 'fs01#vm.throughput.bytespersecond'=524288B/s;;;0; 'fs01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'fs01#vm.storage.used.bytes'=53687091200B;;;0;
    ...    2
    ...    --include-vpg=web
    ...    OK: VMs meeting SLA: 2, not meeting SLA: 0 - All VMs are ok | 'vms.total.count'=2;;;0; 'vms.sla.meeting.count'=2;;;0;2 'vms.sla.notmeeting.count'=0;;;0;2 'web01#vm.rpo.actual.seconds'=8s;;;0; 'web01#vm.journal.usage.bytes'=2147483648B;;;0; 'web01#vm.journal.usage.percentage'=1.33%;;;0;100 'web01#vm.io.operations.persecond'=12iops;;;0; 'web01#vm.throughput.bytespersecond'=524288B/s;;;0; 'web01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web01#vm.storage.used.bytes'=10737418240B;;;0; 'web02#vm.rpo.actual.seconds'=9s;;;0; 'web02#vm.journal.usage.bytes'=1073741824B;;;0; 'web02#vm.io.operations.persecond'=12iops;;;0; 'web02#vm.throughput.bytespersecond'=524288B/s;;;0; 'web02#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web02#vm.storage.used.bytes'=10737418240B;;;0;
    ...    3
    ...    --exclude-name='fs01|erp'
    ...    OK: VMs meeting SLA: 2, not meeting SLA: 0 - All VMs are ok | 'vms.total.count'=2;;;0; 'vms.sla.meeting.count'=2;;;0;2 'vms.sla.notmeeting.count'=0;;;0;2 'web01#vm.rpo.actual.seconds'=8s;;;0; 'web01#vm.journal.usage.bytes'=2147483648B;;;0; 'web01#vm.journal.usage.percentage'=1.33%;;;0;100 'web01#vm.io.operations.persecond'=12iops;;;0; 'web01#vm.throughput.bytespersecond'=524288B/s;;;0; 'web01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web01#vm.storage.used.bytes'=10737418240B;;;0; 'web02#vm.rpo.actual.seconds'=9s;;;0; 'web02#vm.journal.usage.bytes'=1073741824B;;;0; 'web02#vm.io.operations.persecond'=12iops;;;0; 'web02#vm.throughput.bytespersecond'=524288B/s;;;0; 'web02#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web02#vm.storage.used.bytes'=10737418240B;;;0;
    ...    4
    ...    --warning-status='' --critical-status='' --warning-journal-usage-prct=80
    ...    WARNING: VM 'erp-db01' [vpg: erp-database] journal used: 91.15% of hard limit 150.00 GB | 'vms.total.count'=4;;;0; 'vms.sla.meeting.count'=2;;;0;4 'vms.sla.notmeeting.count'=2;;;0;4 'web01#vm.rpo.actual.seconds'=8s;;;0; 'web01#vm.journal.usage.bytes'=2147483648B;;;0; 'web01#vm.journal.usage.percentage'=1.33%;0:80;;0;100 'web01#vm.io.operations.persecond'=12iops;;;0; 'web01#vm.throughput.bytespersecond'=524288B/s;;;0; 'web01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web01#vm.storage.used.bytes'=10737418240B;;;0; 'web02#vm.rpo.actual.seconds'=9s;;;0; 'web02#vm.journal.usage.bytes'=1073741824B;;;0; 'web02#vm.io.operations.persecond'=12iops;;;0; 'web02#vm.throughput.bytespersecond'=524288B/s;;;0; 'web02#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web02#vm.storage.used.bytes'=10737418240B;;;0; 'erp-db01#vm.rpo.actual.seconds'=840s;;;0; 'erp-db01#vm.journal.usage.bytes'=146800640000B;;;0; 'erp-db01#vm.journal.usage.percentage'=91.15%;0:80;;0;100 'erp-db01#vm.io.operations.persecond'=12iops;;;0; 'erp-db01#vm.throughput.bytespersecond'=524288B/s;;;0; 'erp-db01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'erp-db01#vm.storage.used.bytes'=107374182400B;;;0; 'fs01#vm.rpo.actual.seconds'=4200s;;;0; 'fs01#vm.journal.usage.bytes'=0B;;;0; 'fs01#vm.io.operations.persecond'=12iops;;;0; 'fs01#vm.throughput.bytespersecond'=524288B/s;;;0; 'fs01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'fs01#vm.storage.used.bytes'=53687091200B;;;0;
    ...    5
    ...    --warning-status='' --critical-status='' --critical-actual-rpo=600
    ...    CRITICAL: VM 'erp-db01' [vpg: erp-database] actual RPO: 14m - VM 'fs01' [vpg: file-server] actual RPO: 1h 10m | 'vms.total.count'=4;;;0; 'vms.sla.meeting.count'=2;;;0;4 'vms.sla.notmeeting.count'=2;;;0;4 'web01#vm.rpo.actual.seconds'=8s;;0:600;0; 'web01#vm.journal.usage.bytes'=2147483648B;;;0; 'web01#vm.journal.usage.percentage'=1.33%;;;0;100 'web01#vm.io.operations.persecond'=12iops;;;0; 'web01#vm.throughput.bytespersecond'=524288B/s;;;0; 'web01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web01#vm.storage.used.bytes'=10737418240B;;;0; 'web02#vm.rpo.actual.seconds'=9s;;0:600;0; 'web02#vm.journal.usage.bytes'=1073741824B;;;0; 'web02#vm.io.operations.persecond'=12iops;;;0; 'web02#vm.throughput.bytespersecond'=524288B/s;;;0; 'web02#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web02#vm.storage.used.bytes'=10737418240B;;;0; 'erp-db01#vm.rpo.actual.seconds'=840s;;0:600;0; 'erp-db01#vm.journal.usage.bytes'=146800640000B;;;0; 'erp-db01#vm.journal.usage.percentage'=91.15%;;;0;100 'erp-db01#vm.io.operations.persecond'=12iops;;;0; 'erp-db01#vm.throughput.bytespersecond'=524288B/s;;;0; 'erp-db01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'erp-db01#vm.storage.used.bytes'=107374182400B;;;0; 'fs01#vm.rpo.actual.seconds'=4200s;;0:600;0; 'fs01#vm.journal.usage.bytes'=0B;;;0; 'fs01#vm.io.operations.persecond'=12iops;;;0; 'fs01#vm.throughput.bytespersecond'=524288B/s;;;0; 'fs01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'fs01#vm.storage.used.bytes'=53687091200B;;;0;
    ...    6
    ...    --warning-status='' --critical-status=''
    ...    OK: VMs meeting SLA: 2, not meeting SLA: 2 - All VMs are ok | 'vms.total.count'=4;;;0; 'vms.sla.meeting.count'=2;;;0;4 'vms.sla.notmeeting.count'=2;;;0;4 'web01#vm.rpo.actual.seconds'=8s;;;0; 'web01#vm.journal.usage.bytes'=2147483648B;;;0; 'web01#vm.journal.usage.percentage'=1.33%;;;0;100 'web01#vm.io.operations.persecond'=12iops;;;0; 'web01#vm.throughput.bytespersecond'=524288B/s;;;0; 'web01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web01#vm.storage.used.bytes'=10737418240B;;;0; 'web02#vm.rpo.actual.seconds'=9s;;;0; 'web02#vm.journal.usage.bytes'=1073741824B;;;0; 'web02#vm.io.operations.persecond'=12iops;;;0; 'web02#vm.throughput.bytespersecond'=524288B/s;;;0; 'web02#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'web02#vm.storage.used.bytes'=10737418240B;;;0; 'erp-db01#vm.rpo.actual.seconds'=840s;;;0; 'erp-db01#vm.journal.usage.bytes'=146800640000B;;;0; 'erp-db01#vm.journal.usage.percentage'=91.15%;;;0;100 'erp-db01#vm.io.operations.persecond'=12iops;;;0; 'erp-db01#vm.throughput.bytespersecond'=524288B/s;;;0; 'erp-db01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'erp-db01#vm.storage.used.bytes'=107374182400B;;;0; 'fs01#vm.rpo.actual.seconds'=4200s;;;0; 'fs01#vm.journal.usage.bytes'=0B;;;0; 'fs01#vm.io.operations.persecond'=12iops;;;0; 'fs01#vm.throughput.bytespersecond'=524288B/s;;;0; 'fs01#vm.bandwidth.outgoing.bitspersecond'=4486816b/s;;;0; 'fs01#vm.storage.used.bytes'=53687091200B;;;0;
