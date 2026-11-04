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
...                 --mode=vpgs
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zvm-monitoring
...                 --client-secret=secret-123


*** Test Cases ***
Vpgs ${tc}
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
    ...    --filter-counters='^(?!last-failover-test)'
    ...    CRITICAL: VPG 'file-server' status: NotMeetingSLA, substatus: JournalStorageError WARNING: VPG 'erp-database' status: RpoNotMeetingSLA, substatus: DeltaSync | 'vpgs.total.count'=4;;;0; 'vpgs.sla.meeting.count'=1;;;0;4 'vpgs.sla.notmeeting.count'=2;;;0;4 'vpgs.initializing.count'=1;;;0;4 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=840s;;;0; 'erp-database#vpg.history.actual.seconds'=72000s;;;0; 'erp-database#vpg.operation.progress.percentage'=37.50%;;;0;100 'erp-database#vpg.io.operations.persecond'=310iops;;;0; 'erp-database#vpg.throughput.bytespersecond'=12845056B/s;;;0; 'erp-database#vpg.storage.used.bytes'=107374182400B;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.rpo.actual.seconds'=4200s;;;0; 'file-server#vpg.history.actual.seconds'=3600s;;;0; 'file-server#vpg.operation.progress.percentage'=0.00%;;;0;100 'file-server#vpg.io.operations.persecond'=0iops;;;0; 'file-server#vpg.throughput.bytespersecond'=0B/s;;;0; 'file-server#vpg.storage.used.bytes'=53687091200B;;;0; 'file-server#vpg.vms.protected.count'=1;;;0; 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    2
    ...    --filter-counters='^(?!last-failover-test)' --include-name=web
    ...    OK: VPGs meeting SLA: 1, not meeting SLA: 0, initializing: 0 - VPG 'web-frontend' status: MeetingSLA, substatus: None, actual RPO: 8s (configured: 5m), actual history: 1d (configured: 1d) | 'vpgs.total.count'=1;;;0; 'vpgs.sla.meeting.count'=1;;;0;1 'vpgs.sla.notmeeting.count'=0;;;0;1 'vpgs.initializing.count'=0;;;0;1 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0;
    ...    3
    ...    --filter-counters='^(?!last-failover-test)' --exclude-name='erp|file'
    ...    OK: VPGs meeting SLA: 1, not meeting SLA: 0, initializing: 1 - All VPGs are ok | 'vpgs.total.count'=2;;;0; 'vpgs.sla.meeting.count'=1;;;0;2 'vpgs.sla.notmeeting.count'=0;;;0;2 'vpgs.initializing.count'=1;;;0;2 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    4
    ...    --filter-counters='^(?!last-failover-test)' --include-id='0004$'
    ...    OK: VPGs meeting SLA: 0, not meeting SLA: 0, initializing: 1 - VPG 'archive' status: Initializing, substatus: InitialSync, actual history: 0s (configured: 12h) | 'vpgs.total.count'=1;;;0; 'vpgs.sla.meeting.count'=0;;;0;1 'vpgs.sla.notmeeting.count'=0;;;0;1 'vpgs.initializing.count'=1;;;0;1 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    5
    ...    --filter-counters='^(?!last-failover-test)' --warning-status='' --critical-status=''
    ...    OK: VPGs meeting SLA: 1, not meeting SLA: 2, initializing: 1 - All VPGs are ok | 'vpgs.total.count'=4;;;0; 'vpgs.sla.meeting.count'=1;;;0;4 'vpgs.sla.notmeeting.count'=2;;;0;4 'vpgs.initializing.count'=1;;;0;4 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=840s;;;0; 'erp-database#vpg.history.actual.seconds'=72000s;;;0; 'erp-database#vpg.operation.progress.percentage'=37.50%;;;0;100 'erp-database#vpg.io.operations.persecond'=310iops;;;0; 'erp-database#vpg.throughput.bytespersecond'=12845056B/s;;;0; 'erp-database#vpg.storage.used.bytes'=107374182400B;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.rpo.actual.seconds'=4200s;;;0; 'file-server#vpg.history.actual.seconds'=3600s;;;0; 'file-server#vpg.operation.progress.percentage'=0.00%;;;0;100 'file-server#vpg.io.operations.persecond'=0iops;;;0; 'file-server#vpg.throughput.bytespersecond'=0B/s;;;0; 'file-server#vpg.storage.used.bytes'=53687091200B;;;0; 'file-server#vpg.vms.protected.count'=1;;;0; 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    6
    ...    --filter-counters='^(?!last-failover-test)' --warning-status='' --critical-status='%\\\{substatus\\\} =~ /InitialSync/'
    ...    CRITICAL: VPG 'archive' status: Initializing, substatus: InitialSync | 'vpgs.total.count'=4;;;0; 'vpgs.sla.meeting.count'=1;;;0;4 'vpgs.sla.notmeeting.count'=2;;;0;4 'vpgs.initializing.count'=1;;;0;4 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=840s;;;0; 'erp-database#vpg.history.actual.seconds'=72000s;;;0; 'erp-database#vpg.operation.progress.percentage'=37.50%;;;0;100 'erp-database#vpg.io.operations.persecond'=310iops;;;0; 'erp-database#vpg.throughput.bytespersecond'=12845056B/s;;;0; 'erp-database#vpg.storage.used.bytes'=107374182400B;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.rpo.actual.seconds'=4200s;;;0; 'file-server#vpg.history.actual.seconds'=3600s;;;0; 'file-server#vpg.operation.progress.percentage'=0.00%;;;0;100 'file-server#vpg.io.operations.persecond'=0iops;;;0; 'file-server#vpg.throughput.bytespersecond'=0B/s;;;0; 'file-server#vpg.storage.used.bytes'=53687091200B;;;0; 'file-server#vpg.vms.protected.count'=1;;;0; 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    7
    ...    --filter-counters='^(?!last-failover-test)' --warning-actual-rpo=600 --critical-actual-rpo=3600
    ...    CRITICAL: VPG 'file-server' status: NotMeetingSLA, substatus: JournalStorageError, actual RPO: 1h 10m (configured: 5m) WARNING: VPG 'erp-database' status: RpoNotMeetingSLA, substatus: DeltaSync, actual RPO: 14m (configured: 5m) | 'vpgs.total.count'=4;;;0; 'vpgs.sla.meeting.count'=1;;;0;4 'vpgs.sla.notmeeting.count'=2;;;0;4 'vpgs.initializing.count'=1;;;0;4 'web-frontend#vpg.rpo.actual.seconds'=8s;0:600;0:3600;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=840s;0:600;0:3600;0; 'erp-database#vpg.history.actual.seconds'=72000s;;;0; 'erp-database#vpg.operation.progress.percentage'=37.50%;;;0;100 'erp-database#vpg.io.operations.persecond'=310iops;;;0; 'erp-database#vpg.throughput.bytespersecond'=12845056B/s;;;0; 'erp-database#vpg.storage.used.bytes'=107374182400B;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.rpo.actual.seconds'=4200s;0:600;0:3600;0; 'file-server#vpg.history.actual.seconds'=3600s;;;0; 'file-server#vpg.operation.progress.percentage'=0.00%;;;0;100 'file-server#vpg.io.operations.persecond'=0iops;;;0; 'file-server#vpg.throughput.bytespersecond'=0B/s;;;0; 'file-server#vpg.storage.used.bytes'=53687091200B;;;0; 'file-server#vpg.vms.protected.count'=1;;;0; 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    8
    ...    --filter-counters='^(?!last-failover-test)' --critical-actual-history=7200:
    ...    CRITICAL: VPG 'file-server' status: NotMeetingSLA, substatus: JournalStorageError, actual history: 1h (configured: 1d) - VPG 'archive' actual history: 0s (configured: 12h) WARNING: VPG 'erp-database' status: RpoNotMeetingSLA, substatus: DeltaSync | 'vpgs.total.count'=4;;;0; 'vpgs.sla.meeting.count'=1;;;0;4 'vpgs.sla.notmeeting.count'=2;;;0;4 'vpgs.initializing.count'=1;;;0;4 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;7200:;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=840s;;;0; 'erp-database#vpg.history.actual.seconds'=72000s;;7200:;0; 'erp-database#vpg.operation.progress.percentage'=37.50%;;;0;100 'erp-database#vpg.io.operations.persecond'=310iops;;;0; 'erp-database#vpg.throughput.bytespersecond'=12845056B/s;;;0; 'erp-database#vpg.storage.used.bytes'=107374182400B;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.rpo.actual.seconds'=4200s;;;0; 'file-server#vpg.history.actual.seconds'=3600s;;7200:;0; 'file-server#vpg.operation.progress.percentage'=0.00%;;;0;100 'file-server#vpg.io.operations.persecond'=0iops;;;0; 'file-server#vpg.throughput.bytespersecond'=0B/s;;;0; 'file-server#vpg.storage.used.bytes'=53687091200B;;;0; 'file-server#vpg.vms.protected.count'=1;;;0; 'archive#vpg.history.actual.seconds'=0s;;7200:;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    9
    ...    --filter-counters='^(?!last-failover-test)' --warning-vpgs-not-meeting-sla=0
    ...    CRITICAL: VPG 'file-server' status: NotMeetingSLA, substatus: JournalStorageError WARNING: VPGs not meeting SLA: 2 - VPG 'erp-database' status: RpoNotMeetingSLA, substatus: DeltaSync | 'vpgs.total.count'=4;;;0; 'vpgs.sla.meeting.count'=1;;;0;4 'vpgs.sla.notmeeting.count'=2;0:0;;0;4 'vpgs.initializing.count'=1;;;0;4 'web-frontend#vpg.rpo.actual.seconds'=8s;;;0; 'web-frontend#vpg.history.actual.seconds'=86400s;;;0; 'web-frontend#vpg.operation.progress.percentage'=0.00%;;;0;100 'web-frontend#vpg.io.operations.persecond'=42iops;;;0; 'web-frontend#vpg.throughput.bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg.storage.used.bytes'=21474836480B;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=840s;;;0; 'erp-database#vpg.history.actual.seconds'=72000s;;;0; 'erp-database#vpg.operation.progress.percentage'=37.50%;;;0;100 'erp-database#vpg.io.operations.persecond'=310iops;;;0; 'erp-database#vpg.throughput.bytespersecond'=12845056B/s;;;0; 'erp-database#vpg.storage.used.bytes'=107374182400B;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.rpo.actual.seconds'=4200s;;;0; 'file-server#vpg.history.actual.seconds'=3600s;;;0; 'file-server#vpg.operation.progress.percentage'=0.00%;;;0;100 'file-server#vpg.io.operations.persecond'=0iops;;;0; 'file-server#vpg.throughput.bytespersecond'=0B/s;;;0; 'file-server#vpg.storage.used.bytes'=53687091200B;;;0; 'file-server#vpg.vms.protected.count'=1;;;0; 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;
    ...    10
    ...    --filter-counters='^(?!last-failover-test)' --critical-progress=50: --include-name=archive
    ...    CRITICAL: VPG 'archive' operation progress: 42.00% | 'vpgs.total.count'=1;;;0; 'vpgs.sla.meeting.count'=0;;;0;1 'vpgs.sla.notmeeting.count'=0;;;0;1 'vpgs.initializing.count'=1;;;0;1 'archive#vpg.history.actual.seconds'=0s;;;0; 'archive#vpg.operation.progress.percentage'=42.00%;;50:;0;100 'archive#vpg.io.operations.persecond'=5iops;;;0; 'archive#vpg.throughput.bytespersecond'=524288B/s;;;0; 'archive#vpg.storage.used.bytes'=1073741824B;;;0; 'archive#vpg.vms.protected.count'=1;;;0;

Vpgs regexp ${tc}
    [Tags]    apps    backup    zerto    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    11
    ...    --include-name=web --warning-last-failover-test=604800
    ...    ^WARNING: VPG 'web-frontend' last failover test: [0-9wdhms ]+ ago [|] 'vpgs[.]total[.]count'=1;;;0; 'vpgs[.]sla[.]meeting[.]count'=1;;;0;1 'vpgs[.]sla[.]notmeeting[.]count'=0;;;0;1 'vpgs[.]initializing[.]count'=0;;;0;1 'web-frontend#vpg[.]rpo[.]actual[.]seconds'=8s;;;0; 'web-frontend#vpg[.]history[.]actual[.]seconds'=86400s;;;0; 'web-frontend#vpg[.]failovertest[.]last[.]seconds'=[0-9]+s;0:604800;;0; 'web-frontend#vpg[.]operation[.]progress[.]percentage'=0[.]00%;;;0;100 'web-frontend#vpg[.]io[.]operations[.]persecond'=42iops;;;0; 'web-frontend#vpg[.]throughput[.]bytespersecond'=1572864B/s;;;0; 'web-frontend#vpg[.]storage[.]used[.]bytes'=21474836480B;;;0; 'web-frontend#vpg[.]vms[.]protected[.]count'=3;;;0;$
