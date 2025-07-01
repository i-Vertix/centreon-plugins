#!/bin/bash
#
# ## Plugin to check the metrics on api.yanovis.com
# ## Written by Roman Morandell (i-Vertix)
# ##
# ## Changes:
# ## - 20240112 - simplify checks add param path
# ## - 20231220 - first version
#
#
# ## You are free to use this script under the terms of the Gnu Public License.
# ## No guarantee - use at your own risc.
#
#
# Usage: ./check-yanovis-api-metrics.sh --hostname=api.yanovis.com
         #--path=
         #--warning-jobs-per-minute=
         #--critical-jobs-per-minute=
         #--warning-recent-jobs=
         #--critical-recent-jobs=
         #--warning-recent-fails=
         #--critical-recent-fails=
         #--warning-max-jobs-on-supervisor=
         #--critical-max-jobs-on-supervisor=
         #--warning-max-wait-on-supervisor=
         #--critical-max-wait-on-supervisor=
         #--warning-max-jobs-on-queue=
         #--critical-max-jobs-on-queue=
         #--warning-max-wait-on-queue=
         #--critical-max-wait-on-queue=
#
#
# ## Output:
#
# OK - All metrics ok | 'jobs.per.minute'=138;10000;10000 'recent.jobs'=24538;10000;10000 'recent.fails'=32;10000;10000 'max.jobs.on.supervisor'=0;10000;10000 'max.wait.on.supervisor'=0;10000;10000 'max.jobs.on.queue'=0;10000;10000 'max.wait.on.queue'=0;10000;10000
#
# Exit Codes
# 0 OK       .. is ok
# 1 Warning  .. above "warning" threshold
# 2 Critical .. above "critical" threshold
# 3 Unknown  Invalid command line arguments or ..
#

PROGNAME=$(/usr/bin/basename $0)
PROGPATH=$(echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,')
REVISION="Revision 1.1"

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
  --warning-jobs-per-minute
  --critical-jobs-per-minute=
  --warning-recent-jobs=
  --critical-recent-jobs=
  --warning-recent-fails=
  --critical-recent-fails=
  --warning-max-jobs-on-supervisor=
  --critical-max-jobs-on-supervisor=
  --warning-max-wait-on-supervisor=
  --critical-max-wait-on-supervisor=
  --warning-max-jobs-on-queue=
  --critical-max-jobs-on-queue=
  --warning-max-wait-on-queue=
  --critical-max-wait-on-queue="
  echo "Usage: $PROGNAME -h|--help"
  echo "Usage: $PROGNAME -V|--version"
}

print_help() {
  print_revision $PROGNAME $REVISION
  print_usage
  echo ""
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
  print_usage
  exit $STATE_UNKNOWN
fi

port=443
path="pub/support/monitoring/horizon"
exitstatus=$STATE_OK #default

threshold_warn_jobs_per_minute=""
threshold_crit_jobs_per_minute=""
threshold_warn_recent_jobs=""
threshold_crit_recent_jobs=""
threshold_warn_recent_fails=""
threshold_crit_recent_fails=""
threshold_warn_max_jobs_on_supervisor=""
threshold_crit_max_jobs_on_supervisor=""
threshold_warn_max_wait_on_supervisor=""
threshold_crit_max_wait_on_supervisor=""
threshold_warn_max_jobs_on_queue=""
threshold_crit_max_jobs_on_queue=""
threshold_warn_max_wait_on_queue=""
threshold_crit_max_wait_on_queue=""

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
  --warning-jobs-per-minute=*)
    threshold_warn_jobs_per_minute="${1#*=}"
    ;;
  --critical-jobs-per-minute=*)
    threshold_crit_jobs_per_minute="${1#*=}"
    ;;
  --warning-recent-jobs=*)
    threshold_warn_recent_jobs="${1#*=}"
    ;;
  --critical-recent-jobs=*)
    threshold_crit_recent_jobs="${1#*=}"
    ;;
  --warning-recent-fails=*)
    threshold_warn_recent_fails="${1#*=}"
    ;;
  --critical-recent-fails=*)
    threshold_crit_recent_fails="${1#*=}"
    ;;
  --warning-max-jobs-on-supervisor=*)
    threshold_warn_max_jobs_on_supervisor="${1#*=}"
    ;;
  --critical-max-jobs-on-supervisor=*)
    threshold_crit_max_jobs_on_supervisor="${1#*=}"
    ;;
  --warning-max-wait-on-supervisor=*)
    threshold_warn_max_wait_on_supervisor="${1#*=}"
    ;;
  --critical-max-wait-on-supervisor=*)
    threshold_crit_max_wait_on_supervisor="${1#*=}"
    ;;
  --warning-max-jobs-on-queue=*)
    threshold_warn_max_jobs_on_queue="${1#*=}"
    ;;
  --critical-max-jobs-on-queue=*)
    threshold_crit_max_jobs_on_queue="${1#*=}"
    ;;
  --warning-max-wait-on-queue=*)
    threshold_warn_max_wait_on_queue="${1#*=}"
    ;;
  --critical-max-wait-on-queue=*)
    threshold_crit_max_wait_on_queue="${1#*=}"
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
jobs_per_minute=$(echo "$json" | jq -r '.metrics.jobs_per_minute')
recent_jobs=$(echo "$json" | jq -r '.metrics.recent_jobs')
recent_fails=$(echo "$json" | jq -r '.metrics.recent_fails')
max_jobs_on_supervisor=$(echo "$json" | jq -r '.metrics.max_jobs_on_supervisor')
max_wait_on_supervisor=$(echo "$json" | jq -r '.metrics.max_wait_on_supervisor')
max_jobs_on_queue=$(echo "$json" | jq -r '.metrics.max_jobs_on_queue')
max_wait_on_queue=$(echo "$json" | jq -r '.metrics.max_wait_on_queue')

jobs_per_minute_perf_part="'jobs.per.minute'=${jobs_per_minute};${threshold_warn_jobs_per_minute};${threshold_crit_jobs_per_minute}"
recent_jobs_perf_part="'recent.jobs'=${recent_jobs};${threshold_warn_recent_jobs};${threshold_crit_recent_jobs}"
recent_fails_perf_part="'recent.fails'=${recent_fails};${threshold_warn_recent_fails};${threshold_crit_recent_fails}"
max_jobs_on_supervisor_perf_part="'max.jobs.on.supervisor'=${max_jobs_on_supervisor};${threshold_warn_max_jobs_on_supervisor};${threshold_crit_max_jobs_on_supervisor}"
max_wait_on_supervisor_perf_part="'max.wait.on.supervisor'=${max_wait_on_supervisor};${threshold_warn_max_wait_on_supervisor};${threshold_crit_max_wait_on_supervisor}"
max_jobs_on_queue_perf_part="'max.jobs.on.queue'=${max_jobs_on_queue};${threshold_warn_max_jobs_on_queue};${threshold_crit_max_jobs_on_queue}"
max_wait_on_queue_perf_part="'max.wait.on.queue'=${max_wait_on_queue};${threshold_warn_max_wait_on_queue};${threshold_crit_max_wait_on_queue}"

perf_output="${jobs_per_minute_perf_part} ${recent_jobs_perf_part} ${recent_fails_perf_part} ${max_jobs_on_supervisor_perf_part} ${max_wait_on_supervisor_perf_part} ${max_jobs_on_queue_perf_part} ${max_wait_on_queue_perf_part}"

##### Compare with thresholds

alarms=()
warning=0
critical=0

if [[ -n $threshold_crit_jobs_per_minute && $jobs_per_minute -gt $threshold_crit_jobs_per_minute ]]; then
  ((critical++))
  alarms+=("Jobs per minute - $jobs_per_minute")
elif [[ -n $threshold_warn_jobs_per_minute && $jobs_per_minute -gt $threshold_warn_jobs_per_minute ]]; then
  ((warning++))
  alarms+=("Jobs per minute - $jobs_per_minute")
fi


if [[ -n $threshold_crit_recent_jobs && $recent_jobs -gt $threshold_crit_recent_jobs ]]; then
  ((critical++))
  alarms+=("Recent jobs - $recent_jobs")
elif [[ -n $threshold_warn_recent_jobs && $recent_jobs -gt $threshold_warn_recent_jobs ]]; then
  ((warning++))
  alarms+=("Recent jobs - $recent_jobs")
fi


if [[ -n $threshold_crit_recent_fails && $recent_fails -gt $threshold_crit_recent_fails ]]; then
  ((critical++))
  alarms+=("Recent fails - $recent_fails")
elif [[ -n $threshold_warn_recent_fails && $recent_fails -gt $threshold_warn_recent_fails ]]; then
  ((warning++))
  alarms+=("Recent fails - $recent_fails")
fi

if [[ -n $threshold_crit_max_jobs_on_supervisor && $max_jobs_on_supervisor -gt $threshold_crit_max_jobs_on_supervisor ]]; then
  ((critical++))
  alarms+=("Jobs on supervisor - $max_jobs_on_supervisor")
elif [[ -n $threshold_warn_max_jobs_on_supervisor && $max_jobs_on_supervisor -gt $threshold_warn_max_jobs_on_supervisor ]]; then
  ((warning++))
  alarms+=("Jobs on supervisor - $max_jobs_on_supervisor")
fi

if [[ -n $threshold_crit_max_wait_on_supervisor && $max_wait_on_supervisor -gt $threshold_crit_max_wait_on_supervisor ]]; then
  ((critical++))
  alarms+=("Wait on supervisor - $max_wait_on_supervisor")
elif [[ -n $threshold_warn_max_wait_on_supervisor && $max_wait_on_supervisor -gt $threshold_warn_max_wait_on_supervisor ]]; then
  ((warning++))
  alarms+=("Wait on supervisor - $max_wait_on_supervisor")
fi

if [[ -n $threshold_crit_max_jobs_on_queue && $max_jobs_on_queue -gt $threshold_crit_max_jobs_on_queue ]]; then
  ((critical++))
  alarms+=("Max jobs on queue - $max_jobs_on_queue")
elif [[ -n $threshold_warn_max_jobs_on_queue && $max_jobs_on_queue -gt $threshold_warn_max_jobs_on_queue ]]; then
  ((warning++))
  alarms+=("Max jobs on queue - $max_jobs_on_queue")
fi

if [[ -n $threshold_crit_max_wait_on_queue && $max_wait_on_queue -gt $threshold_crit_max_wait_on_queue ]]; then
  ((critical++))
  alarms+=("Max wait on queue - $max_wait_on_queue")
elif [[ -n $threshold_warn_max_wait_on_queue && $max_wait_on_queue -gt $threshold_warn_max_wait_on_queue ]]; then
  ((warning++))
  alarms+=("Max wait on queue - $max_wait_on_queue")
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
