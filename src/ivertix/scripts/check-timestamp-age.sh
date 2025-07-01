#!/bin/sh
#
# ## Plugin check-easymailing-timestamp for timestamp age check of easymail service
# ## Written by Roman Morandell (<<URL>>)
# ##
# ## Changes:
# ## - <<YYYYMMDD>> ...
#
#
# ## You are free to use this script under the terms of the Gnu Public License.
# ## No guarantee - use at your own risc.
#
#
# Usage: ./check-easymailing-timestamp.sh --warning <warning> --critical <critical>
#
# ## Description:
#
# This plugin check the age of a timestamp of a service
#
# ## Output:
#
# The plugin prints ..
#
# Exit Codes
# 0 OK       timestamp is ok
# 1 Warning  timestamp is above "warning" threshold
# 2 Critical timestamp is above "critical" threshold
# 3 Unknown  Invalid command line arguments or timestamp value not available
#

PROGNAME=$(/usr/bin/basename $0)
PROGPATH=$(echo $0 | /bin/sed -e 's,[\\/][^\\/][^\\/]*$,,')
REVISION="Revision 1.1"
AUTHOR="(c) <<YEAR>> <<NAME>> (<<URL>>)"

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

print_revision() {
  echo "$REVISION $AUTHOR"
}

print_usage() {
  echo "Usage: $PROGNAME --hostname <value> --port <value> --url-part <value> [--warning <warning>] [--critical <critical>]"
  echo "Usage: $PROGNAME -h|--help"
  echo "Usage: $PROGNAME -V|--version"
  echo ""
  echo "<warning> and <critical> must be expressed in minutes"
}

print_help() {
  print_revision $PROGNAME $REVISION
  echo ""
  echo "This plugin check the age of a timestamp of a service"
  echo ""
  print_usage
  echo ""
}

# Make sure the correct number of command line
# arguments have been supplied

if [ $# -lt 1 ]; then
  print_usage
  exit $STATE_UNKNOWN
fi

# Grab the command line arguments

port=443
threshold_warn=""
threshold_crit=""
exitstatus=$STATE_OK #default

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
  --urlpath=*)
      urlpath="${1#*=}"
      ;;
  --port=*)
    port="${1#*=}"
    ;;
  --warning=*)
    threshold_warn="${1#*=}"
    ;;
  --critical=*)
    threshold_crit="${1#*=}"
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

string_value=$(curl -s --digest "https://$hostname:$port/$urlpath" --insecure)
service_ts=$(echo $string_value | sed 's/"//g')

current_ts=$(date +%s)
diff=$(((current_ts - service_ts) / 60))

perf_output="Age of timestamp $diff minutes | 'age'=${diff}m;${threshold_warn};${threshold_crit}"

##### Compare with thresholds

if [ $diff -le $threshold_warn ]; then
  echo "OK - $perf_output"
  exitstatus=$STATE_OK
elif [ $diff -gt $threshold_warn ] && [ $diff -le $threshold_crit ]; then
  echo "WARNING - $perf_output"
  exitstatus=$STATE_WARNING
elif [ $diff -gt $threshold_crit ]; then
  echo "CRITICAL - $perf_output"
  exitstatus=$STATE_CRITICAL
else
  echo "UNKNOWN - Value $diff not in range"
  exit 3
fi

exit $exitstatus

### ========================================================================================= ###
###                         END OF SCRIPT                                                     ###
### ========================================================================================= ###
