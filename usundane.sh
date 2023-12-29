#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

function help() {
    echo "Wyczyszczenie katalogu z danymi"
    echo "   usundane.sh"
}

ksef_clearwork
