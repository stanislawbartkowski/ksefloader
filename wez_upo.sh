#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

function help() {
    echo "Wez UPO do sesji"
    echo "Wywołanie:"
    echo "   read_invoice.sh <REFERENCE> <PLIK_RES>"
    logfail "Nie można wywołać."
}

[ "$1" == "" ] || [ "$2" == "" ] && help

ksef_getupo "$1" $2