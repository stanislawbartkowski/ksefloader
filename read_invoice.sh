#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

INIT_SESSION=0
SESSIONSTATUS=`crtemp`
OP="Odczytanie faktur z KSeF"
BEG=`getdate`
NO=0

function trap_exit() {
    if [ "$INIT_SESSION" -eq 1 ]; then
        log "Pojawił się błąd podczas odczytywania"
        requestsessionterminate $SESSIONSTATUS
        ENDD=`getdate`
        journallog "$OP" "$BEG" "$ENDD" $ERROR "Pojawił się błąd podczas odczytywania"
        removetemp
        return 1
    fi      
    removetemp
}

trap "trap_exit" EXIT

function help() {
    echo "Odczytanie faktur z KSeF"
    echo "Wywołanie:"
    echo "   read_invoice.sh <NIP> <DATA_OD> <DATA_DO> <PLIK_RES>"
    logfail "Nie można wywołać."
}

[ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" || "$4" == "" ] && help

ksef_readinvoices $1 $2 $3 $4



