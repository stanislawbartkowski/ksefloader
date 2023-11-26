#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

function help() {
    echo "Usunięcie faktury z bufora"
    echo "Wywołanie:"
    echo "   usunzbufora.sh <uuid> "
    logfail "Nie mozna wywołać. Powinien być dokładnie jeden parametr"
}


[ "$1" == "" ]  && help

ksef_removeinvoice $1
