NIP=5328617307
I="../ksef/example/faktura.xml"
TEMP=/tmp/uuid.txt

RES=/tmp/res.json
#./acceptinvoice.sh $NIP $I $TEMP
./read_invoice.sh $NIP "2023-10-01" "2023-10-21" $RES




