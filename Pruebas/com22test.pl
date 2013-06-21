#! perl -w

use IO::Handle;
use Win32::Serialport;
$COM_PORT = "com22";

print "trying to open $COM_PORT\n";
system ("mode $COM_PORT baud=38400 stop=1 data=8 parity=n rts=on dtr=on");

open DEV,"+>$COM_PORT" or die "failed to open com port\n";
$ofh = select(DEV); $| = 0; $/='>'; select($ofh);

#logic starts here

print "Sending ate0 command\n";
print DEV "ate0\n";
$jnk = "";

$jnk = <DEV>;
print "Received: $jnk";