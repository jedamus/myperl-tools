#!/usr/bin/perl

# created Mittwoch, 05. Dezember 2012 06:27 (C) 2012 by Leander Jedamus
# modifiziert Montag, 05. März 2018 16:16 von Leander Jedamus
# modifiziert Freitag, 13. Oktober 2017 15:48 von Leander Jedamus
# modifiziert Mittwoch, 11. Oktober 2017 18:39 von Leander Jedamus
# modifiziert Montag, 10. Oktober 2016 13:46 von Leander Jedamus
# modifiziert Samstag, 04. Juli 2015 14:24 von Leander Jedamus
# modifiziert Dienstag, 23. Juni 2015 17:47 von Leander Jedamus
# modifiziert Mittwoch, 25. März 2015 10:04 von Leander Jedamus
# modifiziert Montag, 23. März 2015 18:12 von Leander Jedamus
# modifiziert Montag, 23. März 2015 14:01 von Leander Jedamus
# modifiziert Montag, 18. März 2013 18:55 von Leander Jedamus
# modifiziert Samstag, 16. Februar 2013 17:58 von Leander Jedamus
# modifiziert Samstag, 16. Februar 2013 16:37 von Leander Jedamus
# modified Mittwoch, 05. Dezember 2012 10:04 by Leander Jedamus
# modified Mittwoch, 05. Dezember 2012 10:03 by Leander Jedamus
# modified Mittwoch, 05. Dezember 2012 06:30 by Leander Jedamus

# http://linux.math.tifr.res.in/manuals/html/a2ps.html

use strict;
use warnings;
use Locale::gettext qw( gettext bindtextdomain textdomain bind_textdomain_codeset );
use POSIX;
use FindBin '$Bin';                              
use File::Spec;
use vars qw($opt_P);
use Getopt::Long;

my $OS = "unknown";
if ("$^O" eq "linux") { $OS="Linux" };
if ("$^O" eq "darwin") { $OS="MacOS" };

my $domain = "a2ps.pl";
bindtextdomain($domain,File::Spec->catfile($Bin,"translate"));
textdomain($domain);
bind_textdomain_codeset($domain,"ISO-8859-1");
sub _ ($) { &gettext; }

sub convert {
  my ($str) = @_;

  my $IN  = "/tmp/$domain.convert.$$.in";
  my $OUT = "/tmp/$domain.convert.$$.out";

  open(IN,">$IN");
  print IN $str;
  close(IN);
  system "iconv -f utf8 -t latin1 <$IN >$OUT";
  unlink $IN;
  open(OUT,$OUT);
  $str = <OUT>;
  chomp($str);
  close(OUT);
  unlink $OUT;
  return $str;
};# sub convert

sub convert2 {
  my ($str) = @_;

  my $IN  = "/tmp/$domain.convert.$$.in";
  my $OUT = "/tmp/$domain.convert.$$.out";

  open(IN,">$IN");
  print IN $str;
  close(IN);
  system "iconv -f iso-8859-1 -t latin1 <$IN >$OUT";
  unlink $IN;
  open(OUT,$OUT);
  $str = <OUT>;
  chomp($str);
  close(OUT);
  unlink $OUT;
  return $str;
};# sub convert

my $tmpfile = "/tmp/$domain.$$.out";
(my $username) = split(',',(getpwuid($<))[6]);

$opt_P = "laserjet";

&GetOptions('P:s');

foreach my $file (@ARGV)
{
  #system "iconv","-f","utf8","-t","latin1","-o",$tmpfile,$file;
  system "iconv -f utf8 -t latin1 <$file >$tmpfile";

  (my $basename = $file) =~ s/.*\/(.*)$/$1/;

  my $filetmp = "/tmp/$basename.ps";
  my $filetmppdf = "/tmp/$basename.pdf";

  $basename = convert($basename);
  $file = convert($file);
  my $filetime = convert2(strftime("%a, %d.%m.%Y %H:%M",localtime((stat($file))[9])));
  my $time = convert2(strftime("%A, %d. %B %Y",localtime()));
  my $header = convert(sprintf(_("printed by %s"),$username));
  
  system "a2ps",
	 "--margin=0",
         "--line-numbers=1",                # Zeilennummern einschalten
         "-l","83",                         # Anzahl Zeichen in einer Zeile
	 "-T","4",                          # Tabulator enspricht 4 Leerzeichen
	 "-M","A4",                         # Medium A4
	 #"--sides=2",
         "--delegate=0",                    # delegiere Files nicht
	 #"-P",$opt_P,                       # Printer
	 "--left-title=$filetime",          # Mi, 28.11.2012 12:09
	 "--center-title=$basename",        # Dateiname ohne Pfad
	 "--right-title="._('page $p./$p>'),
	 "--left-footer=$time",             # Dienstag, 27. November 2012
	 "--footer=$file",                  # Dateiname mit Pfad
	 "--header=$header",                # Benutzername
	 "-o",$filetmp,                     # Ausgabe in Datei
	 $tmpfile;

  if ( $OS eq "Linux" )
  {
    #print "OS = $OS\n";
    system "ps2pdf","-sPAPERSIZE=a4",$filetmp,$filetmppdf;
    system "lpr","-P",$opt_P,$filetmppdf;
    #system "evince",$filetmppdf;
    #system "evince",$filetmp;
    unlink $filetmppdf;
  }
  elsif ( $OS eq "MacOS" )
  {
    #print "OS = $OS\n";
    #print $filetmp,"\n";
    system "lpr","-l","-P",$opt_P,$filetmp;
  }
  else
  {
    print "unkown OS-Type!\n";
  };
  unlink $filetmp;
};# foreach

unlink $tmpfile;

# vim: ai sw=2

