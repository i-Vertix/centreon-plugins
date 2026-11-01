*** Settings ***
Documentation       apps::backup::zerto::zic::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}zic.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::zerto::zic::restapi::plugin
...                 --mode=vpgs
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --client-id=zic-monitoring
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
    ...    --filter-counters='^(?!last-)'
    ...    CRITICAL: VPG 'erp-database' state: Protecting, protection status: RpoNotMeetingSLA - VPG 'file-server' state: NeedsConfiguration, protection status: Initializing | 'vpgs.total.count'=3;;;0; 'vpgs.sla.meeting.count'=1;;;0;3 'vpgs.sla.notmeeting.count'=1;;;0;3 'vpgs.initializing.count'=1;;;0;3 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=2820s;;;0; 'erp-database#vpg.history.actual.seconds'=82800s;;;0; 'erp-database#vpg.sync.progress.percentage'=100%;;;0;100 'erp-database#vpg.replication.issues.count'=1;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;;0;100 'file-server#vpg.replication.issues.count'=0;;;0; 'file-server#vpg.vms.protected.count'=1;;;0;
    ...    2
    ...    --filter-counters='^(?!last-)' --include-name=web
    ...    OK: VPGs meeting SLA: 1, not meeting SLA: 0, initializing: 0, without data: 1 - VPG 'web-frontend' state: Protecting, protection status: MeetingSLA, actual RPO: 12m 30s (configured: 15m), actual history: 1d 2h (configured: 1d), replication issues: 0 | 'vpgs.total.count'=1;;;0; 'vpgs.sla.meeting.count'=1;;;0;1 'vpgs.sla.notmeeting.count'=0;;;0;1 'vpgs.initializing.count'=0;;;0;1 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0;
    ...    3
    ...    --filter-counters='^(?!last-)' --exclude-name='erp|file'
    ...    OK: VPGs meeting SLA: 1, not meeting SLA: 0, initializing: 0, without data: 1 - VPG 'web-frontend' state: Protecting, protection status: MeetingSLA, actual RPO: 12m 30s (configured: 15m), actual history: 1d 2h (configured: 1d), replication issues: 0 | 'vpgs.total.count'=1;;;0; 'vpgs.sla.meeting.count'=1;;;0;1 'vpgs.sla.notmeeting.count'=0;;;0;1 'vpgs.initializing.count'=0;;;0;1 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0;
    ...    4
    ...    --filter-counters='^(?!last-)' --include-protected-region=eu-west-1
    ...    OK: VPGs meeting SLA: 0, not meeting SLA: 0, initializing: 0, without data: 1 | 'vpgs.total.count'=0;;;0; 'vpgs.sla.meeting.count'=0;;;0;0 'vpgs.sla.notmeeting.count'=0;;;0;0 'vpgs.initializing.count'=0;;;0;0 'vpgs.withoutdata.count'=1;;;0;
    ...    5
    ...    --filter-counters='^(?!last-)' --include-id='^vpg-0003\\\\z'
    ...    CRITICAL: VPG 'file-server' state: NeedsConfiguration, protection status: Initializing | 'vpgs.total.count'=1;;;0; 'vpgs.sla.meeting.count'=0;;;0;1 'vpgs.sla.notmeeting.count'=0;;;0;1 'vpgs.initializing.count'=1;;;0;1 'vpgs.withoutdata.count'=0;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;;0;100 'file-server#vpg.replication.issues.count'=0;;;0; 'file-server#vpg.vms.protected.count'=1;;;0;
    ...    6
    ...    --filter-counters='^(?!last-)' --warning-status='' --critical-status=''
    ...    OK: VPGs meeting SLA: 1, not meeting SLA: 1, initializing: 1, without data: 1 - All VPGs are ok | 'vpgs.total.count'=3;;;0; 'vpgs.sla.meeting.count'=1;;;0;3 'vpgs.sla.notmeeting.count'=1;;;0;3 'vpgs.initializing.count'=1;;;0;3 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=2820s;;;0; 'erp-database#vpg.history.actual.seconds'=82800s;;;0; 'erp-database#vpg.sync.progress.percentage'=100%;;;0;100 'erp-database#vpg.replication.issues.count'=1;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;;0;100 'file-server#vpg.replication.issues.count'=0;;;0; 'file-server#vpg.vms.protected.count'=1;;;0;
    ...    7
    ...    --filter-counters='^(?!last-)' --critical-actual-rpo=1800
    ...    CRITICAL: VPG 'erp-database' state: Protecting, protection status: RpoNotMeetingSLA, actual RPO: 47m (configured: 15m) - VPG 'file-server' state: NeedsConfiguration, protection status: Initializing | 'vpgs.total.count'=3;;;0; 'vpgs.sla.meeting.count'=1;;;0;3 'vpgs.sla.notmeeting.count'=1;;;0;3 'vpgs.initializing.count'=1;;;0;3 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;0:1800;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=2820s;;0:1800;0; 'erp-database#vpg.history.actual.seconds'=82800s;;;0; 'erp-database#vpg.sync.progress.percentage'=100%;;;0;100 'erp-database#vpg.replication.issues.count'=1;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;;0;100 'file-server#vpg.replication.issues.count'=0;;;0; 'file-server#vpg.vms.protected.count'=1;;;0;
    ...    8
    ...    --filter-counters='^(?!last-)' --warning-replication-issues=0
    ...    CRITICAL: VPG 'erp-database' state: Protecting, protection status: RpoNotMeetingSLA, replication issues: 1 - VPG 'file-server' state: NeedsConfiguration, protection status: Initializing | 'vpgs.total.count'=3;;;0; 'vpgs.sla.meeting.count'=1;;;0;3 'vpgs.sla.notmeeting.count'=1;;;0;3 'vpgs.initializing.count'=1;;;0;3 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;0:0;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=2820s;;;0; 'erp-database#vpg.history.actual.seconds'=82800s;;;0; 'erp-database#vpg.sync.progress.percentage'=100%;;;0;100 'erp-database#vpg.replication.issues.count'=1;0:0;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;;0;100 'file-server#vpg.replication.issues.count'=0;0:0;;0; 'file-server#vpg.vms.protected.count'=1;;;0;
    ...    9
    ...    --filter-counters='^(?!last-)' --critical-sync-progress=50:
    ...    CRITICAL: VPG 'erp-database' state: Protecting, protection status: RpoNotMeetingSLA - VPG 'file-server' state: NeedsConfiguration, protection status: Initializing, initial sync progress: 42% | 'vpgs.total.count'=3;;;0; 'vpgs.sla.meeting.count'=1;;;0;3 'vpgs.sla.notmeeting.count'=1;;;0;3 'vpgs.initializing.count'=1;;;0;3 'vpgs.withoutdata.count'=1;;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;50:;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=2820s;;;0; 'erp-database#vpg.history.actual.seconds'=82800s;;;0; 'erp-database#vpg.sync.progress.percentage'=100%;;50:;0;100 'erp-database#vpg.replication.issues.count'=1;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;50:;0;100 'file-server#vpg.replication.issues.count'=0;;;0; 'file-server#vpg.vms.protected.count'=1;;;0;
    ...    10
    ...    --filter-counters='^(?!last-)' --warning-vpgs-without-data=0
    ...    CRITICAL: VPG 'erp-database' state: Protecting, protection status: RpoNotMeetingSLA - VPG 'file-server' state: NeedsConfiguration, protection status: Initializing WARNING: VPGs without data: 1 | 'vpgs.total.count'=3;;;0; 'vpgs.sla.meeting.count'=1;;;0;3 'vpgs.sla.notmeeting.count'=1;;;0;3 'vpgs.initializing.count'=1;;;0;3 'vpgs.withoutdata.count'=1;0:0;;0; 'web-frontend#vpg.rpo.actual.seconds'=750s;;;0; 'web-frontend#vpg.history.actual.seconds'=93600s;;;0; 'web-frontend#vpg.sync.progress.percentage'=100%;;;0;100 'web-frontend#vpg.replication.issues.count'=0;;;0; 'web-frontend#vpg.vms.protected.count'=3;;;0; 'erp-database#vpg.rpo.actual.seconds'=2820s;;;0; 'erp-database#vpg.history.actual.seconds'=82800s;;;0; 'erp-database#vpg.sync.progress.percentage'=100%;;;0;100 'erp-database#vpg.replication.issues.count'=1;;;0; 'erp-database#vpg.vms.protected.count'=2;;;0; 'file-server#vpg.sync.progress.percentage'=42%;;;0;100 'file-server#vpg.replication.issues.count'=0;;;0; 'file-server#vpg.vms.protected.count'=1;;;0;

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
    ...    ^WARNING:\\ VPG\\ 'web\\-frontend'\\ last\\ successful\\ failover\\ test:\\ 1w\\ 3d\\ ago\\ \\|\\ 'vpgs\\.total\\.count'=1;;;0;\\ 'vpgs\\.sla\\.meeting\\.count'=1;;;0;1\\ 'vpgs\\.sla\\.notmeeting\\.count'=0;;;0;1\\ 'vpgs\\.initializing\\.count'=0;;;0;1\\ 'vpgs\\.withoutdata\\.count'=1;;;0;\\ 'web\\-frontend\\#vpg\\.rpo\\.actual\\.seconds'=750s;;;0;\\ 'web\\-frontend\\#vpg\\.history\\.actual\\.seconds'=93600s;;;0;\\ 'web\\-frontend\\#vpg\\.checkpoint\\.last\\.seconds'=\\d+s;;;0;\\ 'web\\-frontend\\#vpg\\.failovertest\\.last\\.seconds'=\\d+s;0:604800;;0;\\ 'web\\-frontend\\#vpg\\.sync\\.progress\\.percentage'=100%;;;0;100\\ 'web\\-frontend\\#vpg\\.replication\\.issues\\.count'=0;;;0;\\ 'web\\-frontend\\#vpg\\.vms\\.protected\\.count'=3;;;0;$
    ...    12
    ...    --include-name=web --critical-last-checkpoint=600
    ...    ^CRITICAL:\\ VPG\\ 'web\\-frontend'\\ last\\ checkpoint:\\ 12m\\ ago\\ \\|\\ 'vpgs\\.total\\.count'=1;;;0;\\ 'vpgs\\.sla\\.meeting\\.count'=1;;;0;1\\ 'vpgs\\.sla\\.notmeeting\\.count'=0;;;0;1\\ 'vpgs\\.initializing\\.count'=0;;;0;1\\ 'vpgs\\.withoutdata\\.count'=1;;;0;\\ 'web\\-frontend\\#vpg\\.rpo\\.actual\\.seconds'=750s;;;0;\\ 'web\\-frontend\\#vpg\\.history\\.actual\\.seconds'=93600s;;;0;\\ 'web\\-frontend\\#vpg\\.checkpoint\\.last\\.seconds'=\\d+s;;0:600;0;\\ 'web\\-frontend\\#vpg\\.failovertest\\.last\\.seconds'=\\d+s;;;0;\\ 'web\\-frontend\\#vpg\\.sync\\.progress\\.percentage'=100%;;;0;100\\ 'web\\-frontend\\#vpg\\.replication\\.issues\\.count'=0;;;0;\\ 'web\\-frontend\\#vpg\\.vms\\.protected\\.count'=3;;;0;$
