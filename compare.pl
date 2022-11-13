#!/usr/bin/perl 

use strict;
#use warnings;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Win32::Console::ANSI;
use Term::ANSIScreen qw/:color /;
use Term::ANSIScreen qw(cls);
use Time::HiRes;
use Fcntl qw(:flock :seek);
use String::HexConvert ':all';
use Win32::Console;
use File::Copy qw(copy);
use Regexp::Assemble;
use Term::ANSIScreen qw/:color :cursor :screen :keyboard/;
use Bit::Vector;
use Smart::Comments;

my $CONSOLE=Win32::Console->new;
my $clear_screen = cls(); 
$CONSOLE->Title('BwE PS4 NOR Comparator');

START:

my $BwE = (colored ['bold red'], qq{
===========================================================
|            __________          __________               |
|            \\______   \\ __  _  _\\_   ____/               |
|             |    |  _//  \\/ \\/  /|  __)_                |
|             |    |   \\\\        //       \\               |
|             |______  / \\__/\\__//______  /               |
|                    \\/PS4 NOR Comparator\\/v1.09          |
|        		                                  |
===========================================================\n\n});
print $BwE;

print "Reading Dumps....\n";

my @files=(); ### Collecting Dumps


while (<*.bin>) ### Looking for *.bin
{
    push (@files, $_) if (-s eq "33554432");
}

while (<*.hex>) ### Looking for *.hex
{
    push (@files, $_) if (-s eq "33554432");
}

while (<*.eep>) ### Looking for *.eep
{
    push (@files, $_) if (-s eq "33554432");
}

while (<Dumps/*.bin>) ### Looking for dumps/*.bin
{
    push (@files, $_) if (-s eq "33554432");
}

while (<Dumps/*.hex>) ### Looking for dumps/*.hex
{
    push (@files, $_) if (-s eq "33554432");
}

while (<Dumps/*.eep>) ### Looking for dumps/*.eep
{
    push (@files, $_) if (-s eq "33554432");

}

# Subdirectories

while (<Dumps/*/*.bin>) 
{
    push (@files, $_) if (-s eq "33554432"); ### Looking for dumps/*/*.bin
}

while (<Dumps/*/*.hex>) ### Looking for dumps/*/*.hex
{
    push (@files, $_) if (-s eq "33554432");
}

while (<Dumps/*/*.eep>) ### Looking for dumps/*/*.eep
{
    push (@files, $_) if (-s eq "33554432");

}

while (<Dumps/*/*/*.bin>) ### Looking for dumps/*/*/*.bin
{
    push (@files, $_) if (-s eq "33554432");
}

while (<Dumps/*/*/*.hex>) ### Looking for dumps/*/*/*.hex
{
    push (@files, $_) if (-s eq "33554432");
}

while (<Dumps/*/*/*.eep>) ### Looking for dumps/*/*/*.eep
{
    push (@files, $_) if (-s eq "33554432");

}

print $clear_screen;
print $BwE;

if ( @files <= 1 ) {
	print "There is nothing to compare...\n"; 
	goto EOF;
} 

open(F,'>', "output.txt") || die $!;

my $dumpcount = scalar @files;

print "You will be comparing $dumpcount dumps!\n\n";

print "1. Compare Specific Version Only\n";
print "2. Compare Specific SKU Only\n";
print "3. Compare Specific Version & SKU Only\n";
print "4. Compare All Dumps\n";

print "\nChoose Option: "; 
my $specific_option = <STDIN>; chomp $specific_option; 

print $clear_screen;
print $BwE;

my @array;
my @files_version=();
my @files_sku=();
my @files_combo=();

if ($specific_option eq "1") {
	
	print "Enter version (Example: 3.50): ";
	my $specific_version = <STDIN>; chomp $specific_version; 	
	
	print "\n"; 
	
	foreach my $file (@files) { ### Calculating $file Version... 
		open(my $bin, "<", $file) or die $!; binmode $bin;
		
		my $FW_Version;

		seek($bin, 0x1C906A, 0); 
		read($bin, my $FW_Version2, 0x2);
		$FW_Version2 = uc ascii_to_hex($FW_Version2); 
		if ($FW_Version2 eq "FFFF")
		{
			seek($bin, 0x1CA606, 0); 
			read($bin, my $FW_Version1, 0x2);
			$FW_Version1 = uc ascii_to_hex($FW_Version1); 
			if ($FW_Version1 eq "FFFF")
			{
				$FW_Version = "N/A";
			} 
			else
			{
				$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
				$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
				$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
			}
		} 
		else
		{
			$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
			$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
			$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
		}
		
		if ($specific_version eq $FW_Version) {
			push (@files_version, $file);
			print "\n", (colored ['bold green'], "$file has $FW_Version");
		}
	}
	
	@array = @files_version;
	
} elsif ($specific_option eq "2") {
	
	print "Enter first two digits of SKU (Example: 72 for CUH-7201B): ";
	my $specific_sku = <STDIN>; chomp $specific_sku; 	
	
	print "\n"; 
	
	foreach my $file (@files) { ### Calculating $file SKU... 
		open(my $bin, "<", $file) or die $!; binmode $bin;
		
		seek($bin, 0x1C8041, 0);
		read($bin, my $SKU, 0xA);
		
		seek($bin, 0x1C8045, 0);
		read($bin, my $shortsku, 0x2);
		
		if ($specific_sku eq $shortsku) {
			push (@files_sku, $file);
			print "\n", (colored ['bold green'], "$file has $SKU");
		}
	}
	
	@array = @files_sku;

} elsif ($specific_option eq "3") {
	
	print "Enter version (Example: 3.50): ";
	my $specific_version = <STDIN>; chomp $specific_version; 	
	
	print "\nEnter first two digits of SKU (Example: 72 for CUH-7201B): ";
	my $specific_sku = <STDIN>; chomp $specific_sku; 	
	
	print "\n"; 
	
	foreach my $file (@files) { ### Calculating $file Version... 
		open(my $bin, "<", $file) or die $!; binmode $bin;
		
		my $FW_Version;

		seek($bin, 0x1C906A, 0); 
		read($bin, my $FW_Version2, 0x2);
		$FW_Version2 = uc ascii_to_hex($FW_Version2); 
		if ($FW_Version2 eq "FFFF")
		{
			seek($bin, 0x1CA606, 0); 
			read($bin, my $FW_Version1, 0x2);
			$FW_Version1 = uc ascii_to_hex($FW_Version1); 
			if ($FW_Version1 eq "FFFF")
			{
				$FW_Version = "N/A";
			} 
			else
			{
				$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
				$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
				$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
			}
		} 
		else
		{
			$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
			$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
			$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
		}
		
		#SKU
		seek($bin, 0x1C8041, 0);
		read($bin, my $SKU, 0xA);
		
		seek($bin, 0x1C8045, 0);
		read($bin, my $shortsku, 0x2);
		
		if ($specific_version eq $FW_Version && $specific_sku eq $shortsku) {
			push (@files_combo, $file);
			print "\n", (colored ['bold green'], "$file has $FW_Version and $SKU");
		}
	}
	
	@array = @files_combo;

} elsif ($specific_option eq "4") {
	
	@array = @files;
	
} else {goto EOF;}

print $clear_screen;
print $BwE;

my $dumpcount2 = scalar @array;

if ($dumpcount2 eq "0") {
	print "Nothing to compare! Try a different filter!";
	goto EOF;
}

print "You will be comparing $dumpcount2 dumps!\n\n";

print "1. Compare Offsets (Hex)\n";
print "2. Compare Offsets (ASCII)\n";
print "3. Compare Offsets MD5\n";
print "4. Compare Offsets Entropy\n";
print "5. Double Offset Comparison\n";
print "6. Dynamic MD5 Calculation\n";
print "7. Compare File Entropy & Byte Count\n";
print "8. Compare File MD5\n";

print "\nChoose Option: "; 
my $option = <STDIN>; chomp $option; 

print $clear_screen;
print $BwE;

#******************************************************************************************
#******************************************************************************************

if ($option eq "1") {

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

print "\nChoose Output Type:\n\n";
print "1. Output - Version - SKU - Filename\n";
print "2. Output - Filename\n";
print "3. Output \n\n";
print "Your Selection (1-3): ";

my $option1selection = <STDIN>; chomp $option1selection; 

$offset = hex($offset);
$length = hex($length);

print "\n"; 

foreach my $file (@array) { ### Calculating $file Results... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $result, $length);
$result = uc ascii_to_hex($result); 

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}

if ($option1selection eq "2") {
		print F "$result - $file\n";
	}
	elsif ($option1selection eq "3") {
		print F "$result\n";
	}
	else {
		print F "$result - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
}  

#******************************************************************************************
#******************************************************************************************

elsif ($option eq "2") {

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

print "\nChoose Output Type:\n\n";
print "1. Output - Version - SKU - Filename\n";
print "2. Output - Filename\n";
print "3. Output \n\n";
print "Your Selection (1-3): ";

my $option1selection = <STDIN>; chomp $option1selection; 

$offset = hex($offset);
$length = hex($length);

print "\n"; 

foreach my $file (@array) { ### Calculating $file Results... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $result, $length);
#$result = uc ascii_to_hex($result); 

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}

if ($option1selection eq "2") {
		print F "$result - $file\n";
	}
	elsif ($option1selection eq "3") {
		print F "$result\n";
	}
	else {
		print F "$result - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
}  

#******************************************************************************************
#******************************************************************************************

elsif ($option eq "3") { 

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

print "\nChoose Output Type:\n\n";
print "1. Output MD5 - Version - SKU - Filename\n";
print "2. Output MD5 - Filename\n";
print "3. Output MD5\n\n";
print "Your Selection (1-3): ";

my $option2selection = <STDIN>; chomp $option2selection; 

$offset = hex($offset);
$length = hex($length);

print "\n"; 

foreach my $file (@array) { ### Calculating $file MD5's... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $result, $length);

my $result_MD5 = uc md5_hex($result);

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}

if ($option2selection eq "2") {
		print F "$result_MD5 - $file\n";
	}
	elsif ($option2selection eq "3") {
		print F "$result_MD5\n";
	}
	else {
		print F "$result_MD5 - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
} 

#******************************************************************************************
#******************************************************************************************

elsif ($option eq "4") {

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

print "\nChoose Output Type:\n\n";
print "1. Entropy - Version - SKU - Filename\n";
print "2. Entropy - Filename\n\n";
print "Your Selection (1-2): ";

my $option3selection = <STDIN>; chomp $option3selection; 

$offset = hex($offset);
$length = hex($length);

print "\n"; 

foreach my $file (@array) { ### Calculating $file Entropy...    
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0); 
read($bin, my $range, $length);

my %Count; my $total = 0; my $entropy = 0; 
foreach my $char (split(//, $range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $entropy += $p * log($p);}
my $result = sprintf("%.2f", -$entropy / log 2);

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}
 
if ($option3selection eq "2") {
		print F "$result - $file\n";
	}
	else {
		print F "$result - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
} 

#******************************************************************************************
#******************************************************************************************

elsif ($option eq "5") {

print "Enter Offset 1: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length 1: "; 
my $length = <STDIN>; chomp $length; 
print "\nEnter Offset 2: "; 
my $offset2 = <STDIN>; chomp $offset2; 
print "Enter Length 2: "; 
my $length2 = <STDIN>; chomp $length2; 

print "\nChoose Output Type:\n\n";
print "1. Output 1 - Output 2 - Version - SKU - Filename\n";
print "2. Output 1 - Output 2 - Filename\n";
print "3. Output 1 - Output 2\n\n";
print "Your Selection (1-3): ";

my $option4selection = <STDIN>; chomp $option4selection; 

$offset = hex($offset);
$length = hex($length);
$offset2 = hex($offset2);
$length2 = hex($length2);

print "\n"; 

foreach my $file (@array) { ### Calculating $file Results... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $result, $length);
$result = uc ascii_to_hex($result); 

seek($bin, $offset2, 0);
read($bin, my $result2, $length2);
$result2 = uc ascii_to_hex($result2); 

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}

if ($option4selection eq "2") {
		print F "$result - $result2 - $file\n";
	}
	elsif ($option4selection eq "3") {
		print F "$result - $result2\n";
	}
	else {
		print F "$result - $result2 - $SKU - $FW_Version - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
}  

#******************************************************************************************
#******************************************************************************************

elsif ($option eq "6") {

print "Enter File Size Location Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "\nEnter Offset Length: "; 
my $length = <STDIN>; chomp $length; 
print "\nEnter MD5 Area Starting Offset: "; 
my $offset2 = <STDIN>; chomp $offset2; 

print "\nChoose Output Type:\n\n";
print "1. Length (Size) - MD5 - Version - SKU - Filename\n";
print "2. Length (Size) - MD5\n";
print "3. MD5\n\n";
print "Your Selection (1-3): ";

my $option5selection = <STDIN>; chomp $option5selection; 

$offset = hex($offset);
$length = hex($length);
$offset2 = hex($offset2);

print "\n"; 

foreach my $file (@array) { ### Calculating $file Results... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0); 
read($bin, my $DynSize, $length); 
$DynSize = uc ascii_to_hex($DynSize);
$DynSize = unpack "H*", reverse pack "H*", $DynSize;
$DynSize = hex($DynSize); $DynSize = uc sprintf("%x", $DynSize);

seek($bin, $offset2, 0); 
read($bin, my $DynMD5, hex($DynSize));
$DynMD5 = uc md5_hex($DynMD5);

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}

if ($option5selection eq "2") {
		print F "$DynSize - $DynMD5\n";
	}
	elsif ($option5selection eq "3") {
		print F "$DynMD5\n";
	}
	else {
		print F "$DynSize - $DynMD5 - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
}  


#******************************************************************************************
#******************************************************************************************

elsif ($option eq "7") {

print "\nChoose Output Type:\n\n";
print "1. Entropy - FF Count - 00 Count - Version - SKU - Filename\n";
print "2. Entropy - FF Count - 00 Count - Filename\n";
print "3. Entropy - FF Count - 00 Count\n\n";
print "Your Selection (1-3): ";

my $option7selection = <STDIN>; chomp $option7selection; 

print "\n"; 

foreach my $file (@array) { ### Calculating $file Entropy...    
open(my $bin, "<", $file) or die $!; binmode $bin;

my $len = -s $file;
my ($entropy, %t) = 0;

open (my $file_en, '<', $file) || die "Cant open $file\n", goto FAILURE;
binmode $file_en;

while( read( $file_en, my $buffer, 1024) ) {  ### Calculating $file Entropy...    
	$t{$_}++ 
		foreach split '', $buffer; 
	$buffer = '';
}

foreach (values %t) { 
	my $p = $_/$len;
	$entropy -= $p * log $p ;
}       
my $result = sprintf("%.2f", $entropy / log 2);
my $result_percent = sprintf("%.2f", $result / 8 * 100);

use constant BLOCK_SIZE => 4*1024*1024;

open(my $fh, '<:raw', $file)
   or die("Can't open \"$file\": $!\n"), goto FAILURE;

my @counts = (0) x 256;
while (1) {  ### Counting $file Bytes...
   my $rv = sysread($fh, my $buf, BLOCK_SIZE);
   die($!) if !defined($rv);
   last if !$rv;

   ++$counts[$_] for unpack 'C*', $buf;
}

my $FFCountPercent = sprintf("%.2f",($counts[0xFF] / 33554432 * 100));
my $NullCountPercent = sprintf("%.2f",($counts[0x00] / 33554432 * 100));

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}
 
if ($option7selection eq "2") {
		print F "$result ($result_percent%) - $counts[0xFF] ($FFCountPercent%) - $counts[0x00] ($NullCountPercent%) - $file\n";
	}
	elsif ($option7selection eq "3") {
		print F "$result ($result_percent%) - $counts[0xFF] ($FFCountPercent%) - $counts[0x00] ($NullCountPercent%)\n";
	}
	else {
		print F "$result ($result_percent%) - $counts[0xFF] ($FFCountPercent%) - $counts[0x00] ($NullCountPercent%) - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!\n";
my $opensysfile = system("output.txt");
goto EOF;
} 

#******************************************************************************************
#******************************************************************************************

elsif ($option eq "8") {

print "\nChoose Output Type:\n\n";
print "1. File MD5 - Version - SKU - Filename\n";
print "2. File MD5 - Filename\n";
print "3. File MD5\n\n";
print "Your Selection (1-3): ";

my $option6selection = <STDIN>; chomp $option6selection; 

print "\n";
foreach my $file (@array) { ### Calculating $file MD5...    

open(my $bin, "<", $file) or die $!; binmode $bin;

my $md5sum = uc Digest::MD5->new->addfile($bin)->hexdigest; 
 
seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

my $FW_Version;

seek($bin, 0x1C906A, 0); 
read($bin, my $FW_Version2, 0x2);
$FW_Version2 = uc ascii_to_hex($FW_Version2); 
if ($FW_Version2 eq "FFFF")
{
	seek($bin, 0x1CA606, 0); 
	read($bin, my $FW_Version1, 0x2);
	$FW_Version1 = uc ascii_to_hex($FW_Version1); 
	if ($FW_Version1 eq "FFFF")
	{
		$FW_Version = "N/A";
	} 
	else
	{
		$FW_Version1 = unpack "H*", reverse pack "H*", $FW_Version1;
		$FW_Version1 = hex($FW_Version1); $FW_Version1 = uc sprintf("%x", $FW_Version1);
		$FW_Version = substr($FW_Version1, 0, 1) . "." . substr($FW_Version1, 1);
	}
} 
else
{
	$FW_Version2 = unpack "H*", reverse pack "H*", $FW_Version2;
	$FW_Version2 = hex($FW_Version2); $FW_Version2 = uc sprintf("%x", $FW_Version2);
	$FW_Version = substr($FW_Version2, 0, 1) . "." . substr($FW_Version2, 1);
}

if ($option6selection eq "2") {
		print F "$md5sum - $file\n";
	}
	elsif ($option6selection eq "3") {
		print F "$md5sum\n";
	}
	else {
		print F "$md5sum - $FW_Version - $SKU - $file\n";
	}

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
} 

#******************************************************************************************
#******************************************************************************************

else {goto EOF;}

EOF:

print "\n\nGo Again? (y/n): ";

my $again = <STDIN>; chomp $again; 

if ($again ne "y") {
goto END;
} else {
print $clear_screen;
goto START;
}

END:

print "\n\nPress Enter to Exit... ";
while (<>) {
chomp;
last unless length;
}
