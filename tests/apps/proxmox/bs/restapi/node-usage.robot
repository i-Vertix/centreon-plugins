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
...                 --mode=node-usage
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token-id=monitor@pbs!centreon
...                 --api-token-secret=token-123


*** Test Cases ***
Node Usage ${tc}
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
    ...    OK: CPU usage: 5.37 %, CPU I/O wait: 0.21 %, load average: 0.26, 0.24, 0.24, uptime: 9M 1w 4d 1h 38m 20s - Memory total: 3.82 GB used: 644.88 MB (16.47%) free: 3.20 GB (83.53%) - Swap total: 1024.00 MB used: 31.16 MB (3.04%) free: 992.83 MB (96.96%) - Root filesystem total: 10.23 GB used: 6.73 GB (65.84%) free: 2.95 GB (28.87%) | 'node.cpu.utilization.percentage'=5.37%;;;0;100 'node.cpu.iowait.percentage'=0.21%;;;0;100 'node.load.1m.average.count'=0.26;;;0; 'node.load.5m.average.count'=0.24;;;0; 'node.load.15m.average.count'=0.24;;;0; 'node.uptime.seconds'=24623987s;;;0; 'node.memory.usage.bytes'=676208640B;;;0;4106833920 'node.memory.free.bytes'=3430625280B;;;0;4106833920 'node.memory.usage.percentage'=16.47%;;;0;100 'node.swap.usage.bytes'=32677888B;;;0;1073737728 'node.swap.free.bytes'=1041059840B;;;0;1073737728 'node.swap.usage.percentage'=3.04%;;;0;100 'node.rootfs.usage.bytes'=7229652992B;;;0;10979876864 'node.rootfs.free.bytes'=3170152448B;;;0;10979876864 'node.rootfs.usage.percentage'=65.84%;;;0;100
    ...    2
    ...    --filter-counters='^cpu|load|uptime' --warning-cpu-usage=1 --critical-load1=0.2
    ...    CRITICAL: CPU usage: 5.37 %, load average: 0.26 | 'node.cpu.utilization.percentage'=5.37%;0:1;;0;100 'node.cpu.iowait.percentage'=0.21%;;;0;100 'node.load.1m.average.count'=0.26;;0:0.2;0; 'node.load.5m.average.count'=0.24;;;0; 'node.load.15m.average.count'=0.24;;;0; 'node.uptime.seconds'=24623987s;;;0;
    ...    3
    ...    --filter-counters='^memory' --warning-memory-usage-prct=10 --critical-memory-usage=:500000000
    ...    CRITICAL: Memory total: 3.82 GB used: 644.88 MB (16.47%) free: 3.20 GB (83.53%), total: 3.82 GB used: 644.88 MB (16.47%) free: 3.20 GB (83.53%) | 'node.memory.usage.bytes'=676208640B;;0:500000000;0;4106833920 'node.memory.free.bytes'=3430625280B;;;0;4106833920 'node.memory.usage.percentage'=16.47%;0:10;;0;100
    ...    4
    ...    --filter-counters='^swap|^root' --critical-root-usage-prct=60 --warning-swap-usage-free=2000000000:
    ...    CRITICAL: Root filesystem total: 10.23 GB used: 6.73 GB (65.84%) free: 2.95 GB (28.87%) WARNING: Swap total: 1024.00 MB used: 31.16 MB (3.04%) free: 992.83 MB (96.96%) | 'node.swap.usage.bytes'=32677888B;;;0;1073737728 'node.swap.free.bytes'=1041059840B;2000000000:;;0;1073737728 'node.swap.usage.percentage'=3.04%;;;0;100 'node.rootfs.usage.bytes'=7229652992B;;;0;10979876864 'node.rootfs.free.bytes'=3170152448B;;;0;10979876864 'node.rootfs.usage.percentage'=65.84%;;0:60;0;100
    ...    5
    ...    --filter-counters=uptime --warning-uptime=:86400
    ...    WARNING: uptime: 9M 1w 4d 1h 38m 20s | 'node.uptime.seconds'=24623987s;0:86400;;0;
