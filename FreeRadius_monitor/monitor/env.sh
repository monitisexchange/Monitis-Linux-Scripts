#!/bin/bash

loc=`which radtest`
if [[ ("x$loc" == "x") ]] ; then
   echo "ERROR: 'radtest' is not istalled..."
   exit 3
fi

loc=`which curl`
if [[ ("x$loc" == "x") ]] ; then
   echo "ERROR: 'cUrl' is not istalled..."
   exit 3
fi

loc=`which bc`
if [[ ("x$loc" == "x") ]] ; then
   echo "ERROR: 'BC calculator' is not installed..."
   exit 3
fi

