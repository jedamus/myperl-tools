#!/usr/bin/perl

# created Mittwoch, 05. Dezember 2012 06:34 (C) 2012 by Leander Jedamus
# modifiziert Mittwoch, 22. Juli 2015 17:23 von Leander Jedamus
# modifiziert Dienstag, 23. Juni 2015 16:04 von Leander Jedamus
# modifiziert Montag, 25. Februar 2013 11:11 von Leander Jedamus
# modified Montag, 04. Februar 2013 13:14 by Leander Jedamus
# modified Montag, 04. Februar 2013 13:11 by Leander Jedamus
# modified Montag, 04. Februar 2013 13:08 by Leander Jedamus
# modified Montag, 04. Februar 2013 13:07 by Leander Jedamus
# modified Mittwoch, 05. Dezember 2012 06:34 by Leander Jedamus

use strict;
use warnings;
use vars qw($opt_file $opt_project $opt_version);
use Getopt::Long;

my $author = "Leander Jedamus";
my $email = "ljedamus\@gmail.com";
my $year = `date +'%Y'`;
chomp $year;
my $transdir = "translate";
my $charset = "UTF-8";
#my $charset = "ISO-8859-1";
my @languages = ("de","en");

$opt_file = "mycopy.pl";
$opt_project = "mycopy.pl";
$opt_version = "1.0";

&GetOptions('file=s','project=s','version=s');

(my $endung = $opt_file) =~ s/.*(\..*)/$1/;

my $tmpscript = "/tmp/gettext$endung";

open(SCRIPT,$opt_file);
open(TMPSCRIPT,">$tmpscript");
while(<SCRIPT>)
{
  s/_[(]/gettext(/g;
  print TMPSCRIPT;
};# while <SCRIPT>
close(TMPSCRIPT);
close(SCRIPT);

#system("rm -rf $transdir");
system("mkdir -p $transdir");

if(-f "$transdir/$opt_project.po")
{
  system("mv $transdir/$opt_project.po $transdir/$opt_project.po.old");
};
system("xgettext --from-code=utf-8 $tmpscript -d $opt_project -p $transdir");
chdir $transdir;
open(IN,"$opt_project.po");
open(OUT,">$opt_project.po.tmp");
while(<IN>)
{
  s/SOME DESCRIPTIVE TITLE/$opt_file/g;
  s/YEAR THE PACKAGE'S COPYRIGHT HOLDER/$year $author/g;
  s/FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR/$email, $year/g;
  s/FULL NAME <EMAIL\@ADDRESS>/$author <$email>/g;
  s/LANGUAGE <LL\@li.org>/$author <$email>/g;
  s/CHARSET/$charset/g;
  s/VERSION/$opt_version/g;
  s/PACKAGE/$opt_file/g;
  s/$tmpscript/$opt_file/g;
  print OUT;
};# while
close(OUT);
close(IN);
system("mv $opt_project.po.tmp $opt_project.po");

foreach my $language (@languages)
{
  my $po = "${opt_project}_$language.po";
  my $po_old = "$po.old";
  my $old_po = 0;
  if(-f $po)
  {
    system("mv $po $po_old");
    $old_po = 1;
  };
  system("msginit --no-translator -l $language -i $opt_project.po");
  system("mv $language.po $po");
  if($old_po == 1)
  {
    system("msgmerge $po_old $po > $po.new");
    system("mv $po.new $po");
  };

  system("mkdir -p $language/LC_MESSAGES");
  system("msgfmt -o $language/LC_MESSAGES/$opt_project.mo $po");
};# foreach $language

unlink $tmpscript
