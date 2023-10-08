# -------------------------
# Solution based on ksef
# -------------------------
# Date: 2023/09/28

BUFORDIR=$WORKDIRECTORY/bufor
FAKTURYDIR=$WORKDIRECTORY/faktury

OK="OK"
BLAD="ERROR"

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
  log "Usunięcie danych w $WORKDIRECTORY"
  local -r BEG=`getdate`
  rm -rf $BUFORDIR/*
  rm -rf $FAKTURYDIR/*
  local -r END=`getdate`
  journallog "Usunięcie danych" "$BEG" "$END" $OK "Usunięcie danych z $WORKDIRECTORY"
}

# Accept invoice to the bufor and assigns uuid 
# $1 < - invoice
# $2 > - temporary file containing the generated uuid
# Returns
function ksef_acceptinvoice() {
  local -r INVOICE=$1
  local -r BEG=`getdate`
  local -r UUID=`uuidgen`
  local -r MESS="Kopiowanie faktury z $1 do $BUFORDIR/$UUID.xml"
  local -r OP="Nowa faktura do bufora"
  log "$MESS"
  if ! xmllint $INVOICE --schema $KSEFPROCDIR/xsd/schemat.xsd --noout 1>>$LOGFILE 2>&1 ; then
    local -r END=`getdate`
    journallog "$OP" "$BEG" "$END" $BLAD "Faktura niezgodna ze schematem xsd"
    log "Błąd podczas sprawdzanie zgodności faktury"
    return 2
  fi
  if ! cp $1 $BUFORDIR/$UUID.xml 2>>$LOGFILE; then 
    local -r END=`getdate`
    journallog "$OP" "$BEG" "$END" $BLAD "Błąd podczas kopiowanie"
    logfail "Błąd podczas kopiowania"
  fi

  echo $UUID >$2
  local -r END=`getdate`
  journallog "$OP" "$BEG" "$END" $OK "UUID: $UUID"
}

function ksef_initsession() {
  local -r TEMP=`crtemp`
  local -r INITTOKEN=`crtemp`
  requestchallenge $TEMP
  createinitxmlfromchallenge $TEMP >$INITTOKEN
  requestinittoken $INITTOKEN $SESSIONTOKEN
  INIT_SESSION=1
}


# Move invoice from invoice to faktury and KSeF
function ksef_faktury_bufor() {
  log "Sprawdzanie $BUFORDIR"
  if ! ls $BUFORDIR/*.xml >>$LOGFILE 2>&1; then
     local -r END=`getdate`
     log "Nie znaleziono zadnych nowych faktur"
     journallog "$OP" "$BEG" "$END" $OK "Nie znaleziono żadnych nowych faktur w buforze"
     return 0
  fi
  ksef_initsession
  local -r REFERENCESTATUS=`crtemp`
  for f in $BUFORDIR/*.xml; do
    requestinvoicesendandreference $SESSIONTOKEN $f $REFERENCESTATUS
    local FNAME=$(basename -s .xml $f)
    mv $f $FAKTURYDIR/
    cp $REFERENCESTATUS $FAKTURYDIR/$FNAME.json
    NO=$((NO+1))
  done
  local -r END=`getdate`
  journallog "$OP" "$BEG" "$END" $OK "Przeniesiono do KSeF $NO faktur"
  log "Przeniesiono $NO faktur znalezionych w $BUFORDIR"
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

  # check buffer
  local -r BUFFERFILE=$BUFORDIR/$REFERENCE.xml
   if [ -f $BUFFERFILE ]; then
     local -r END=`getdate`
     log "Faktura w buforze"
     journallog "$OP" "$BEG" "$END" $OK "Faktura $REFERENCE w buforze"
     return 2
  fi
  local -r FAKTURYFILE=$FAKTURYDIR/$REFERENCE.xml
  local -r FAKTURYJSON=$FAKTURYDIR/$REFERENCE.json
  # musi byc w FAKTURYDIR
  existfile $FAKTURYFILE
  # jeśli nie ma JSON to pczekaj 5 sekund, moze jest w trakcie czekania na status
  [ ! -f $FAKTURYJSON ] && sleep 5
  existfile $FAKTURYJSON
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
