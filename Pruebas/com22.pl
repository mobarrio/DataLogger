#! perl -w

use strict;
use Win32::SerialPort;

my $cont = 1;
my $alias = "COM22";
my $ob = Win32::SerialPort->new ($alias) || die;

$ob->baudrate(38400);
$ob->parity("none");
$ob->parity_enable(1); 	# for any parity except "none"
$ob->databits(8);
$ob->stopbits(1);
$ob->handshake('none');
$ob->write_settings;

my $baud   = $ob->baudrate;
my $parity = $ob->parity;
my $data   = $ob->databits;
my $stop   = $ob->stopbits;
my $hshake = $ob->handshake;
print "DEV = $alias, B = $baud, D = $data, S = $stop, P = $parity, H = $hshake\n";


$ob->read_interval(1000);
my $InBytes = 1024;
my $count = 0;
my $result = "";
while (1)
{
	if($count > 0)
	{
		if($result =~ m/05/g)     { print "Recv ACK\n"; }
		elsif($result =~ m/13/g)  { print "Recv EOT\n"; }
		else                      { print "Recv DATA\n"; }
		print "W:[$cont] R:[$result]\n";
		$ob->write("$cont\r");
		$cont++;
	}
	($count, $result) = $ob->read($InBytes);
}

undef $ob; 