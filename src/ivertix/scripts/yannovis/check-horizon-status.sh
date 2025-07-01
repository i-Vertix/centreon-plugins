#!/bin/bash
#
# ## Plugin to check the metrics on api.yanovis.com
# ##
# ## Changes:
# ## - 20240112 - first version
#
#
#
# Usage: ./check-horizon-status.sh --hostname=api.yanovis.com
         #--path=
         #--warning-running=
         #--critical-running=
         #--warning-supervisors=
         #--critical-supervisors=
#
#
# ## Output:
#
# OK - All metrics ok | 'service.running'=3;5:10;5:10 'service.supervisors'=9;; 'service.paused'=0;;
#
# Exit Codes
# 0 OK       .. is ok
# 1 Warning  .. above "warning" threshold
# 2 Critical .. above "critical" threshold
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
  echo "Usage: $PROGNAME --hostname=<value> [--port=<value>] [--path=<value>] [--warning-*=<warn>] [--critical-*=<crit>]
  --warning-running=
  --critical-running=
  --warning-supervisors=
  --critical-supervisors="
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

if [ $# -lt 1 ]; then
  print_usage
  exit $STATE_UNKNOWN
fi

IFS=":"

port=443
path="pub/support/monitoring/horizon"
exitstatus=$STATE_OK #default

threshold_warn_running=""
threshold_crit_running=""
threshold_warn_supervisors=""
threshold_crit_supervisors=""

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
  --path=*)
    path="${1#*=}"
    ;;
  --warning-running=*)
    threshold_warn_running="${1#*=}"
    ;;
  --critical-running=*)
    threshold_crit_running="${1#*=}"
    ;;
  --warning-supervisors=*)
    threshold_warn_supervisors="${1#*=}"
    ;;
  --critical-supervisors=*)
    threshold_crit_supervisors="${1#*=}"
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
running=$(echo "$json" | jq -r '.service.running')
paused=$(echo "$json" | jq -r '.service.paused')
supervisors=$(echo "$json" | jq -r '.service.supervisors')

running_perf_part="'service.running'=${running};${threshold_warn_running};${threshold_crit_running}"
supervisors_perf_part="'service.supervisors'=${supervisors};${threshold_warn_supervisors};${threshold_crit_supervisors}"
paused_perf_part="'service.paused'=${paused};;"

perf_output="${running_perf_part} ${supervisors_perf_part} ${paused_perf_part}"

##### Compare with thresholds

alarms=()
warning=0
critical=0

if check_in_range "$running" "$threshold_crit_running"; then
  ((critical++))
  alarms+=("Instances running - $running")
elif check_in_range "$running" "$threshold_warn_running"; then
  ((warning++))
  alarms+=("Instances running - $running")
fi

if check_in_range "$supervisors" "$threshold_crit_supervisors"; then
  ((critical++))
  alarms+=("Supervisors running - supervisors")
elif check_in_range "$supervisors" "$threshold_warn_supervisors"; then
  ((warning++))
  alarms+=("Supervisors running - supervisors")
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

### ========================================================================================= ###
###                         END OF SCRIPT                                                     ###
### ========================================================================================= ###
