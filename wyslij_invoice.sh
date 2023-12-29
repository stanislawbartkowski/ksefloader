#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

INIT_SESSION=0
SESSIONSTATUS=`crtemp`
OP="Wysyłanie faktury do KSeF"
BEG=`getdate`

function trap_exit() {
    if [ "$INIT_SESSION" -eq 1 ]; then
        requestsessionterminate $SESSIONSTATUS
        local -r END=`getdate`
        local -r MESS="Wystąpił błąd wysyłania faktury"
        journallog "$OP" "$BEG" "$END" $ERROR "$MESS"
        removetemp
        log "$MESS"
        return 1
    fi      
    removetemp
}

function help() {
    echo "Wysłanie faktury do KSeF"
    echo "Wywołanie:"
    echo "   wyslij_invoice.sh <nip> <ścieżka do faktury XML> <plik z wynikiem>"
    echo " Exit:"
    echo " 0 - faktura została wysłana do KSeF i został pobrany status"
    echo " 1 - failure"
    echo " 2 - niezgodność z xsd"
    logfail "Nie mozna wywołać. Powinny być trzy parametry"
}

trap "trap_exit" EXIT

[ "$1" == "" ] || [ "$2" == "" ] || [ "$3" == "" ] && help

ksef_sendinvoice $1 $2 $3

