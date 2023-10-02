source ./env.rc
source $KSEFPROCDIR/proc/commonproc.sh
source $KSEFPROCDIR/proc/ksefproc.sh
source proc/ksefloader.sh

I="../ksef/example/faktura.xml"
#I="../ksef/example/Faktura_KSeF.xml"

#TEMP=`crtemp`
#ksef_acceptinvoice $I $TEMP
#cat $TEMP
#trap "echo 'trap' " EXIT

ksief_bufor

echo "aaa"



