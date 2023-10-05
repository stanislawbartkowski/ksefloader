source ./env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source proc/ksefloader.sh

help() {
    echo "Pobranie stanu faktury wstawionej do buufora"
    echo "Wywołanie:"
    echo "   wezkseffaktura.sh identyfikator_faktury <plik z wynikiem>"
    echo "Zwraca:"
    echo " 0 : OK, jest ksef_reference number"
    echo " 1 : Bład wywołania"
    echo " 2 : Faktura jest w buforze"
    echo " 3 : Faktura odrzucona"
    logfail "Nie mozna wywołać. Powinny być dwa parametry"
}

[ "$1" == "" ] && [ "$2" == "" ] && help

ksieg_getinvoicestatus $1 $2

