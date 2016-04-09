#!/usr/bin/perl
use strict;
use warnings;
use feature qw(switch say);
use diagnostics;

#RIP = Regex Information Parser 

#First idea created by BLESK bleskmm@gmail.com
#Modified by TF tifay78@gmail.com
#New program version by Simecek 11.2.2007

# ver 1.0 - functional program
# ver 1.1 - add test function for config.in, small changes
# ver 1.2 - change matching functionalities, change declaration of variables, improvements to Perl 5.16.X.

# parametry:
# 	1 - soubor se seznamem hlasek - co radek to hlaska - (config.in)
#	2 - soubor, ktery chceme kontrolovat

# info pre config.in
#	znak minus "-" znamena ze sa budu prehladavat len riadky ktore obsahuju spominany retazec
#		       doporucuje sa ho pouzivat hned v prvych riadkox, aby sme si tym odstranili
#		       hlasky ktore nas nezaujimaju a budeme ich odstranovat cez syslog-ng => status =2
#	znak mocniny "^" znamena ze nasledujuci retacez je v REGEX tvare => status =1
#	Ak retezec zacina "-" uz nemoze byt nasledovany "^"

my @ARGS = ($ARGV[0] =~ /^-/)?@ARGV[1..$#ARGV]:@ARGV;

# otevreme soubory
open(CONFFILE,  "$ARGS[0]") or die "Nejde otevrit konfiguracni soubor $ARGS[0]: $!";
open(INFILE, "$ARGS[1]") or die "Nejde otevrit vstupni soubor $ARGS[1]: $!";


print "--------------- Debug report ---------------\n";

my ($counter, $nomatch_sum, $result) = (0, 0, 0);

# hashes
my (%result_look, %pattern_statut, %pattern_index, %pattern_sum);
# variables
my ($statut, $pattern, $counter_test, $counter_line, $j);

# temporary routine
sub RoomCount() {$counter}

# array of results
my @result_look = ([]) x RoomCount;
my (@patterns, @NOMATCH);

# nacteme PATTERNs do pameti programu. Vyhodou je vyssi rychlost hledani !
while (my $conf_line=<CONFFILE>) {
  chomp $conf_line;
  print "DEBUG: $conf_line\n";

  # ver 1.2
  given ($conf_line) {
   when (/^\^/) {$statut=1;}  # vyhledavaci statut - REGEX PATTERN
   when (/^-/)  {$statut=2;}  # vyhledavaci statut - OBSAHUJE UVEDENY RETEZEC
   default {$statut=3;}       # vyhledavaci statut - NEOBSAHUJE UVEDENY RETEZEC
  } # given  

  # uprava promenne PATTERN pro finalni ulozeni do pameti.
  $pattern=($statut != 3) ? substr $conf_line,1 : $conf_line;

  # ver 1.1
  # kontrola, zda neni chyba v config.in, napr. vicekrat stejny pattern
  $counter_test=1;
  $counter_line=$counter+1;
  foreach $j (@patterns)  {
    #print "DEBUG2: $j - $pattern\n";
    if ($j eq $pattern) {print "WARNING: Pattern $j on line $counter_line is duplicate with line $counter_test !!!!\n";}
    $counter_test++;
  } # end-foreach

  # ulozeni hledanych vzoru do pameti.
  push( @patterns, $pattern );
  $pattern_statut{$pattern}=$statut;
  $pattern_index{$pattern}=++$counter;
  $pattern_sum{$pattern}=0;
} # end-while
close (CONFFILE);

print "--------------- Total lines= $counter ---------------\n";
print "--------------- Pattern report ---------------\n";
foreach $j (@patterns) {
  # tisk co se bude hledat a prislusnych hodnot pomocnych promennych.
  print "pattern=$j\t\t\tstatut=$pattern_statut{$j}\tindex=$pattern_index{$j}\n";
}

while (my $line=<INFILE>) {
my $k;
  #print "line $line\n";
  # pro kazdy radek prohledej vsechny PATTERNY
  foreach $j (@patterns) {
    #print "\nline=$line *pattern=$j\t$pattern_statut{$j}\t";
    # vyhledavaci statut - REGEX PATTERN
    # ver 1.2
    given ($pattern_statut{$j}) {
     when(3) {if ($line !~ $j) {$result=1;$k=$j;last;}} # vyhledavaci statut - NEOBSAHUJE UVEDENY RETEZEC
     default {if ($line =~ $j) {$result=1;$k=$j;last;}} # vyhledavaci statut - OBSAHUJE UVEDENY RETEZEC + REGEX
    } # given

  } # end-foreach
  #print "result=$result";
  if ($result eq 0) {
    # nebyla zadna shoda.
    push(@NOMATCH,$line);
    $nomatch_sum++;}
  else {
    # byla nalezena shoda.
    push @{$result_look{$pattern_index{$k}}},$line; 
    $pattern_sum{$k}++;
    $result=0;       
  } # if
} # end-while infile
close(INFILE);

# ted ulozime vysledky do souboru na disk jednim velkym vrzem
print "--------------- Result report ---------------\n";
foreach $j (@patterns) {
  print "For pattern=$j\t are found $pattern_sum{$j} lines and results are written to file=$pattern_index{$j}.txt.\n";
  open(CIL, ">$pattern_index{$j}.txt") or die "Nelze otevøít soubor: $!";
  if ($pattern_sum{$j} != 0) { print CIL @{$result_look{$pattern_index{$j}}; }
}; # end-foreach
close(CIL);
}
# ted ulozime vysledky do souboru na disk
print "I can not match $nomatch_sum lines and this lines are written to file=nomatch.txt.\n";
open(CIL, ">nomatch.txt") or die "Nelze otevøít soubor: $!";
if ($nomatch_sum != 0) { print CIL @NOMATCH; }
close(CIL);
__END__
