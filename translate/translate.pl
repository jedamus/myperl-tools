#!/usr/bin/perl

# created Mittwoch, 05. Dezember 2012 06:34 (C) 2012 by Leander Jedamus
# modifiziert Mittwoch, 01. Mai 2019 01:48 von Leander Jedamus
# modifiziert Montag, 16. Oktober 2017 18:20 von Leander Jedamus
# modifiziert Montag, 17. August 2015 11:21 von Leander Jedamus
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
use File::Temp qw/ tempfile tempdir /;
use Getopt::Long;

my $author = "Leander Jedamus";
my $email = "ljedamus\@testmail.com";
my $year = `date +'%Y'`;
chomp $year;
my $date = `date +'%Y-%m-%d %H:%M%z'`;
chomp $date;
my $transdir = "translate";
my $charset = "UTF-8";
#my $charset = "ISO-8859-1";
my @languages = ("de","en");
my @tmpfiles;

my @files;
my $project = "mycopy.pl";
my $version = "1.0";

&GetOptions('file=s' => \@files,'project=s' => \$project,'version=s' => \$version);

my $tmpdir = tempdir( CLEANUP => 1 );

foreach my $file (@files) {

  my ($fh, $tmpfile) = tempfile( DIR => $tmpdir );
  (my $suffix = $file) =~ s/.*(\..*)/$1/;
  $tmpfile .= $suffix;
  push(@tmpfiles,$tmpfile);
  
  open(SCRIPT,$file);
  open(TMPSCRIPT,">$tmpfile");
  while(<SCRIPT>)
  {
    s/_[(]/gettext(/g;
    print TMPSCRIPT;
  };# while <SCRIPT>
  close(TMPSCRIPT);
  close(SCRIPT);
};# foreach

my $filelist;
foreach my $tmpfile (@tmpfiles) { $filelist .= $tmpfile . " " };

#system("rm -rf $transdir");
system("mkdir -p $transdir");

if(-f "$transdir/$project.po")
{
  system("mv $transdir/$project.po $transdir/$project.po.old");
};
system("xgettext --from-code=utf-8 $filelist -d $project -p $transdir");
chdir $transdir;
open(IN,"$project.po");
open(OUT,">$project.po.tmp");
while(<IN>)
{
  s/SOME DESCRIPTIVE TITLE/$project/g;
  s/YEAR THE PACKAGE'S COPYRIGHT HOLDER/$year $author/g;
  s/FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR/$email, $year/g;
  s/FULL NAME <EMAIL\@ADDRESS>/$author <$email>/g;
  s/LANGUAGE <LL\@li.org>/$author <$email>/g;
  s/CHARSET/$charset/g;
  s/VERSION/$version/g;
  s/PACKAGE/$project/g;
  s/YEAR-MO-DA HO:MI+ZONE/$date/g;

  my $i = 0;
  foreach my $tmpfile (@tmpfiles) {
    my $file = $files[$i];
    s/$tmpfile/$file/g;
    $i++;
  };# foreach
  print OUT;
};# while
close(OUT);
close(IN);
system("mv $project.po.tmp $project.po");

foreach my $language (@languages)
{
  my $po = "${project}_$language.po";
  my $po_old = "$po.old";
  my $old_po = 0;
  if(-f $po)
  {
    system("mv $po $po_old");
    $old_po = 1;
  };
  system("msginit --no-translator -l $language -i $project.po");
  system("mv $language.po $po");
  if($old_po == 1)
  {
    system("msgmerge $po_old $po > $po.new");
    system("mv $po.new $po");
  };

  system("mkdir -p $language/LC_MESSAGES");
  system("msgfmt -o $language/LC_MESSAGES/$project.mo $po");
};# foreach $language

# vim:ai sw=2

