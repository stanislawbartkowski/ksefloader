source ./env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source proc/ksefloader.sh

INIT_SESSION=0
SESSIONTOKEN=`crtemp`
OP="Sprawdzanie bufora z fakturami"
BEG=`getdate`
NO=0


function trap_exit() {
    if [ "$INIT_SESSION" -eq 1 ]; then
        requestsessionterminate $SESSIONTOKEN
        END=`getdate`
        journallog "$OP" "$BEG" "$END" $ERROR "Przeniesiono $NO faktur. Wystąpił błąd podczas przenoszenia"
        removetemp
        log "Wystąpił błąd podczas przenoszenia faktur z bufora"
        return 1
    fi      
    removetemp
}

trap "trap_exit" EXIT

ksef_faktury_bufor
