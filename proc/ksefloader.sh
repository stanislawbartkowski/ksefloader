# -------------------------
# Solution based on ksef
# -------------------------
# Date: 2023/09/28
# Date: 2023/11/26 - Usunięcie faktury z bufora
# Date: 2023/11/28 - Przebudowa, usunięcie bufora

# Creates working space
# Does not impact existing installation
function ksef_creatework() {
  log "Zakładanie bazy faktur w $WORKDIRECTORY"
  local -r BEG=`getdate`
  mkdir -p $WORKDIRECTORY
  local -r END=`getdate`
  journallognocomment "Założenie bazy danych" "$BEG" "$END" $OK
}

# Removes to content of the working space
function ksef_clearwork() {
  log "Usunięcie danych w $WORKDIRECTORY"
  local -r BEG=`getdate`
  rm -rf $WORKDIRECTORY/*
  local -r END=`getdate`
  journallog "Usunięcie danych" "$BEG" "$END" $OK "Usunięcie danych z $WORKDIRECTORY"
}

function ksef_initsession() {
  local -r NIP=$1
  local -r TEMP=`crtemp`
  local -r INITTOKEN=`crtemp`  
  requestchallenge $NIP $TEMP
  logfile $TEMP
  createinitxmlfromchallenge $NIP $TEMP >$INITTOKEN
  requestinittoken $INITTOKEN $SESSIONSTATUS
  INIT_SESSION=1
}


# Read invoices using paging
# $1 < NIP
# $2 < DATE_FROM
# $3 < DATE_TO
# $4 > RESULT
function ksef_readinvoices() {
  local -r page_size=10
  local -r NIP=$1
  local -r DATE_FROM=$2
  local -r DATE_TO=$3
  local -r RES=$4
  local -r TEMP=`crtemp`
  local -r page_size=10
  
  ksef_initsession $NIP
  requestsessionstatus $SESSIONSTATUS $TEMP

  echo '{ "res" : [] }' >$RES
  local page_offset=0
  while true; do
    log "Odczytaj od $page_offset $page_size faktur"
    requestinvoicesync $SESSIONSTATUS $DATE_FROM $DATE_TO $page_offset $page_size $TEMP
    R=`jq -r '.invoiceHeaderList' $TEMP`
    if [ "$R" == "[]" ]; then break; fi
    jq -n --slurpfile doc1  $RES --slurpfile doc2 $TEMP  '{ res: ($doc1[0].res + $doc2[0].invoiceHeaderList) }' >$RES
    (( page_offset+=$page_size ))
  done
  local -r END=`getdate`
  local -r MESS="Faktury zostały odczytane"
  log "$MESS"
  journallog "$OP" "$BEG" "$END" $ERROR "$MESS"
  requestsessionterminate $SESSIONSTATUS
  INIT_SESSION=0
}

# Send invoice to KSeF
# $1 < - nip
# $2 < - invoice
# $3 > - invoice reference status including ksefRefereneNumber and sessionReferenceNumber
# Returns
# 0 - OK
# 1 - ERROR while communicating with KSeF
# 2 - Invalid XML Schema
function ksef_sendinvoice() {
  local -r NIP=$1
  local -r INVOICE=$2
  local -r OUTTEMP=$3
  local -r BEG=`getdate`
  local -r TEMP=`crtemp`
  local -r OP="Wysłanie faktury do KSeF"
  log "$MESS"

  ksef_initsession $NIP
  requestsessionstatus $SESSIONSTATUS $TEMP

  log "Sprawdzanie poprawności $INVOICE ze schematem $KSEFPROCDIR/xsd/schemat.xsd" 

  if ! xmllint $INVOICE --schema $KSEFPROCDIR/xsd/schemat.xsd --noout 1>>$LOGFILE 2>&1 ; then
    local -r END=`getdate`
    journallog "$OP" "$BEG" "$END" $BLAD "Faktura niezgodna ze schematem xsd"
    log "Błąd podczas sprawdzania zgodności faktury ze schematem"
    return 2
  fi
  requestinvoicesendandreference $SESSIONSTATUS $INVOICE $OUTTEMP
  local -r END=`getdate`
  journallog "$OP" "$BEG" "$END" $OK "Faktura wysłana do KSeF"
  requestsessionterminate $SESSIONSTATUS
  INIT_SESSION=0
}

# Get UPO
# $1 < session reference number
# $2 > result
function ksef_getupo() {
  local -r REFERENCE=$1
  local -r OUTRES=$2
  local -r OP="Odczytanie UPO dla sesji"
  local -r BEG=`getdate`

  log "$OP $REFERENCE"
  requestcommonsessionstatus $REFERENCE $OUTRES
  local -r END=`getdate`
  journallog "$OP" "$BEG" "$END" $OK "Session status odczytany"
}