source ./env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source proc/ksefloader.sh

help() {
    echo "Wstawienie faktury do bufora w celu wysłania do KSeF"
    echo "Wywołanie:"
    echo "   acceptinvoice.sh <ścieżka do faktury XML> <plik z wynikiem>"
    logfail "Nie mozna wywołać. Powinny być dwa parametry"
}

[ "$1" == "" ] && [ "$2" == "" ] && help

ksef_acceptinvoice $1 $2

