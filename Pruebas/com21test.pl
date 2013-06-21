#! perl -w

use IO::Handle;
#Open the serial port for communication

$COM_PORT = "com21";
print "Trying to open $COM_PORT\n";
system("mode $COM_PORT baud=38400 data=8 stop=1 rts=on dtr=on parity=n");
print "mode command worked properly\n";
open DEV, "+>$COM_PORT" or die "Failed to open communication port\n";
print "$COM_PORT device is opened properly\n";
$ofh = select(DEV); $| = 0; select($ofh);
print "select call returned\n";

#Actual logic is here

my $jnk="";
print "Waiting for data\n";
$jnk = <DEV>;
print "Recieve: $jnk";
print "sending OK\n>";
print DEV "OK\n\n>";
print "\n";

print "Reading\n";
$jnk = <DEV>;