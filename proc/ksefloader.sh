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
    logfail "Błąd podczas sprawdzanie zgodności faktury"
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
  journallog "$OP" "$BEG" "$END" $OK "Przeniesiono do KSef $NO faktur"
  log "Przeniesiono $NO faktur znalezionych w $BUFORDIR"
  requestsessionterminate $SESSIONTOKEN
  INIT_SESSION=0
}
