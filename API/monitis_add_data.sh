#!/bin/bash
# add custom monitor for Monitis
# written by Michael Chletsos 2011-05-25
# update 2011-06-18

usage()
{
cat << EOF
usage: $0 options

This script checks for timeouts over Xms in logs.

OPTIONS:
   -h      Show this message
   -a      api key
   -s      secret key
   -m      monitor tag
   -i      monitor id
   -t      timestamp (defaults to utc now)
   -r      results name:value[;name2:value2...]
EOF
}



APIKEY=
VERSION="2"
SECRETKEY=
URL="http://monitis.com/customMonitorApi"
OUTPUT="xml"
MONITOR=
ID=
CHECKTIME=`date -u +"%s"000`
TIMESTAMP=`date -u +"%F %T"`
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
   i)
     ID=$OPTARG
   ;;
   t)
     CHECKTIME=$OPTARG
   ;;
   r)
     RESULTS=$OPTARG
   ;;
  esac
done

if [[ -z $APIKEY ]] || [[ -z $SECRETKEY ]] || [[ -z $MONITOR$ID ]] || [[ -z $RESULTS ]] || [[ -z $CHECKTIME ]]
then
     usage
     exit 1
fi



if [[ -z $ID ]]
then
# Get id of monitor if not provided

  XMLID=$(curl -s "$URL?apikey=$APIKEY&output=$OUTPUT&version=$VERSION&action=getMonitors&tag=$MONITOR" | xpath -q -e /monitors/monitor/id)

  ID=${XMLID//[^0-9]/}
fi

# Add monitor result
ACTION="addResult"
CHECKSUM_STR="action"$ACTION"apikey"$APIKEY"checktime"$CHECKTIME"monitorId"$ID"results"$RESULTS"timestamp"$TIMESTAMP"version"$VERSION
CHECKSUM=$(echo -en $CHECKSUM_STR | openssl dgst -sha1 -hmac $SECRETKEY -binary | openssl enc -base64 )
POSTDATA="--data-urlencode \"action="$ACTION"\" --data-urlencode \"apikey="$APIKEY"\" --data-urlencode \"checktime="$CHECKTIME"\" --data-urlencode \"monitorId="$ID"\" --data-urlencode \"results="$RESULTS"\" --data-urlencode \"timestamp=$TIMESTAMP\" --data-urlencode \"version="$VERSION"\" --data-urlencode \"checksum="$CHECKSUM"\""

eval "curl -s ${POSTDATA} $URL"


