#!/bin/sh
#
# ## Plugin xy for xy
# ## Written by <<NAME>> (<<URL>>)
# ##
# ## Changes:
# ## - <<YYYYMMDD>> ...
#
#
# ## You are free to use this script under the terms of the Gnu Public License.
# ## No guarantee - use at your own risc.
#
#
# Usage: ./plugin.sh --user=user1 --password=12345678 --warning <warn> --critical <crit>
#
# ## Description:
#
# This plugin ....
#
# ## Output:
#
# The plugin prints ..
#
# Exit Codes
# 0 OK       .. is ok
# 1 Warning  .. above "warning" threshold
# 2 Critical .. above "critical" threshold
# 3 Unknown  Invalid command line arguments or ..
#
# Example:
#
# .. - ok         (exit code 0)
# .. KB - warning   (exit code 1)
# .. KB - critical  (exit code 2)

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
  echo "Usage: $PROGNAME --user <value> --password <value> --port <value> [--warning <warn>] [--critical <crit>]"
  echo "Usage: $PROGNAME -h|--help"
  echo "Usage: $PROGNAME -V|--version"
  echo ""
  echo "<warn> and <crit> must be expressed in <<FORMAT>>"
}

print_help() {
  print_revision $PROGNAME $REVISION
  echo ""
  echo "<<DESCRIPTION>>"
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
  --user=*)
    user="${1#*=}"
    ;;
  --password=*)
    pwd="${1#*=}"
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

#string_value=$(curl -s --digest -u "$user:$pwd" "http://hostname:$port/path" --insecure)
#int_value=$(echo $string_value | sed 's/"//g')

#perf_output="$int_value | 'Count|Sum|AVG|size|xx'=${int_value}<<Unit>>;${threshold_warn};${threshold_crit}"

##### Compare with thresholds

if [ $int_value -gt $threshold_warn ]; then
  echo "OK - $perf_output"
  exitstatus=$STATE_OK
elif [ $int_value -le $threshold_warn ] && [ $int_value -gt $threshold_crit ]; then
  echo "WARNING - $perf_output"
  exitstatus=$STATE_WARNING
elif [ $int_value -le $threshold_crit ]; then
  echo "CRITICAL - $perf_output"
  exitstatus=$STATE_CRITICAL
else
  echo "UNKNOWN - Value $int_value not in range"
  exit 3
fi

exit $exitstatus

### ========================================================================================= ###
###                         END OF SCRIPT                                                     ###
### ========================================================================================= ###
