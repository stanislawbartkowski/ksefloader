#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

help() {
    echo "Wstawienie faktury do bufora w celu wysłania do KSeF"
    echo "Wywołanie:"
    echo "   acceptinvoice.sh <ścieżka do faktury XML> <plik z wynikiem>"
    echo " Exit:"
    echo " 0 - akceptacja do wyboru"
    echo " 1 - failure"
    echo " 2 - niezgodność z xsd"
    logfail "Nie mozna wywołać. Powinny być dwa parametry"
}

[ "$1" == "" ] && [ "$2" == "" ] && help

ksef_acceptinvoice $1 $2

