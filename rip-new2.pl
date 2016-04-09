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
# ver 2.0 - Stream parsing direct to files without use memory by Lukas Verner (C) autumn 2014 

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

# variables with setup values
my ($counter, $nomatch_sum, $result) = (0, 0, 0);
# variables
my ($statut, $pattern, $counter_test, $counter_line, $j);
# hashes
my (%result_look, %pattern_statut, %pattern_index, %pattern_sum);
# temporary routine
sub RoomCount() {$counter}
# array of results
my @result_look = ([]) x RoomCount;
my (@patterns, @NOMATCH, @CIL);

print "--------------- Debug report ---------------\n";
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

# ver 2.0
# Otevreni cilovych soubrou pro vsechny patterny
foreach $j (@patterns) {
  #print "For pattern=$j\t are found $pattern_sum{$j} lines and results are written to file=$pattern_index{$j}.txt.\n";
  open($CIL[$pattern_index{$j}], ">$pattern_index{$j}.txt") or die "Nelze otevrit soubor: $!";
}
open(NOMATCH, ">nomatch.txt") or die "Nelze otevøít soubor: $!";

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
    print NOMATCH "$line"; # ver 2.0
    $nomatch_sum++;}
  else {
    # byla nalezena shoda.
    print { $CIL[$pattern_index{$k}] } "$line"; # ver 2.0
    $pattern_sum{$k}++;
    $result=0;       
  } # if
} # end-while infile
close(INFILE);
# ver 2.0
# Zavreni cilovych soubrou pro vsechny patterny
foreach $j (@patterns) {
  close($CIL[$pattern_index{$j}]);
}

# Vypis poctu vysledku
print "--------------- Result report ---------------\n";
foreach $j (@patterns) {
   print "For pattern=$j\t are found $pattern_sum{$j} lines and results are written to file=$pattern_index{$j}.txt.\n";
}
print "I can not match $nomatch_sum lines and this lines are written to file=nomatch.txt.\n";
__END__
