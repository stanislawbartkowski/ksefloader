#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

function help() {
    echo "Wyczyszczenie bufora dla użytkownika NIP"
    echo "Wywołanie:"
    echo "   usundane.sh <nip> "
    logfail "Nie mozna wywołać. Powinien być dokładnie jeden parametr"
}


[ "$1" == "" ]  && help

ksief_clearwork $1
