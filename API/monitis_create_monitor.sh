#!/bin/bash
# add result to custom monitor for Monitis
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
   -n      monitor name
   -m      monitor tag
   -r      results parameters name:displayName:UOM:datatype[;name2:displayName2:UOM2:datatype2...]
EOF
}


ACTION='addMonitor'
APIKEY=
NAME=
RESULTPARAMS=
TAG=
TIMESTAMP=`date -u +'%F %T'`
VERSION='2'
SECRETKEY=
URL='http://monitis.com/customMonitorApi'

while getopts "ha:n:m:i:r:s:" OPTION
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
   n)
     NAME=$OPTARG
   ;;
   m)
     TAG=$OPTARG
   ;;
   r)
     RESULTPARAMS=$OPTARG
   ;;
  esac
done

if [[ -z $APIKEY ]] || [[ -z $SECRETKEY ]] || [[ -z $NAME ]] || [[ -z $TAG ]] || [[ -z $RESULTPARAMS ]] 
then
     usage
     exit 1
fi



CHECKSUM_STR='action'$ACTION'apikey'$APIKEY'name'$NAME'resultParams'$RESULTPARAMS'tag'$TAG'timestamp'$TIMESTAMP'version'$VERSION


CHECKSUM=`echo -en "$CHECKSUM_STR" | openssl dgst -sha1 -hmac $SECRETKEY -binary | openssl enc -base64 `


POSTDATA="--data-urlencode \"action="$ACTION"\" --data-urlencode \"apikey="$APIKEY"\" --data-urlencode \"name="$NAME"\" --data-urlencode \"resultParams="$RESULTPARAMS"\" --data-urlencode \"tag="$TAG"\" --data-urlencode \"timestamp=$TIMESTAMP\" --data-urlencode \"version="$VERSION"\" --data-urlencode \"checksum="$CHECKSUM"\""

eval "curl ${POSTDATA} $URL "
