#!/usr/bin/perl

#RIP = Regex Information Parser 

#First idea created by BLESK bleskmm@gmail.com
#Modified by TF tifay78@gmail.com
#New program version by Simecek 11.2.2007

# ver 1.0 - functional program
# ver 1.1 - add test function for config.in, small changes

# parametry:
# 	1 - soubor se seznamem hlasek - co radek to hlaska - (config.in)
#	2 - soubor, ktery chceme kontrolovat

# info pre config.in
#	znak minus "-" znamena ze sa budu prehladavat len riadky ktore obsahuju spominany retazec
#		       doporucuje sa ho pouzivat hned v prvych riadkox, aby sme si tym odstranili
#		       hlasky ktore nas nezaujimaju a budeme ich odstranovat cez syslog-ng
#	znak mocniny "^" znamena ze nasledujuci retacez je v REGEX tvare
#	Ak retezec zacina "-" uz nemoze byt nasledovany "^"

if ($ARGV[0] =~ /^-/) {
	$ARG1 = @ARGV[0];
	@ARGS = @ARGV[1..$#ARGV];
} else {
	$ARG1 = "x";
	@ARGS = @ARGV;
}

# otevreme soubory
open(CONFFILE,  "@ARGS[0]") or die "Nejde otevrit konfiguracni soubor @ARGS[0]: $!";
open(INFILE, "@ARGS[1]") or die "Nejde otevrit vstupni soubor @ARGS[1]: $!";

# nacteme PATTERNs do pameti programu. Vyhodou je vyssi rychlost !
print "--------------- Debug report ---------------\n";
$counter = 0;
while (<CONFFILE>) {
  chomp $_;
  print "DEBUG: $_\n";
  # vyhledavaci statut - REGEX PATTERN
  if ($_=~/^\^/) {$statut=1;}
  else {
  # vyhledavaci statut - OBSAHUJE UVEDENY RETEZEC
    if ($_=~/^-/) {$statut=2;}
  # vyhledavaci statut - NEOBSAHUJE UVEDENY RETEZEC
    else {$statut=3;}
    }
  # uprava promenne PATTERN pro finalni ulozeni do pameti.
  unless ($statut == 3) {$pattern = substr $_, 1;} else {$pattern=$_}

  # ver 1.1
  # kontrola, zda neni chyba v config.in, napr. vicekrat stejny pattern
  $counter_test=1;
  $counter_line=$counter+1;
  foreach $j (@patterns)  {
    #print "DEBUG2: $j - $pattern\n";
    if ($j eq $pattern) {print "WARNING: Pattern $j on line $counter_line is duplicate with line $counter_test !!!!\n";}
    $counter_test++;
  }

  # ulozeni hledanych vzoru do pameti.
  push( @patterns, $pattern );
  $pattern_statut{$pattern}=$statut;
  $pattern_index{$pattern}=++$counter;
  $pattern_sum{$pattern}=0;
}
close (CONFFILE);

print "--------------- Total lines= $counter ---------------\n";
print "--------------- Pattern report ---------------\n";
foreach $j (@patterns) {
  # tisk co se bude hledat a prislusnych hodnot pomocnych promennych.
  print "pattern=$j\t\t\tstatut=$pattern_statut{$j}\tindex=$pattern_index{$j}\n";
}

sub RoomCount() {$counter}
# hash
my %result_look;
# pole vysledku
my @result_look = ([]) x RoomCount;

$nomatch_sum=0;
$result=0;
while (<INFILE>) {
  #print "line $_\n";
  # pro kazdy radek prohledej vsechny PATTERNY
  foreach $j (@patterns) {
    #print "*pattern=$j\n";
    # vyhledavaci statut - REGEX PATTERN
    if ($pattern_statut{$j} eq 1 ) {
      if (/$j/) {$result=1;push @{$result_look{$pattern_index{$j}}},$_;$pattern_sum{$j}++;last;}
    }
    # vyhledavaci statut - OBSAHUJE UVEDENY RETEZEC
    if ($pattern_statut{$j} eq 2 ) {
      if (m/$j/) {$result=1;push @{$result_look{$pattern_index{$j}}},$_;$pattern_sum{$j}++;last;}
    }
    # vyhledavaci statut - NEOBSAHUJE UVEDENY RETEZEC
    if ($pattern_statut{$j} eq 3 ) {
      if (!/$j/) {$result=1;push @{$result_look{$pattern_index{$j}}},$_;$pattern_sum{$j}++;last;}
    }
  } # end foreach
  if ($result eq 0) {
    # nebyla zadna shoda.
    push(@NOMATCH,$_);$nomatch_sum++;}
  else {$result=0;}
} # end while infile

# ted ulozime vysledky do souboru na disk
print "--------------- Result report ---------------\n";
foreach $j (@patterns) {
  print "For pattern=$j\t are found $pattern_sum{$j} lines and results are written to file=$pattern_index{$j}.txt.\n";
  open(CIL, ">$pattern_index{$j}.txt") or die "Nelze otevøít soubor: $!";
  print CIL @{$result_look{$pattern_index{$j}}};
  close(CIL);
}
# ted ulozime vysledky do souboru na disk
print "I can not match $nomatch_sum lines and this lines are written to file=nomatch.txt.\n";
open(CIL, ">nomatch.txt") or die "Nelze otevøít soubor: $!";
print CIL @NOMATCH;
close(CIL);