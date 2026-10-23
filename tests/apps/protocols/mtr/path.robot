*** Settings ***
Documentation     Check the network path with mtr

Resource          ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS} --plugin=apps::protocols::mtr::plugin --mode=path


*** Test Cases ***
Path ${tc}
    [Documentation]    Test cases run in order: the path change cases rely on the cache of the previous ones
    [Tags]    apps    protocols    mtr

    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    --command-path=${CURDIR}${/}bin
    ...    --command=${mtr}
    ...    --statefile-dir=/dev/shm/
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    mtr
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    192.0.2.100
    ...    mtr
    ...    ${EMPTY}
    ...    OK: path has 6 hop(s) (last: 6), changed hops: none, hops: 6 - Destination '192.0.2.100' status: reached, packet loss: 0.00 %, rtt last: 0.85 ms, rtt average: 1.50 ms, rtt best: 0.82 ms, rtt worst: 6.84 ms, rtt stdev: 1.88 ms - All hops are ok | 'path.hops.count'=6;;;0; 'destination.packets.loss.percentage'=0.00%;;;0;100 'destination.rtt.last.milliseconds'=0.85ms;;;0; 'destination.rtt.average.milliseconds'=1.50ms;;;0; 'destination.rtt.best.milliseconds'=0.82ms;;;0; 'destination.rtt.worst.milliseconds'=6.84ms;;;0; 'destination.rtt.stdev.milliseconds'=1.88ms;;;0; '1#hop.packets.loss.percentage'=0.00%;;;0;100 '1#hop.rtt.last.milliseconds'=1.41ms;;;0; '1#hop.rtt.average.milliseconds'=1.80ms;;;0; '1#hop.rtt.best.milliseconds'=0.78ms;;;0; '1#hop.rtt.worst.milliseconds'=5.06ms;;;0; '1#hop.rtt.stdev.milliseconds'=1.21ms;;;0; '2#hop.packets.loss.percentage'=0.00%;;;0;100 '2#hop.rtt.last.milliseconds'=1.24ms;;;0; '2#hop.rtt.average.milliseconds'=1.29ms;;;0; '2#hop.rtt.best.milliseconds'=1.20ms;;;0; '2#hop.rtt.worst.milliseconds'=1.42ms;;;0; '2#hop.rtt.stdev.milliseconds'=0.07ms;;;0; '3#hop.packets.loss.percentage'=0.00%;;;0;100 '3#hop.rtt.last.milliseconds'=0.80ms;;;0; '3#hop.rtt.average.milliseconds'=0.80ms;;;0; '3#hop.rtt.best.milliseconds'=0.71ms;;;0; '3#hop.rtt.worst.milliseconds'=0.90ms;;;0; '3#hop.rtt.stdev.milliseconds'=0.06ms;;;0; '4#hop.packets.loss.percentage'=0.00%;;;0;100 '4#hop.rtt.last.milliseconds'=1.81ms;;;0; '4#hop.rtt.average.milliseconds'=3.40ms;;;0; '4#hop.rtt.best.milliseconds'=1.81ms;;;0; '4#hop.rtt.worst.milliseconds'=12.04ms;;;0; '4#hop.rtt.stdev.milliseconds'=3.33ms;;;0; '5#hop.packets.loss.percentage'=0.00%;;;0;100 '5#hop.rtt.last.milliseconds'=1.57ms;;;0; '5#hop.rtt.average.milliseconds'=2.15ms;;;0; '5#hop.rtt.best.milliseconds'=1.52ms;;;0; '5#hop.rtt.worst.milliseconds'=6.06ms;;;0; '5#hop.rtt.stdev.milliseconds'=1.38ms;;;0; '6#hop.packets.loss.percentage'=0.00%;;;0;100 '6#hop.rtt.last.milliseconds'=0.85ms;;;0; '6#hop.rtt.average.milliseconds'=1.50ms;;;0; '6#hop.rtt.best.milliseconds'=0.82ms;;;0; '6#hop.rtt.worst.milliseconds'=6.84ms;;;0; '6#hop.rtt.stdev.milliseconds'=1.88ms;;;0;
    ...    2
    ...    192.0.2.100
    ...    mtr
    ...    --warning-destination-rtt-average=1 --filter-perfdata='^path'
    ...    WARNING: Destination '192.0.2.100' rtt average: 1.50 ms | 'path.hops.count'=6;;;0;
    ...    3
    ...    loss.example
    ...    mtr
    ...    --critical-destination-packet-loss=20
    ...    CRITICAL: Destination 'loss.example' packet loss: 30.00 % | 'path.hops.count'=4;;;0; 'destination.packets.loss.percentage'=30.00%;;0:20;0;100 'destination.rtt.last.milliseconds'=120.40ms;;;0; 'destination.rtt.average.milliseconds'=95.25ms;;;0; 'destination.rtt.best.milliseconds'=80.12ms;;;0; 'destination.rtt.worst.milliseconds'=150.33ms;;;0; 'destination.rtt.stdev.milliseconds'=21.50ms;;;0; '1#hop.packets.loss.percentage'=0.00%;;;0;100 '1#hop.rtt.last.milliseconds'=0.50ms;;;0; '1#hop.rtt.average.milliseconds'=0.55ms;;;0; '1#hop.rtt.best.milliseconds'=0.40ms;;;0; '1#hop.rtt.worst.milliseconds'=0.80ms;;;0; '1#hop.rtt.stdev.milliseconds'=0.10ms;;;0; '3#hop.packets.loss.percentage'=10.00%;;;0;100 '3#hop.rtt.last.milliseconds'=25.10ms;;;0; '3#hop.rtt.average.milliseconds'=30.42ms;;;0; '3#hop.rtt.best.milliseconds'=20.03ms;;;0; '3#hop.rtt.worst.milliseconds'=55.80ms;;;0; '3#hop.rtt.stdev.milliseconds'=9.71ms;;;0; '4#hop.packets.loss.percentage'=30.00%;;;0;100 '4#hop.rtt.last.milliseconds'=120.40ms;;;0; '4#hop.rtt.average.milliseconds'=95.25ms;;;0; '4#hop.rtt.best.milliseconds'=80.12ms;;;0; '4#hop.rtt.worst.milliseconds'=150.33ms;;;0; '4#hop.rtt.stdev.milliseconds'=21.50ms;;;0;
    ...    4
    ...    loss.example
    ...    mtr
    ...    --exclude-hop='^198[.]' --warning-hop-packet-loss=5 --filter-perfdata='^path'
    ...    WARNING: Hop '4' [203.0.113.50] packet loss: 30.00 % | 'path.hops.count'=4;;;0;
    ...    5
    ...    unreachable.example
    ...    mtr
    ...    --filter-perfdata='^path'
    ...    CRITICAL: Destination 'unreachable.example' status: unreachable | 'path.hops.count'=4;;;0;
    ...    6
    ...    garbage.example
    ...    mtr
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot decode response (add --debug option to display returned content)
    ...    7
    ...    nothere.example
    ...    mtr
    ...    ${EMPTY}
    ...    UNKNOWN: Command error: mtr: Failed to resolve host: nothere.example: Name or service not known
    ...    8
    ...    192.0.2.100
    ...    mtr
    ...    --port=443
    ...    UNKNOWN: Option --port can only be used with --protocol set to udp or tcp.
    ...    9
    ...    path.example
    ...    mtr
    ...    --filter-perfdata='^path'
    ...    OK: path has 6 hop(s) (last: 6), changed hops: none, hops: 6 - Destination 'path.example' status: reached, packet loss: 0.00 %, rtt last: 0.85 ms, rtt average: 1.50 ms, rtt best: 0.82 ms, rtt worst: 6.84 ms, rtt stdev: 1.88 ms - All hops are ok | 'path.hops.count'=6;;;0;
    ...    10
    ...    path.example
    ...    mtr-changed
    ...    --filter-perfdata='^path'
    ...    WARNING: path has 7 hop(s) (last: 6), changed hops: +198.51.100.33, +203.0.113.10, -198.51.100.3 | 'path.hops.count'=7;;;0;
    ...    11
    ...    path.example
    ...    mtr-changed
    ...    --filter-perfdata='^path'
    ...    OK: path has 7 hop(s) (last: 7), changed hops: none, hops: 7 - Destination 'path.example' status: reached, packet loss: 0.00 %, rtt last: 0.85 ms, rtt average: 1.50 ms, rtt best: 0.82 ms, rtt worst: 6.84 ms, rtt stdev: 1.88 ms - All hops are ok | 'path.hops.count'=7;;;0;
    ...    12
    ...    path.example
    ...    mtr
    ...    --warning-path-status='\\\%{hop_count_changed} == 1' --critical-path-status='\\\%{removed_hops} =~ /203[.]0[.]113[.]10/' --filter-perfdata='^path'
    ...    CRITICAL: path has 6 hop(s) (last: 7), changed hops: +198.51.100.3, -198.51.100.33, -203.0.113.10 | 'path.hops.count'=6;;;0;
