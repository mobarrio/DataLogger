#! perl -w

use strict;
use Win32::SerialPort;

my $alias = "COM21";
my $ob = Win32::SerialPort->new ($alias) || die;

$ob->baudrate(38400);
$ob->parity("none");
$ob->parity_enable(1); 	# for any parity except "none"
$ob->databits(8);
$ob->stopbits(1);
$ob->handshake('none');
$ob->write_settings;

my $baud = $ob->baudrate;
my $parity = $ob->parity;
my $data = $ob->databits;
my $stop = $ob->stopbits;
my $hshake = $ob->handshake;
print "DEV = $alias, B = $baud, D = $data, S = $stop, P = $parity, H = $hshake\n";

# $ob->save("$alias.cfg");
# print "wrote configuration file $alias.cfg\n";

my $result = "";
my $count = 0;
while($result != "13")
{
	if($count <= 0) 
	{ 
		$ob->write("05"); 
		sleep 1;
	}
	$result = $ob->input();
	chop($result);
	if($result =~ m/05/g)     { print "Recv ACK\n"; }
	elsif($result =~ m/13/g)  { print "Recv EOT\n"; undef $ob; exit;}
	else                      { print "Recv DATA [$result]\n"; }
	
}
undef $ob; 