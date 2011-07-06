#!/bin/bash
# add result to custom monitor for Monitis
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

This script adds a custom monitor on Monitis.

OPTIONS:
   -h      Show this message
   -a      api key
   -s      secret key
   -n      monitor name
   -m      monitor tag
   -r      results parameters name:displayName:UOM:datatype[;name2:displayName2:UOM2:datatype2...]

--- WARNING ---
This script is obsolsete and was replaced by monitis_api.sh
Check out https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/API
--- WARNING ---
EOF
}


APIKEY=
NAME=
RESULTPARAMS=
TAG=
SECRETKEY=

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

(cd `dirname $0`; source monitis_api.sh && export API_KEY=$APIKEY && export SECRET_KEY=$SECRETKEY && monitis_add_custom_monitor "$NAME" "$TAG" "$RESULTPARAMS")

