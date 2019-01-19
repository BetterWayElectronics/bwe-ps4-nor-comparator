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
$CONSOLE->Title('BwE PS4 NOR Comparator');

my $BwE = (colored ['bold green'], qq{
===========================================================
|            __________          __________               |
|            \\______   \\ __  _  _\\_   ____/               |
|             |    |  _//  \\/ \\/  /|  __)_                |
|             |    |   \\\\        //       \\               |
|             |______  / \\__/\\__//______  /               |
|                    \\/PS4 NOR Comparator\\/v1.1           |
|        		                                  |
===========================================================\n\n});
print $BwE;

my @files=(); 

while (<*.bin>) 
{
    push (@files, $_) if (-s eq "33554432");
}

if ( @files <= 1 ) {
	print "There is nothing to compare...\n"; 
	goto EOF;
} 

open(F,'>', "output.txt") || die $!;

print "1. Compare Offsets (Result - SKU - Filename)\n";
print "2. Compare Offsets MD5 (MD5 Hash - Filename)\n";
print "3. Compare Offsets Entropy (Entropy - Filename)\n";
print "4. Compare File MD5 (MD5 Hash - Filename)\n";
print "5. Double Comparison (Result 1 - Result 2 - Filename)\n";

print "\nChoose Option: "; 
my $option = <STDIN>; chomp $option; 

my $clear_screen = cls(); 
print $clear_screen;
print $BwE;

if ($option eq "1") {

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

$offset = hex($offset);
$length = hex($length);

foreach my $file (@files) { ### Calculating Results... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $yeah, $length);
$yeah = uc ascii_to_hex($yeah); 

seek($bin, 0x1C8041, 0);
read($bin, my $SKU, 0xA);

print F "$yeah - $SKU - $file\n";

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
}  

elsif ($option eq "2") { 

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

$offset = hex($offset);
$length = hex($length);

foreach my $file (@files) { ### Calculating MD5's... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $yeah, $length);
$yeah = uc ascii_to_hex($yeah); 

my $yeah_MD5 = uc md5_hex($yeah);

print F "$yeah_MD5 - $file\n";

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
} 

elsif ($option eq "3") {

print "Enter Offset: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length: "; 
my $length = <STDIN>; chomp $length; 

$offset = hex($offset);
$length = hex($length);

foreach my $file (@files) { ### Calculating Entropy...    
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0); 
read($bin, my $range, $length);

my %Count; my $total = 0; my $entropy = 0; 
foreach my $char (split(//, $range)) {$Count{$char}++; $total++;}
foreach my $char (keys %Count) {my $p = $Count{$char}/$total; $entropy += $p * log($p);}
my $result = sprintf("%.2f", -$entropy / log 2);
 
print F "$result - $file\n";

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
} 

elsif ($option eq "4") {

foreach my $file (@files) { ### Calculating MD5's...    
open(my $bin, "<", $file) or die $!; binmode $bin;

my $md5sum = uc Digest::MD5->new->addfile($bin)->hexdigest; 
 
print F "$md5sum - $file\n";

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
} 

elsif ($option eq "5") {

print "Enter Offset 1: "; 
my $offset = <STDIN>; chomp $offset; 
print "Enter Length 1: "; 
my $length = <STDIN>; chomp $length; 
print "\nEnter Offset 2: "; 
my $offset2 = <STDIN>; chomp $offset; 
print "Enter Length 2: "; 
my $length2 = <STDIN>; chomp $length; 

$offset = hex($offset);
$length = hex($length);
$offset2 = hex($offset2);
$length2 = hex($length2);

foreach my $file (@files) { ### Calculating Results... 
open(my $bin, "<", $file) or die $!; binmode $bin;

seek($bin, $offset, 0);
read($bin, my $yeah, $length);
$yeah = uc ascii_to_hex($yeah); 

seek($bin, $offset2, 0);
read($bin, my $yeah2, $length2);
$yeah2 = uc ascii_to_hex($yeah2); 

print F "$yeah - $yeah2 - $file\n";

}
close(F); 
print $clear_screen;
print $BwE;
print "Mission Complete!";
my $opensysfile = system("output.txt");
goto EOF;
}  

else {goto EOF;}

EOF:

print "\n\nPress Enter to Exit... ";
while (<>) {
chomp;
last unless length;
}
