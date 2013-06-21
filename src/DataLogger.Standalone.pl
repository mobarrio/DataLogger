#!perl -w

####################################################################################################################################################################################### 
###                                                                                                                                                                                 ###
### DataloggerASTM - Copyright (c) 2012 by Mariano Jorge Obarrio Miles.                                                                                                             ###
### This work is made available under the terms of licensed under a Creative Commons Reconocimiento-NoComercial 3.0 Unported License http://creativecommons.org/licenses/by-nc/3.0/ ###
### Legal Code (the full license): http://creativecommons.org/licenses/by-nc/3.0/legalcode                                                                                          ###
###                                                                                                                                                                                 ###
#######################################################################################################################################################################################
#

use strict;
use warnings;
use Win32::SerialPort; # on Windows 
use Getopt::Long;
use POSIX;
use DBI;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Data::Uniqid qw (uniqid luniqid);
use Config::Tiny;
use Time::HiRes qw(usleep time alarm sleep);
use Fcntl ':flock';
#use File::stat;
#use Data::Dumper;

BEGIN { open(STDERR, ">DataLogger.err") || die "Can't write to file: $!\n";  }
# turn on autoflush
$|=1;

my $Config 				= Config::Tiny->new;
my $conffile 			= 'DataLogger.conf';
my (%Resultados, %Data) = ();
my $db					= "ASTM";
my $host				= "192.168.1.66";
my $port				= "3306";
my $userid				= "astm";
my $passwd				= "astm123";
my $DEVICE				= "com1";
my $baudrate			= 57600;
my $databits			= 8; 
my $stopbits			= 1;
my $parity				= "none";
my $handshake			= "none"; # following: "none", "rts", "xoff", "dtr".
my $output				= "sql";
my $record_termination 	= 2; # 1 CR, 2 CRLF
my $delay   			= 60;
my ($help, $ckSum, $bool, $quiet, $debug, $schema, $numPac) = (0) x 7;
my ($dbh, $now, $count, $result, $HexRes, $registro, $ck, $idHeader, $idPatient, $idOrden, $idResult, $idComment) = ("") x 12;
my ($serial, $RefField ,$FrameNumber , $FrameType, $PPID, $HID, $PID, $OID, $RID, $CID, $id) = ("") x 11;
my $logtime 			= strftime "%Y-%m-%d %H:%M:%S", localtime;
my %CampoTipo = (
				 C => "Comentario", 
				 H => "Cabecera", 
				 O => "Orden", 
				 P => "Paciente", 
				 R => "Resultado", 
				 Q => "Consulta (Solicita informacion de la orden)",
				 M => "Informacion del fabricante",
				 S => "Scientific Record",
				 L => "Terminador de Registro"
				);

my %Signals = 	(
					CR   => "\x0d", NUL  => "\x00", SOH  => "\x01", STX  => "\x02",	ETX  => "\x03",	EOT  => "\x04",	ENQ  => "\x05",
					ACK  => "\x06", BEL  => "\x07",	BS   => "\x08", HT   => "\x09",	LF   => "\x0a",	VT   => "\x0b",	FF   => "\x0c",
					SO   => "\x0e",	SI   => "\x0f", DLE  => "\x10",	DC1  => "\x11",	DC2  => "\x12",	DC3  => "\x13", DC4  => "\x14", 
					NAK  => "\x15",	SYN  => "\x16", ETB  => "\x17"
				);         

if (-e $conffile)
{
	# Open the config
	$Config = Config::Tiny->read( $conffile );

	$db                 = $Config->{MYSQL}->{db};
	$host               = $Config->{MYSQL}->{host};
	$port               = $Config->{MYSQL}->{port};
	$userid             = $Config->{MYSQL}->{userid};
	$passwd             = $Config->{MYSQL}->{passwd};
	$DEVICE             = $Config->{RS232}->{device};
	$baudrate           = $Config->{RS232}->{baudrate};
	$databits           = $Config->{RS232}->{databits};
	$parity             = $Config->{RS232}->{parity};
	$stopbits           = $Config->{RS232}->{stopbits};
	$handshake          = $Config->{RS232}->{handshake};
	$quiet              = $Config->{General}->{quiet};
	$output             = $Config->{General}->{output};
	$debug              = $Config->{General}->{debug};
	$record_termination = $Config->{General}->{record_termination};
}

$Config->{MYSQL}->{db}                   = $db;
$Config->{MYSQL}->{host}                 = $host;
$Config->{MYSQL}->{port}                 = $port;
$Config->{MYSQL}->{userid}               = $userid;
$Config->{MYSQL}->{passwd}               = $passwd;
$Config->{RS232}->{device}               = $DEVICE;
$Config->{RS232}->{baudrate}             = $baudrate;
$Config->{RS232}->{databits}             = $databits;
$Config->{RS232}->{parity}               = $parity;
$Config->{RS232}->{stopbits}             = $stopbits;
$Config->{RS232}->{handshake}            = $handshake;
$Config->{General}->{quiet}              = $quiet;
$Config->{General}->{output}             = $output;
$Config->{General}->{debug}              = $debug;
$Config->{General}->{record_termination} = $record_termination;

# Save a config
$Config->write( $conffile );

GetOptions (
			"debug"            => \$debug,
			"schema"           => \$schema,
			"help|usage|?"     => \$help
			);

			
# Definicion de Prototipos de la funciones
sub openPort($); 
sub closePort($); 
sub usage;
sub ChkSUM;
sub insertSQL;
sub schema;
sub GetCheckSumValue;
#sub rotateFiles;
sub updateTRC;
sub TRC2TXT;
sub TXT2SQL;
sub logInfo;

if ($schema)           { schema(); };
if (!$DEVICE || $help) { usage();  };
$serial  = openPort($DEVICE);

print "DataLogger is ON [$logtime]\n" if(!$quiet);
print "Open Serial Port : $DEVICE, $baudrate, $databits, $parity, $stopbits, $handshake\n"  if(!$quiet);
if($output eq "sql")
{
	my $connectionInfo="DBI:mysql:database=$db;$host:$port";
	$dbh = DBI->connect($connectionInfo,$userid,$passwd);
}
my ($ENQ) = 0;
my ($BytesRX) = 0;
my $filename = md5_hex(luniqid);
logInfo("Esperando Inicio de Trasmicion [ENQ].\n");
while(1)
{
	$count  = 0;
	$result = "";
	($count, $result) = $serial->read(1);
	
	# Con el usleep intento reducir el numero de ciclos de CPU generados por el While
	if($count == 0) { usleep(2000); next; }

	# Actualiza el archivo de TRACE
	updateTRC($filename, $result);

	# Pasa a Hexa el byte leido
	$HexRes = unpack ("H*", $result);
	if($HexRes =~ /05/)
	{		
			# Si ENQ == 1 El archivo no fue procesado!
			if($ENQ == 1)
			{
				# Incluye un CR en el archivo TRC
				updateTRC($filename,"\n");

				my $now = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime);
				print STDERR "$now - BAD TRANSFER: Se recibe un ENQ sin ser enviado un EOT.\n";
				print STDERR "$now -               Posible registro truncado o corrupto Header_ID:[$filename]\n";
				logInfo("\t- BAD TRANSFER: Se recibe un ENQ sin ser enviado un EOT.\n");
				logInfo("\t                Posible registro truncado o corrupto Header_ID:[$filename]\n");
				
				# Transforma TRC a TXT y luego de TXT a MySQL
				($numPac) = TXT2SQL( TRC2TXT($filename) ); 

				# Actualiza el numero de pacientes si los hay! 
				# Recordar que $filename es igual que el $HID (Header_ID de la tabla Header)
				updateNumPac($filename, $numPac) if(($numPac gt 0) && ($output eq "sql"));
				logInfo("\t- $numPac Pacientes procesados Header_ID:[$filename]\n");

				# Genera un nuevo Archivo
				$filename = md5_hex(luniqid); 
				logInfo("Esperando Inicio de Trasmicion [ENQ].\n");
			}
			logInfo("\t- Reciviendo datos y generando ${filename}.trc\n");

			# Incluye un CR en el archivo TRC
			updateTRC($filename,"\n");

			$serial->transmit_char(0x06);
			$ENQ     = 1;
			$BytesRX = 0;
	}
	elsif($HexRes =~ /15|0a|0A/) { $serial->transmit_char(0x06); } 
	elsif($HexRes =~ /04/) 
	{ 
			# Inicio y Fin de transferencia correcto ENQ <-> EOT
			$ENQ = 0;
			
			#my $filesize = stat("${filename}.trc")->size;
			#logInfo("\tSize: ${filename}.trc\n");
			
			# Incluye un CR en el archivo TRC
			updateTRC($filename,"\n");
			
			# Transforma TRC a TXT y luego de TXT a MySQL
			($numPac) = TXT2SQL( TRC2TXT($filename) ); 

			# Actualiza el numero de pacientes si los hay! 
			# Recordar que $filename es igual que el $HID (Header_ID de la tabla Header)
			updateNumPac($filename, $numPac) if(($numPac gt 0) && ($output eq "sql"));
			logInfo("\t- $numPac Pacientes procesados Header_ID:[$filename]\n");
		
			# Genera un nuevo Archivo
			$filename = md5_hex(luniqid); 
			logInfo("Esperando Inicio de Trasmicion [ENQ].\n");
	}
	# usleep(500);
	usleep(2000); # 0.002 Microsegndo | 1.000.000 Microsegundos == 1 Segundo
}
$dbh->disconnect() if($output eq "sql");
closePort($serial);
;

sub TXT2SQL
{
	no warnings;
	
    return unless (@_ == 1);
	my $filename = shift;
	$filename //= '';

	logInfo("\t- Convirtiendo TXT a SQL.\n");
	open(FILE_IN,  "<${filename}.txt") or die $!;
	
	my ($numPac) = 0;

	# Read the input file line by line
	my $registro = "";
	while(<FILE_IN>)
	{ 
		chop($_);
		$registro  = $_;
		$FrameNumber = substr($_,0,1); # Campo Numero
		$FrameType   = substr($_,1,1); # Campo Tipo de Frame (H, P, O, R, C)

		# Procesa el registro segun el tipo de dato
		if($FrameType =~ /H|h/)
		{ 
				updateNumPac($HID,$numPac) if(($numPac gt 0) && ($output eq "sql"));
				
				# Asignamos el nombre del archivo en hexa como clave en el Header. De esta forma podemos relacionar fisicamente el archivo con MySQL
				$HID    = $filename; #$HID    = md5_hex(luniqid);
				($PPID, $CID, $RID, $OID, $PID) = ""; 
				$numPac = 0;
		} 
		elsif($FrameType =~ /P|p/) { $PID = md5_hex(luniqid); ($PPID, $CID, $RID,$OID)  = ""; $numPac++; }
		elsif($FrameType =~ /O|o/) { $OID = md5_hex(luniqid); ($PPID, $CID, $RID) = ""; }
		elsif($FrameType =~ /R|r/) { $RID = md5_hex(luniqid); ($PPID, $CID) = ""; } 
		elsif($FrameType =~ /C|c/)
		{ 
			$CID = md5_hex(luniqid); 
			if   (!$PID && !$OID && !$RID) { $PPID = $HID; $RefField = "Header_ID";  } # $CID = md5_hex($HID); - Comentario de la Cabecera
			elsif(!$OID && !$RID)          { $PPID = $PID; $RefField = "Patient_ID"; } # $CID = md5_hex($PID); - Comentario del Paciente
			elsif(!$RID)                   { $PPID = $OID; $RefField = "Orden_ID";   } # $CID = md5_hex($OID); - Comentario de la Orden
			else                           { $PPID = $RID; $RefField = "Result_ID";  } # $CID = md5_hex($RID); - Comentario del Resultado
		}
		elsif($FrameType =~ /Q|q|M|m|S|s|L|l/ ) { } # Resto de FRAMETYPES Ignorados
		Send2MySQL($registro);
	}
	close(FILE_IN);
	return($numPac);
}

sub TRC2TXT
{
	no warnings;
	
	return unless (@_ == 1);
	my $filename = shift;
	$filename //= '';

	logInfo("\t- Convirtiendo TRC a TXT.\n");
	open(FILE_IN,  "<${filename}.trc") or die $!;
	open(FILE_OUT, ">${filename}.txt") or die $!;

	# Read the input file line by line
	my $record = "";
	while(<FILE_IN>)
	{
		my($record) = $_;
		$record =~ s/(\x05)//eg;
		$record =~ s/(\x04)//eg;
		$record =~ s/(\x02)//eg;
		$record =~ s/(\x03)/sprintf ord($1)/eg;
		$record =~ s/\n//eg;
		$record =~ s/\r//eg;
		next if(length($record) == 0);
		my $FrameNumber = substr($record,0,1);
		my $FrameType   = substr($record,1,1);
		my $CkSum1      = substr($record,length($record)-2,2);
		$record         = substr($record,0,length($record)-3);
		my $CkSum2      = ChkSUM("${record}\x0d\x03");
		print FILE_OUT  "$record\n";
		my $now = POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime);
		if("$CkSum1" ne "$CkSum2")
		{
			print STDERR "$now - BAD CHECKSUM    : $record - [$CkSum1 ne $CkSum2]\n";
			logInfo("\t\t- BAD CHECKSUM    : $record - [$CkSum1 ne $CkSum2]\n");
		}
		if($FrameNumber =~ m/[^0-7]/g)
		{
			print STDERR "$now - BAD FRAMENUMBER : $record - [$FrameNumber]\n";
			logInfo("\t\t- BAD FRAMENUMBER : $record - [$FrameNumber]\n");
		}
		if($FrameType =~ m/[^HPORCQMSL]/ig)
		{
			print STDERR "$now - BAD FRAMETYPE   : $record - [$FrameType]\n";
			logInfo("\t\t- BAD FRAMETYPE   : $record - [$FrameType]\n");
		}
	}
	close(FILE_IN);
	close(FILE_OUT);
	
	return($filename);
}

sub Send2MySQL
{
	return unless (@_ == 1);
	my ($rec) = shift;
	$rec //= '';
	if(length($rec) == 0) { return; }

	my $FrameNumber = substr($_,0,1); # Campo Numero
	my $FrameType   = substr($_,1,1); # Campo Tipo de Frame (H, P, O, R, C)
	my $Status = "NA";
	my @campos      = split(/\|/, $rec);
	my %Data = ();
	my $id  = '';
	my $ck = ""; #ChkSUM("\x02${rec}\x0d\x03"); <-- Verificar!
	if($FrameType =~ /H|h/)
	{
		$id = $HID;
		%Data = 
			(
				"Header_$id" => 
				{
					"Header_ID"                 => $HID,
					"Access_Password" 			=> $campos[3], 
					"Sender_Name" 				=> $campos[4], 
					"Sender_Address" 			=> $campos[5], 
					"Reserved" 					=> $campos[6], 
					"Sender_Telephone" 			=> $campos[7], 
					"Characteristics_Of_Sender" => $campos[8], 
					"Receiver_ID" 				=> $campos[9], 
					"Comments" 					=> $campos[10], 
					"Processing_ID" 			=> $campos[11], 
					"ASTM_Version" 				=> $campos[12], 
					"Date_and_Time" 		    => $campos[13],
					"Status"                    => $Status,
					"Checksum" 					=> $ck
				}
			);
	}
	elsif($FrameType =~ /P|p/)
	{
		$id = $PID;
		%Data = 
			(
				"Patient_$id" => 
				{
					"Patient_ID"                                                => $PID,
					"Header_ID"                                                 => $HID,
					"Sequence" 													=> $campos[1],
					"Practice_Assigned_Patient_ID" 								=> $campos[2],
					"Laboratory_Assigned_Patient_ID" 							=> $campos[3],
					"Patient_ID_No_3" 											=> $campos[4],
					"Patient_Name_Name_First_name" 								=> $campos[5],
					"Mothers_Maiden_Name" 										=> $campos[6],
					"Birthdate" 												=> $campos[7],
					"Patient_Sex" 												=> $campos[8],
					"Patient_Race_thnic_Origin" 								=> $campos[9],
					"Patient_Address" 											=> $campos[10],
					"Reserved" 													=> $campos[11],
					"Patient_Telephone_Nb" 										=> $campos[12],
					"Attending_Physician_ID" 									=> $campos[13],
					"Special_Field_1" 											=> $campos[14],
					"Special_Field_2" 											=> $campos[15],
					"Patient_Height" 											=> $campos[16],
					"Patient_Weight" 											=> $campos[17],
					"Patients_Known_or_Suspected_Diagnosis" 					=> $campos[18],
					"Patient_Active_Medication" 								=> $campos[19],
					"Patients_Diet" 											=> $campos[20],
					"Practice_Field_1" 											=> $campos[21],
					"Practice_Field_2" 											=> $campos[22],
					"Admission_and_Discharge_Dates" 							=> $campos[23],
					"Admission_Status" 											=> $campos[24],
					"Location" 													=> $campos[25],
					"Nature_of_Alternative_Diagnostic_Code_and_Classifiers_1" 	=> $campos[26],
					"Nature_of_Alternative_Diagnostic_Code_and_Classifiers_2" 	=> $campos[27],
					"Patient_Religion" 											=> $campos[28],
					"Martial_status" 											=> $campos[29],
					"Isolation_Status" 											=> $campos[30],
					"Language" 													=> $campos[31],
					"Hospital_Service" 											=> $campos[32],
					"Hopital_Institution" 										=> $campos[33],
					"Dosage_Category" 											=> $campos[34],
					"Status"                                                    => $Status,
					"Checksum" 													=> $ck				
				}
			);
	}
	elsif($FrameType =~ /O|o/)
	{
		$id = $OID;
		%Data = 
			(
				"Orden_$id" => 
				{
					"Orden_ID"                                          => $OID,
					"Patient_ID"										=> $PID,
					"Sequence" 											=> $campos[1],
					"Sample_ID" 										=> $campos[2],
					"Instrument_Specimen_ID" 							=> $campos[3],
					"Universal_Test_ID" 								=> $campos[4],
					"Priority" 											=> $campos[5],
					"Requested_Ordered_Date_and_Time" 					=> $campos[6],
					"Specimen_Collection_Date_and_Time" 				=> $campos[7],
					"Collection_End_Time" 								=> $campos[8],
					"Collection_Volume" 								=> $campos[9],
					"Collector_ID" 										=> $campos[10],
					"Action_Code" 										=> $campos[11],
					"Danger_Code" 										=> $campos[12],
					"Relevant_Clinical_Informations" 					=> $campos[13],
					"Date_Time_Specimen_Received" 						=> $campos[14],
					"Specimen_Descriptor" 								=> $campos[15],
					"Ordering_Physician" 								=> $campos[16],
					"Physician_Tel_Nb" 									=> $campos[17],
					"User_Field_1" 										=> $campos[18],
					"User_Field_2" 										=> $campos[19],
					"Laboratory_Field_1" 								=> $campos[20],
					"Laboratory_Field_2" 								=> $campos[21],
					"Date_and_Time_Results_reported_or_last_modified" 	=> $campos[22],
					"Instrument_Charge_to_Computer_System" 				=> $campos[23],
					"Instrument_Section_ID" 							=> $campos[24],
					"Report_Types" 										=> $campos[25],
					"Reserved" 											=> $campos[26],
					"Location_or_Ward_of_Specimen_Collection" 			=> $campos[27],
					"Nosocomial_Infection_Flag" 						=> $campos[28],
					"Specimen_Service" 									=> $campos[29],
					"Specimen_institution" 								=> $campos[30],
					"Status"                                            => $Status,
					"Checksum" 											=> $ck
				}
			);
	}
	elsif($FrameType =~ /R|r/)
	{
		$id = $RID;
		%Data = 
			(
				"Result_$id" => 
				{ 
					"Result_ID"                                     => $RID,
					"Orden_ID"									    => $OID,
					"Sequence" 										=> $campos[1],
					"Universal_Test_ID" 							=> $campos[2],
					"Data_or_Measurement_value" 					=> $campos[3],
					"Unit" 											=> $campos[4],
					"Reference_Range" 								=> $campos[5],
					"Result_Abnormal_Flag" 							=> $campos[6],
					"Nature_of_Abnormality_Testing" 				=> $campos[7],
					"Result_Status" 								=> $campos[8],
					"Date_of_Change_in_Normative_Values_or_Units" 	=> $campos[9],
					"Operator_Identification" 						=> $campos[10],
					"Date_Time_Test_Starting" 						=> $campos[11],
					"Date_Time_Test_Completed" 						=> $campos[12],
					"Instrument_Identification" 					=> $campos[13],
					"Status"                                        => $Status,
					"Checksum" 										=> $ck
				}
			);
	}
	elsif($FrameType =~ /C|c/)
	{
		$id = $CID;
		if   ($RefField =~ /Header_ID/g)  { $FrameType = "HC"; }
		elsif($RefField =~ /Patient_ID/g) { $FrameType = "PC"; }
		elsif($RefField =~ /Orden_ID/g)   { $FrameType = "OC"; }
		elsif($RefField =~ /Result_ID/g)  { $FrameType = "RC"; }
		%Data = 
			( 
				"Comment_$id" => 
				{	
					"Comment_ID"      => $CID,
					$RefField         => "$PPID",
					"Sequence" 		  => $campos[1], 
					"Comment_Source"  => $campos[2], 
					"Text" 			  => $campos[3], 
					"Comment_Type"	  => $campos[4], 
					"Status"    	  => $Status,
					"Checksum" 		  => $ck 
				}
			);
	}
	else { return; }
	# Elimina campos del registro no definidos para acelerar el INSERT 
	for my $val ( keys %Data ) 
	{
		for my $val2 ( keys %{ $Data{$val} } ) 
		{
			delete $Data{$val}{$val2} if((not defined $Data{$val}{$val2}) || length($Data{$val}{$val2}) == 0); 
		}
	} 
	# print Dumper(%Data);
	# Envia la salia al SQL o a la PANTALLA
	if($output eq "sql") { insertSQL($id,$FrameType,%Data); }
	#else                 { print "$rec\n"; }
}

sub updateNumPac
{
	my ($id, $numpac) = @_;
	
    $id //= '';
	$numpac //= 0;

	# Realizamos la conexión a la base de datos 
	my $SentenciaSQL = "SELECT COUNT(1) FROM Header WHERE Header_ID = '$id';";
	my $sth = $dbh->prepare($SentenciaSQL);
	$sth->execute();
	my $exite = $sth->fetch()->[0]; # 0 Implica que el valor es nuevo!
	if($exite > 0) 
	{
		#Sentencia SQL 
		$SentenciaSQL = "UPDATE Header Set NumPac=$numpac WHERE Header_ID = '$id';";
		$sth = $dbh->prepare($SentenciaSQL);
		# Ejecutamos el query 
		$sth->execute();
	}
	$sth->finish();

}

sub insertSQL
{
	my ($id, $FrameType, %hash) = @_;
	
    $id //= '';
	$FrameType //= '';
	
	usage() if(!$db || !$host || !$userid || !$passwd);
	
	my %Tables = (C => "Comment",    H => "Header",    O => "Orden",    P => "Patient",    R => "Result",    PC => "Comment_Patient", OC => "Comment_Orden", RC => "Comment_Result" );
	my %Fields = (C => "Comment_ID", H => "Header_ID", O => "Orden_ID", P => "Patient_ID", R => "Result_ID", PC => "Comment_ID",      OC => "Comment_ID",    RC => "Comment_ID" );

	return if(not defined $Tables{$FrameType});

	# Realizamos la conexión a la base de datos 
	my $SentenciaSQL = "SELECT COUNT(1) FROM $Tables{$FrameType} WHERE $Fields{$FrameType}='$id';";
	my $sth = $dbh->prepare($SentenciaSQL);
	$sth->execute();
	my $exite = $sth->fetch()->[0]; # 0 Implica que el valor es nuevo!
	if($exite == 0) 
	{
		my $sujeto = "";
		my $predicado = "";
		foreach my $k (keys %hash)
		{
		my @keys   = keys %{$hash{$k}};
		my @values = values %{$hash{$k}};
		my $elementos = scalar(@keys);
		my $cont = 1;
		
		foreach my $valor (@keys) 
		{ 
			$sujeto    .= "$valor"; 
			$predicado .= "'$hash{$k}{$valor}'";
			if($cont < $elementos)
			{
			$sujeto    .= ",";
			$predicado .= ",";
			}
			$cont++;
		}		
		#Sentencia SQL 
		$SentenciaSQL = "INSERT INTO $Tables{$FrameType}($sujeto) VALUES ($predicado);";
		
		$sth = $dbh->prepare($SentenciaSQL);
		
		# Ejecutamos el query 
		$sth->execute();
		}
	}
	else { logInfo("\t- Registro Duplicado $Fields{$FrameType}:[$id] en la tabla $Tables{$FrameType}\n"); }
	$sth->finish();
}

sub ChkSUM
{
	my $str = shift;
	my @c = split(//,$str);
	my $chksum = 0;
	for my $c ( @c ) { $chksum = ( $chksum + ord($c) ) % 256; }
	$result = uc(sprintf("%.2x", $chksum));
	return($result)
}


sub logInfo
{
    return unless (@_ == 1);
	my ($data) = shift;
	$data //= '';
	my $logtime = strftime "%Y-%m-%d %H:%M:%S", localtime;
	print "${logtime} ${data}" if($debug);
	# print STDERR "${logtime} ${data}" if($debug);
}

sub updateTRC
{
    return unless (@_ == 2);
	my ($filename, $data) = @_;
	
	$filename //= '';
	$data //= '';
	#return if(length($filename) == 0 || length($data) == 0);
	return unless (length $filename and length $data);
	
	open(DT, ">>${filename}.trc");
	flock(DT, LOCK_EX); # try to lock the file exclusively, will wait till you get the lock
	print DT $data; 
	flock(DT, LOCK_UN);
	close(DT);
}

sub openPort($) 
{ 
    my ($device) = @_; 

    #my $serial = Device::SerialPort->new ($device, 1); # on UNIX 
    my $serial = Win32::SerialPort->new ($device, 1); # on Windows 
    die "No se puede abrir el puerto serie: $^E\n" unless ($serial); 
    $serial->user_msg(1); 
    $serial->baudrate($baudrate); 
    $serial->databits($databits); 
    $serial->parity($parity); 
    $serial->stopbits($stopbits); 
    $serial->handshake($handshake); 
	$serial->write_settings;
	#$serial->save("$device.cfg") if($args{s});
	#print "wrote configuration file $device.cfg\n";
    return $serial; 
} 

sub closePort($) 
{ 
    my ($serial) = @_; 
    $serial->close(); 
	undef $serial; 
	logInfo("DataLogger is OFF\n");
}

sub usage
{
	print "Usage:\n";
	print "\n";
	
	print "usage: DataLogger 
                  -debug : Modo DEBUG\n
                  -schema: Crea Schema de MySQL (ASTM-Schema.sql).\n\n";
	print "  # DataLogger -debug\n";	
	print "  # DataLogger -schema\n";
	print "\n Nota: Toda la configuracion se define en el archivo DataLogger.conf\n";
	exit;
}

sub schema
{
 my $filename = "ASTM-Schema.sql";
 open(my $fh, ">$filename") or die "cannot open $filename: $!";
 print $fh <<__HELP__;
/*
MySQL - 5.1.53 : Database - ASTM
*********************************************************************
*/


/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET \@OLD_UNIQUE_CHECKS=\@\@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET \@OLD_FOREIGN_KEY_CHECKS=\@\@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET \@OLD_SQL_MODE=\@\@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET \@OLD_SQL_NOTES=\@\@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`ASTM` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `ASTM`;

/*Table structure for table `Action_Code` */

DROP TABLE IF EXISTS `Action_Code`;

CREATE TABLE `Action_Code` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Action_Code` */

LOCK TABLES `Action_Code` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Orden` */

DROP TABLE IF EXISTS `Comment_Orden`;

CREATE TABLE `Comment_Orden` (
  `Comment_ID` varchar(33) NOT NULL,
  `Orden_ID` varchar(33) DEFAULT NULL,
  `Reference_Table` varchar(15) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Comment_Source` varchar(1) DEFAULT NULL,
  `Text` varchar(100) DEFAULT NULL,
  `Comment_Type` varchar(1) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Comment_ID`),
  KEY `Comment-Source` (`Comment_Source`),
  KEY `Comment-Type` (`Comment_Type`),
  KEY `Comment-Orden` (`Orden_ID`),
  CONSTRAINT `Comment_Orden` FOREIGN KEY (`Orden_ID`) REFERENCES `Orden` (`Orden_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Orden` */

LOCK TABLES `Comment_Orden` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Patient` */

DROP TABLE IF EXISTS `Comment_Patient`;

CREATE TABLE `Comment_Patient` (
  `Comment_ID` varchar(33) NOT NULL,
  `Patient_ID` varchar(33) DEFAULT NULL,
  `Reference_Table` varchar(15) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Comment_Source` varchar(1) DEFAULT NULL,
  `Text` varchar(100) DEFAULT NULL,
  `Comment_Type` varchar(1) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Comment_ID`),
  KEY `Comment-Source` (`Comment_Source`),
  KEY `Comment-Type` (`Comment_Type`),
  KEY `Comment-Orden` (`Patient_ID`),
  CONSTRAINT `Comment_Patient` FOREIGN KEY (`Patient_ID`) REFERENCES `Patient` (`Patient_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Patient` */

LOCK TABLES `Comment_Patient` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Result` */

DROP TABLE IF EXISTS `Comment_Result`;

CREATE TABLE `Comment_Result` (
  `Comment_ID` varchar(33) NOT NULL,
  `Result_ID` varchar(33) DEFAULT NULL,
  `Reference_Table` varchar(15) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Comment_Source` varchar(1) DEFAULT NULL,
  `Text` varchar(100) DEFAULT NULL,
  `Comment_Type` varchar(1) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Comment_ID`),
  KEY `Comment-Source` (`Comment_Source`),
  KEY `Comment-Type` (`Comment_Type`),
  KEY `Comment-Orden` (`Result_ID`),
  CONSTRAINT `Comment_Result` FOREIGN KEY (`Result_ID`) REFERENCES `Result` (`Result_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Result` */

LOCK TABLES `Comment_Result` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Source` */

DROP TABLE IF EXISTS `Comment_Source`;

CREATE TABLE `Comment_Source` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Source` */

LOCK TABLES `Comment_Source` WRITE;

UNLOCK TABLES;

/*Table structure for table `Comment_Type` */

DROP TABLE IF EXISTS `Comment_Type`;

CREATE TABLE `Comment_Type` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Comment_Type` */

LOCK TABLES `Comment_Type` WRITE;

UNLOCK TABLES;

/*Table structure for table `Header` */

DROP TABLE IF EXISTS `Header`;

CREATE TABLE `Header` (
  `Header_ID` varchar(33) NOT NULL,
  `Access_Password` varchar(50) DEFAULT NULL,
  `Sender_Name` varchar(50) DEFAULT NULL,
  `Sender_Address` varchar(50) DEFAULT NULL,
  `Reserved` varchar(50) DEFAULT NULL,
  `Sender_Telephone` varchar(20) DEFAULT NULL,
  `Characteristics_Of_Sender` varchar(50) DEFAULT NULL,
  `Receiver_ID` varchar(33) DEFAULT NULL,
  `Comments` varchar(50) DEFAULT NULL,
  `Processing_ID` varchar(33) DEFAULT NULL,
  `ASTM_Version` varchar(50) DEFAULT NULL,
  `Date_and_Time` varchar(14) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  `NumPac` int(11) DEFAULT '0',
  PRIMARY KEY (`Header_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Header` */

LOCK TABLES `Header` WRITE;

UNLOCK TABLES;

/*Table structure for table `Message_Terminator` */

DROP TABLE IF EXISTS `Message_Terminator`;

CREATE TABLE `Message_Terminator` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(70) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Message_Terminator` */

LOCK TABLES `Message_Terminator` WRITE;

UNLOCK TABLES;

/*Table structure for table `Nature_of_Abnormality_Testing` */

DROP TABLE IF EXISTS `Nature_of_Abnormality_Testing`;

CREATE TABLE `Nature_of_Abnormality_Testing` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Nature_of_Abnormality_Testing` */

LOCK TABLES `Nature_of_Abnormality_Testing` WRITE;

UNLOCK TABLES;

/*Table structure for table `Orden` */

DROP TABLE IF EXISTS `Orden`;

CREATE TABLE `Orden` (
  `Orden_ID` varchar(33) NOT NULL,
  `Patient_ID` varchar(33) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Sample_ID` varchar(22) DEFAULT NULL,
  `Instrument_Specimen_ID` varchar(1) DEFAULT NULL,
  `Universal_Test_ID` varchar(15) DEFAULT NULL,
  `Priority` varchar(1) DEFAULT NULL,
  `Requested_Ordered_Date_and_Time` varchar(20) DEFAULT NULL,
  `Specimen_Collection_Date_and_Time` varchar(20) DEFAULT NULL,
  `Collection_End_Time` varchar(20) DEFAULT NULL,
  `Collection_Volume` varchar(50) DEFAULT NULL,
  `Collector_ID` varchar(50) DEFAULT NULL,
  `Action_Code` varchar(1) DEFAULT NULL,
  `Danger_Code` varchar(50) DEFAULT NULL,
  `Relevant_Clinical_Informations` varchar(50) DEFAULT NULL,
  `Date_Time_Specimen_Received` varchar(20) DEFAULT NULL,
  `Specimen_Descriptor` varchar(20) DEFAULT NULL,
  `Ordering_Physician` varchar(50) DEFAULT NULL,
  `Physician_Tel_Nb` varchar(20) DEFAULT NULL,
  `User_Field_1` varchar(50) DEFAULT NULL,
  `User_Field_2` varchar(50) DEFAULT NULL,
  `Laboratory_Field_1` varchar(50) DEFAULT NULL,
  `Laboratory_Field_2` varchar(50) DEFAULT NULL,
  `Date_and_Time_Results_reported_or_last_modified` varchar(20) DEFAULT NULL,
  `Instrument_Charge_to_Computer_System` varchar(50) DEFAULT NULL,
  `Instrument_Section_ID` varchar(50) DEFAULT NULL,
  `Report_Types` varchar(1) DEFAULT NULL,
  `Reserved` varchar(50) DEFAULT NULL,
  `Location_or_Ward_of_Specimen_Collection` varchar(10) DEFAULT NULL,
  `Nosocomial_Infection_Flag` varchar(50) DEFAULT NULL,
  `Specimen_Service` varchar(50) DEFAULT NULL,
  `Specimen_institution` varchar(50) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Orden_ID`),
  KEY `FK_Order` (`Patient_ID`),
  KEY `Order-Action_code` (`Action_Code`),
  KEY `Order-Report_Types` (`Report_Types`),
  CONSTRAINT `FK_Order` FOREIGN KEY (`Patient_ID`) REFERENCES `Patient` (`Patient_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Orden` */

LOCK TABLES `Orden` WRITE;

UNLOCK TABLES;

/*Table structure for table `Patient` */

DROP TABLE IF EXISTS `Patient`;

CREATE TABLE `Patient` (
  `Patient_ID` varchar(33) NOT NULL,
  `Header_ID` varchar(33) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Practice_Assigned_Patient_ID` varchar(20) DEFAULT NULL,
  `Laboratory_Assigned_Patient_ID` varchar(50) DEFAULT NULL,
  `Patient_ID_No_3` varchar(50) DEFAULT NULL,
  `Patient_Name_Name_First_name` varchar(52) DEFAULT NULL,
  `Mothers_Maiden_Name` varchar(50) DEFAULT NULL,
  `Birthdate` varchar(8) DEFAULT NULL,
  `Patient_Sex` varchar(1) DEFAULT NULL,
  `Patient_Race_thnic_Origin` varchar(20) DEFAULT NULL,
  `Patient_Address` varchar(50) DEFAULT NULL,
  `Reserved` varchar(50) DEFAULT NULL,
  `Patient_Telephone_Nb` varchar(20) DEFAULT NULL,
  `Attending_Physician_ID` varchar(20) DEFAULT NULL,
  `Special_Field_1` varchar(20) DEFAULT NULL,
  `Special_Field_2` varchar(20) DEFAULT NULL,
  `Patient_Height` varchar(5) DEFAULT NULL,
  `Patient_Weight` varchar(5) DEFAULT NULL,
  `Patients_Known_or_Suspected_Diagnosis` varchar(20) DEFAULT NULL,
  `Patient_Active_Medication` varchar(20) DEFAULT NULL,
  `Patients_Diet` varchar(20) DEFAULT NULL,
  `Practice_Field_1` varchar(50) DEFAULT NULL,
  `Practice_Field_2` varchar(50) DEFAULT NULL,
  `Admission_and_Discharge_Dates` varchar(50) DEFAULT NULL,
  `Admission_Status` varchar(50) DEFAULT NULL,
  `Location` varchar(20) DEFAULT NULL,
  `Nature_of_Alternative_Diagnostic_Code_and_Classifiers_1` varchar(50) DEFAULT NULL,
  `Nature_of_Alternative_Diagnostic_Code_and_Classifiers_2` varchar(50) DEFAULT NULL,
  `Patient_Religion` varchar(50) DEFAULT NULL,
  `Martial_status` varchar(50) DEFAULT NULL,
  `Isolation_Status` varchar(50) DEFAULT NULL,
  `Language` varchar(50) DEFAULT NULL,
  `Hospital_Service` varchar(50) DEFAULT NULL,
  `Hopital_Institution` varchar(50) DEFAULT NULL,
  `Dosage_Category` varchar(50) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Patient_ID`),
  KEY `Patient-Sex` (`Patient_Sex`),
  KEY `Header-Patient` (`Header_ID`),
  CONSTRAINT `Header-Patient` FOREIGN KEY (`Header_ID`) REFERENCES `Header` (`Header_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Patient` */

LOCK TABLES `Patient` WRITE;

UNLOCK TABLES;

/*Table structure for table `Patient_Sex` */

DROP TABLE IF EXISTS `Patient_Sex`;

CREATE TABLE `Patient_Sex` (
  `id` varchar(1) NOT NULL,
  `Decripcion` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Patient_Sex` */

LOCK TABLES `Patient_Sex` WRITE;

UNLOCK TABLES;

/*Table structure for table `Priority` */

DROP TABLE IF EXISTS `Priority`;

CREATE TABLE `Priority` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Priority` */

LOCK TABLES `Priority` WRITE;

UNLOCK TABLES;

/*Table structure for table `Report_Types` */

DROP TABLE IF EXISTS `Report_Types`;

CREATE TABLE `Report_Types` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Report_Types` */

LOCK TABLES `Report_Types` WRITE;

UNLOCK TABLES;

/*Table structure for table `Result` */

DROP TABLE IF EXISTS `Result`;

CREATE TABLE `Result` (
  `Result_ID` varchar(33) NOT NULL,
  `Orden_ID` varchar(33) DEFAULT NULL,
  `Sequence` varchar(10) DEFAULT NULL,
  `Universal_Test_ID` varchar(15) DEFAULT NULL,
  `Data_or_Measurement_value` varchar(20) DEFAULT NULL,
  `Unit` varchar(50) DEFAULT NULL,
  `Reference_Range` varchar(50) DEFAULT NULL,
  `Result_Abnormal_Flag` varchar(2) DEFAULT NULL,
  `Nature_of_Abnormality_Testing` varchar(1) DEFAULT NULL,
  `Result_Status` varchar(1) DEFAULT NULL,
  `Date_of_Change_in_Normative_Values_or_Units` varchar(20) DEFAULT NULL,
  `Operator_Identification` varchar(50) DEFAULT NULL,
  `Date_Time_Test_Starting` varchar(20) DEFAULT NULL,
  `Date_Time_Test_Completed` varchar(20) DEFAULT NULL,
  `Instrument_Identification` varchar(20) DEFAULT NULL,
  `Status` varchar(3) DEFAULT NULL,
  `Checksum` varchar(2) DEFAULT NULL,
  PRIMARY KEY (`Result_ID`),
  KEY `Result-Nature_of_Abnormal_Testing` (`Nature_of_Abnormality_Testing`),
  KEY `Result-Abnormal_Flags` (`Result_Abnormal_Flag`),
  KEY `Result-Status` (`Result_Status`),
  KEY `Result-Orden` (`Orden_ID`),
  CONSTRAINT `Result-Orden` FOREIGN KEY (`Orden_ID`) REFERENCES `Orden` (`Orden_ID`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Result` */

LOCK TABLES `Result` WRITE;

UNLOCK TABLES;

/*Table structure for table `Result_Abnormal_ Flags` */

DROP TABLE IF EXISTS `Result_Abnormal_ Flags`;

CREATE TABLE `Result_Abnormal_ Flags` (
  `id` varchar(2) NOT NULL,
  `Descripcion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Result_Abnormal_ Flags` */

LOCK TABLES `Result_Abnormal_ Flags` WRITE;

UNLOCK TABLES;

/*Table structure for table `Result_Status` */

DROP TABLE IF EXISTS `Result_Status`;

CREATE TABLE `Result_Status` (
  `id` varchar(1) NOT NULL,
  `Descripcion` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*Data for the table `Result_Status` */

LOCK TABLES `Result_Status` WRITE;

UNLOCK TABLES;

/*!40101 SET SQL_MODE=\@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=\@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=\@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=\@OLD_SQL_NOTES */;
__HELP__
 close($fh) || warn "close failed: $!";
 print "Schema $filename creado.\n";
 exit;
}
