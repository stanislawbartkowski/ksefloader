# -------------------------
# Solution based on ksef
# -------------------------
# Date: 2023/09/28

BUFORDIR=$WORKDIRECTORY/bufor
FAKTURYDIR=$WORKDIRECTORY/faktury

OK="OK"
BLAD="ERROR"

function getnipdir() {
  echo $BUFORDIR/$1
}

function getnipfakturydir() {
  echo $FAKTURYDIR/$1
}

# Creates working space
# Does not impact existing installation
function ksef_creatework() {
  log "Zakładanie bazy faktur w $WORKDIRECTORY"
  local -r BEG=`getdate`
  mkdir -p $WORKDIRECTORY
  mkdir -p $BUFORDIR
  mkdir -p $FAKTURYDIR
  local -r END=`getdate`
  journallognocomment "Założenie bazy danych" "$BEG" "$END" $OK
}

# Removes to content of the working space
function ksief_clearwork() {
  local -r NIP=$1
  log "Usunięcie danych w $WORKDIRECTORY"
  local -r BEG=`getdate`
  rm -rf $BUFORDIR/$NIP/*
  rm -rf $FAKTURYDIR/$NIP/*
  local -r END=`getdate`
  journallog "Usunięcie danych" "$BEG" "$END" $OK "Usunięcie danych z $WORKDIRECTORY dla $NIP"
}

# Accept invoice to the bufor and assigns uuid 
# $1 < - nip
# $2 < - invoice
# $3 > - temporary file containing the generated uuid
# Returns
function ksef_acceptinvoice() {
  local -r NIP=$1
  local -r INVOICE=$2
  local -r OUTTEMP=$3
  local -r BEG=`getdate`
  local -r UUID=`uuidgen`
  local -r NDIR=`getnipdir $NIP`
  local -r MESS="Kopiowanie faktury z $INVOICE do $NDIR/$UUID.xml"
  local -r OP="Nowa faktura do bufora"
  log "$MESS"
  mkdir -p $NDIR
  if ! xmllint $INVOICE --schema $KSEFPROCDIR/xsd/schemat.xsd --noout 1>>$LOGFILE 2>&1 ; then
    local -r END=`getdate`
    journallog "$OP" "$BEG" "$END" $BLAD "Faktura niezgodna ze schematem xsd"
    log "Błąd podczas sprawdzanie zgodności faktury"
    return 2
  fi
  if ! cp $INVOICE $NDIR/$UUID.xml 2>>$LOGFILE; then 
    local -r END=`getdate`
    journallog "$OP" "$BEG" "$END" $BLAD "Błąd podczas kopiowanie"
    logfail "Błąd podczas kopiowania"
  fi

  echo $UUID >$OUTTEMP
  local -r END=`getdate`
  journallog "$OP" "$BEG" "$END" $OK "UUID: $UUID"
}

function ksef_initsession() {
  local -r NIP=$1
  local -r TEMP=`crtemp`
  local -r INITTOKEN=`crtemp`
  logile
  requestchallenge $NIP $TEMP
  logfile $TEMP
  createinitxmlfromchallenge $NIP $TEMP >$INITTOKEN
  requestinittoken $INITTOKEN $SESSIONTOKEN
  INIT_SESSION=1
}


# Move invoice from bufor to faktury and KSeF
function ksef_faktury_bufor() {
  local -r NIP=$1
  local -r NDIR=`getnipdir $NIP`
  local -r FDIR=`getnipfakturydir $NIP`
  log "Sprawdzanie $NDIR"
  if ! ls $BUFORDIR/**/*.xml >>$LOGFILE 2>&1; then
     local -r END=`getdate`
     log "Nie znaleziono zadnych nowych faktur w $NDIR"
     journallog "$OP" "$BEG" "$END" $OK "Nie znaleziono żadnych nowych faktur w buforze"
     return 0
  fi
  ksef_initsession $NIP
  local -r REFERENCESTATUS=`crtemp`
  for f in $NDIR/*.xml; do
    requestinvoicesendandreference $SESSIONTOKEN $f $REFERENCESTATUS
    local FNAME=$(basename -s .xml $f)
    mkdir -p $FDIR
    mv $f $FDIR/
    [ $? -eq 0 ] || logfail "Failed while moving $f $FDIR"
    cp $REFERENCESTATUS $FDIR/$FNAME.json
    [ $? -eq 0 ] || logfail "Failed while copying $REFERENCESTATUS $FDIR/$FNAME.json"
    NO=$((NO+1))
  done
  local -r END=`getdate`
  journallog "$OP" "$BEG" "$END" $OK "Przeniesiono do KSeF $NO faktur"
  log "Przeniesiono $NO faktur znalezionych w $NDIR"
  requestsessionterminate $SESSIONTOKEN
  INIT_SESSION=0
}

# Get ivoice status using internal uuid
# $1 < internal uuid
# $2 > file path name to put the result
# exit code:
# 0 - OK, invoice sent and $2 contains json with reference number
# 1 - Failure
# 2 - Invoice still in the buffer
# 3 - Invoice rejected

function ksieg_getinvoicestatus() {
  local -r REFERENCE=$1
  local -r RES=$2
  local -r OP="Invoice status"
  local -r BEG=`getdate`
  log "Sprawdzenie statusu faktury $REFERENCE"

  local -r BUFFERFILE=`ls $BUFORDIR/**/$REFERENCE.xml 2>/dev/null`
  local -r FAKTURYFILE=`ls $FAKTURYDIR/**/$REFERENCE.xml 2>/dev/null`

  # check buffer
   if [ -n "$BUFFERFILE" ]; then
     local -r END=`getdate`
     log "Faktura w buforze"
     journallog "$OP" "$BEG" "$END" $OK "Faktura $REFERENCE w buforze"
     return 2
  fi
  [ -z "$FAKTURYFILE" ] && logfail "$REFERENCE - nie ma takiej faktury ani w buforze ani w katalogu z fakturami"
  local FAKTURYJSON=`ls $FAKTURYDIR/**/$REFERENCE.json 2>/dev/null` 
  # jeśli nie ma JSON to pczekaj 5 sekund, moze jest w trakcie czekania na status
  [  -z "$FAKTURYJSON" ] && sleep 5
  local FAKTURYJSON=`ls $FAKTURYDIR/**/$REFERENCE.json 2>/dev/null` 
  if ! cp $FAKTURYJSON $RES; then 
     local -r END=`getdate`
     local -r MESS="Błąd podczas kopiowania $FAKTURYJSON"
     journallog "$OP" "$BEG" "$END" $ERROR "$MESS"
     logfail "$MESS"
  fi
  local -r END=`getdate`
  log "Faktura jest wprowadzona do KSeF i status został przesłany"
  journallog "$OP" "$BEG" "$END" $OK "Status $REFERENCE faktury przesłany"
  return 0
}
