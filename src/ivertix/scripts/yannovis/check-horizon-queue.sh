#!/bin/bash
#
# ## Plugin to check horizon queue metrics
# ##
# ## Changes:
# ## - 20240115 - first version
#
#
#
# Usage: ./check-horizon-queue.sh --hostname=api.yanovis.com --identifier=default
         #--path=
         #--warning-queued=
         #--critical-queued=
         #--warning-waittime=
         #--critical-waittime=
         #--warning-throughput=
         #--critical-throughput=
#
#
# ## Output:
#
# OK - All metrics ok | '<identifier>.queued'=0;0:100; '<identifier>.waittime'=0;; '<identifier>.throughput'=68;;1000 '<identifier>.runtime'=258.3316176470588;;
# OK - All metrics ok | 'events.queued'=0;0:100; 'events.waittime'=0;; 'events.throughput'=68;;1000 'events.runtime'=258.3316176470588;;
#
# Exit Codes
# 0 OK       .. is ok
# 1 Warning  .. within "warning" threshold
# 2 Critical .. within "critical" threshold
# 3 Unknown  Invalid command line arguments or ..
#

PROGNAME=$(/usr/bin/basename $0)
PROGPATH=$(echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,')
REVISION="Revision 1.0"

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

print_revision() {
  echo "$REVISION"
}

print_usage() {
  echo "Usage: $PROGNAME --hostname=<value> --identifier=<name> [--port=<value>] [--path=<value>] [--warning-*=<warn>] [--critical-*=<crit>]
  --warning-queued=
  --critical-queued=
  --warning-waittime=
  --critical-waittime=
  --warning-throughput=
  --critical-throughput="
  echo "Usage: $PROGNAME -h|--help"
  echo "Usage: $PROGNAME -V|--version"
}

print_help() {
  print_revision $PROGNAME $REVISION
  print_usage
  echo ""
}

# function to check values against thresholds
check_in_range() {
  local value="$1"
  local threshold="$2"
  local min=""
  local max=""

  read -r min max <<< "$threshold"
  #echo "val,min,max $value, $min, $max"

  if [[
    (-n "$min" && -n "$max" && "$value" -gt "$min" && "$value" -lt "$max") ||
    (-n "$min" && -z "$max" && "$value" -gt "$min") ||
    (-z "$min" && -n "$max" && "$value" -lt "$max")
  ]]; then
    return 0  # is in range
  else
    return 1  # is out of range
  fi
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 2 ]; then
  print_usage
  exit $STATE_UNKNOWN
fi

IFS=":"

port=443
path="pub/support/monitoring/horizon"
exitstatus=$STATE_OK #default

identifier=""
threshold_warn_queued=""
threshold_crit_queued=""
threshold_warn_waittime=""
threshold_crit_waittime=""
threshold_warn_throughput=""
threshold_crit_throughput=""

# read and check the parameters
while test -n "$1"; do
  case "$1" in
  --help)
    print_help
    exit $STATE_OK
    ;;
  -h)
    print_help
    exit $STATE_OK
    ;;
  --version)
    print_revision $PROGNAME $VERSION
    exit $STATE_OK
    ;;
  -V)
    print_revision $PROGNAME $VERSION
    exit $STATE_OK
    ;;
  --hostname=*)
    hostname="${1#*=}"
    ;;
  --port=*)
    port="${1#*=}"
    ;;
  --identifier=*)
    identifier="${1#*=}"
    ;;
  --path=*)
    path="${1#*=}"
    ;;
  --warning-queued=*)
    threshold_warn_queued="${1#*=}"
    ;;
  --critical-queued=*)
    threshold_crit_queued="${1#*=}"
    ;;
  --warning-waittime=*)
    threshold_warn_waittime="${1#*=}"
    ;;
  --critical-waittime=*)
    threshold_crit_waittime="${1#*=}"
    ;;
  --warning-throughput=*)
    threshold_warn_throughput="${1#*=}"
    ;;
  --critical-throughput=*)
    threshold_crit_throughput="${1#*=}"
    ;;
  *)
    echo "Unknown argument: $1"
    print_usage
    exit $STATE_UNKNOWN
    ;;
  esac
  shift
done

###### PUT YOUR CODE HERE

response=$(curl -s -w "%{http_code}" --digest "https://$hostname:$port/$path" --insecure)

http_status="${response: -3}"
json="${response:0: -3}"

if [[ $http_status -ge 300 ]]; then
    echo "UNKNOWN - https://$hostname:$port/$path - http_status $http_status"
    exit $STATE_UNKNOWN
fi

# Use jq to extract the value
queued=$(echo "$json" | jq -r ".queues[\"$identifier\"].queued_jobs")
throughput=$(echo "$json" | jq -r ".queues[\"$identifier\"].throughput")
waittime=$(echo "$json" | jq -r ".queues[\"$identifier\"].wait_time")
runtime=$(echo "$json" | jq -r ".queues[\"$identifier\"].runtime")

queued_perf_part="'${identifier}.queued'=${queued};${threshold_warn_queued};${threshold_crit_queued}"
waittime_perf_part="'${identifier}.waittime'=${waittime};${threshold_warn_waittime};${threshold_crit_waittime}"
throughput_perf_part="'${identifier}.throughput'=${throughput};${threshold_warn_throughput};${threshold_crit_throughput}"
runtime_perf_part="'${identifier}.runtime'=${runtime};;"

perf_output="${queued_perf_part} ${waittime_perf_part} ${throughput_perf_part} ${runtime_perf_part}"

##### Compare with thresholds

alarms=()
warning=0
critical=0

if [ "$queued" == "null" ]; then
  ((warning++))
  alarms+=("Queued jobs - $queued")
elif check_in_range "$queued" "$threshold_crit_queued"; then
  ((critical++))
  alarms+=("Queued jobs - $queued")
elif check_in_range "$queued" "$threshold_warn_queued"; then
  ((warning++))
  alarms+=("Queued jobs - $queued")
fi

if [ "$waittime" == "null" ]; then
  ((warning++))
  alarms+=("Queue wait time - $waittime")
elif check_in_range "$waittime" "$threshold_crit_waittime"; then
  ((critical++))
  alarms+=("Queue wait time - $waittime")
elif check_in_range "$waittime" "$threshold_warn_waittime"; then
  ((warning++))
  alarms+=("Queue wait time - $waittime")
fi

if [ "$throughput" == "null" ]; then
  ((warning++))
  alarms+=("Queue throughput - $throughput")
elif check_in_range "$throughput" "$threshold_crit_throughput"; then
  ((critical++))
  alarms+=("Queue throughput - $throughput")
elif check_in_range "$throughput" "$threshold_warn_throughput"; then
  ((warning++))
  alarms+=("Queue throughput - $throughput")
fi

if [[ critical -gt 0 ]]; then
  status="CRITICAL"
  exitstatus=$STATE_CRITICAL
elif [[ warning -gt 0 ]]; then
  status="WARNING"
  exitstatus=$STATE_WARNING
else
  status="OK"
  alarms+=("All metrics ok")
  exitstatus=$STATE_OK
fi

output=""
index=0

for element in "${alarms[@]}"; do
    if [[ $index -gt 0 ]]; then
      output="${output}, "
    fi

    output="${output}${element}"
    ((index++))
done

echo "$status - $output | $perf_output"
exit $exitstatus

### ============================================================= ###
###                         END OF SCRIPT                         ###
### ============================================================= ###
