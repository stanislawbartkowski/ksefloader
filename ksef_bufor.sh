#!/bin/bash
DIR=`dirname $0`
RDIR=`realpath $DIR`
source $RDIR/env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source $RDIR/proc/ksefloader.sh

INIT_SESSION=0
SESSIONTOKEN=`crtemp`
OP="Sprawdzanie bufora z fakturami"
BEG=`getdate`
NO=0

function trap_exit() {
    if [ "$INIT_SESSION" -eq 1 ]; then
        requestsessionterminate $SESSIONTOKEN
        ENDD=`getdate`
        journallog "$OP" "$BEG" "$ENDD" $ERROR "Przeniesiono $NO faktur. Wystąpił błąd podczas przenoszenia"
        removetemp
        log "Wystąpił błąd podczas przenoszenia faktur z bufora"
        return 1
    fi      
    removetemp
}

trap "trap_exit" EXIT

for n in `yq -r ".tokens | keys[]" $TOKENSTORE`; do
  NIP=`echo $n | cut -c 4- `
  echo $NIP
  ksef_faktury_bufor $NIP
done
