#!/bin/bash
# adds data to a custom monitor in Monitis
# written by Michael Chletsos 2011-05-25
# OBSOLETE by Dan Fruehauf <malkodan@gmail.com> 2011-07-06
# update 2011-07-06

usage()
{
cat << EOF
--- WARNING ---
This script is obsolsete and was replaced by monitis_api.sh
Check out https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/API
--- WARNING ---

usage: $0 options

This script adds data to a custom monitor in Monitis.

OPTIONS:
   -h      Show this message
   -a      api key
   -s      secret key
   -m      monitor tag
   -i      monitor id
   -t      timestamp (defaults to utc now)
   -r      results name:value[;name2:value2...]

--- WARNING ---
This script is obsolsete and was replaced by monitis_api.sh
Check out https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/API
--- WARNING ---
EOF
}



APIKEY=
SECRETKEY=
MONITOR=
CHECKTIME=`date -u +"%s"000`
RESULTS=

while getopts "ha:m:i:t:r:s:" OPTION
do
  case $OPTION in
   h)
     usage
     exit 1
   ;;
   a)
     APIKEY=$OPTARG
   ;;
   s)
     SECRETKEY=$OPTARG
   ;;
   m)
     MONITOR=$OPTARG
   ;;
   t)
     CHECKTIME=$OPTARG
   ;;
   r)
     RESULTS=$OPTARG
   ;;
  esac
done

if [[ -z $APIKEY ]] || [[ -z $SECRETKEY ]] || [[ -z $MONITOR ]] || [[ -z $RESULTS ]] || [[ -z $CHECKTIME ]]
then
     usage
     exit 1
fi

(cd `dirname $0`; source monitis_api.sh && export API_KEY=$APIKEY && export SECRET_KEY=$SECRETKEY && monitis_update_custom_monitor_data "$MONITOR" "$RESULTS")
