#!/bin/bash
#
# ## Plugin to execute a php script
# ##
# ## Changes:
# ## - 20240122 - first version
#
#
#
# Usage: ./run_php.sh --filename=check_mss
         #--path=
         #--param1=
         #--param2=
         #--param3=        
         #--param4=
         #--warning-1=
         #--critical-1=
         #--warning-2=
         #--critical-2=
         #--warning-3=
         #--critical-3=
         #--warning-4=
         #--critical-4=
#
#
# ## Output:
#
# OK - All metrics ok | 'val1'=0;0:100; 'val2'=0;; 'val3'=68;;1000 'val4'=516;;1000
# OK - All metrics ok | 'val1'=0;0:100; 'val2'=0;; 'val3'=68;;1000 'val4'=516;;1000
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
  echo "Usage: $PROGNAME --filename=<value> [--path=<value>] [--param[1-4]=<value>] [--warning-[1-4]=<warn>] [--critical-[1-4]=<crit>]
  --path
  --param1=
  --param2=
  --param3=
  --param4=
  --warning-1=
  --critical-1=
  --warning-2=
  --critical-2=
  --warning-3=
  --critical-3=
  --warning-4=
  --critical-4="
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

IFS=":"

path="php/"
exitstatus=$STATE_OK #default

param1=""
param2=""
param3=""
param4=""
threshold_warn_val1=""
threshold_crit_val1=""
threshold_warn_val2=""
threshold_crit_val2=""
threshold_warn_val3=""
threshold_crit_val3=""
threshold_warn_val4=""
threshold_crit_val4=""

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
  --filename=*)
    filename="${1#*=}"
    ;;
  --path=*)
    path="${1#*=}"
    ;;
  --param1=*)
    param1="${1#*=}"
    ;;
  --param2=*)
    param2="${1#*=}"
    ;;
  --param3=*)
    param3="${1#*=}"
    ;;
  --param4=*)
    param4="${1#*=}"
    ;;
  --warning-1=*)
    threshold_warn_val1="${1#*=}"
    ;;
  --critical-1=*)
    threshold_crit_val1="${1#*=}"
    ;;
  --warning-2=*)
    threshold_warn_val2="${1#*=}"
    ;;
  --critical-2=*)
    threshold_crit_val2="${1#*=}"
    ;;
  --warning-3=*)
    threshold_warn_val3="${1#*=}"
    ;;
  --critical-3=*)
    threshold_crit_val3="${1#*=}"
    ;;
  --warning-4=*)
    threshold_warn_val4="${1#*=}"
    ;;
  --critical-4=*)
    threshold_crit_val4="${1#*=}"
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

full_path="$path$filename.php"

# check existance of file
if [ ! -e "$full_path" ]; then
    echo "UNKNOWN- Unknown file: $full_path"
    exit $STATE_UNKNOWN
fi

output=$(php "$full_path" --p1="$param1" --p2="$param2" --p3="$param3" --p4="$param4" --th1w="$threshold_warn_val1" --th1c="$threshold_crit_val1" --th2w="$threshold_warn_val2" --th2c="$threshold_crit_val2" --th3w="$threshold_warn_val3" --th3c="$threshold_crit_val3" --th4w="$threshold_warn_val4" --th4c="$threshold_crit_val4")
exitstatus=$?


case $exitstatus in
    $STATE_OK)
        status="OK"
        ;;
    $STATE_WARNING)
        status="WARNING"
        ;;
    $STATE_CRITICAL)
        status="CRITICAL"
        ;;
    $STATE_UNKNOWN)
        status="UNKNOWN"
        ;;
    *)
        status="UNKNOWN"  # Default to UNKNOWN if the exit status is not recognized
        ;;
esac

echo "$status - $output"
exit $exitstatus
### ============================================================= ###
###                         END OF SCRIPT                         ###
### ============================================================= ###
