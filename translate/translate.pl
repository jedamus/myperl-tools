#!/usr/bin/perl

# created Mittwoch, 05. Dezember 2012 06:34 (C) 2012 by Leander Jedamus
# modifiziert Dienstag, 26. November 2019 16:01 von Leander Jedamus
# modifiziert Montag, 25. November 2019 11:58 von Leander Jedamus
# modifiziert Samstag, 11. Mai 2019 04:45 von Leander Jedamus
# modifiziert Mittwoch, 01. Mai 2019 02:33 von Leander Jedamus
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
my $email = "ljedamus\@web.de";
my $year = `date +'%Y'`;
chomp $year;
my $date = `date +'%Y-%m-%d %H:%M%z'`;
chomp $date;
my $charset = "UTF-8";
#my $charset = "ISO-8859-1";
my @tmpfiles;


sub get_it {
  my $file = shift;
  my $lines = "";
  my @result = ();
  open(FILE,$file);
  while(<FILE>)
  {
    if(/^#/) { next };
    $lines .= $_;
  };# while <FILE>
  close(FILE);
  $_ = $lines;
  while($_) {
    /\W*([\w\/\.]+)\W+/;
    # print $1,"\n";
    push(@result,$1);
    $_ = $';
  };
  return(@result);
};# sub get_it

my @files;
my $project = "mycopy.pl";
my $version = "1.0";
my $transdir = "translate";
my $n = 0;
my @languages = ("de","en");

&GetOptions('file=s' => \@files,'project=s' => \$project,'version=s' => \$version, 'dir=s' => \$transdir, 'n' => \$n);

my $tmpdir = tempdir( CLEANUP => 1 );

if($n) {
  my $file = $transdir . "/POTFILES.in";
  if(-f $file) {
    @files = get_it($file);
  };# if -f $file
  $file = $transdir . "/LINGUAS";
  if(-f $file) {
    @languages = get_it($file);
  };# if -f $file
};# if $n

if(@files) {
  foreach my $file (@files) {

    if(-f $file)
    {
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
    } else {
      print("file $file does not exist!\n");
      exit(1);
    };# else
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
    s/YEAR-MO-DA HO:MI\+ZONE/$date/g;
    s/Language: /Language: @languages/g;
    s/Report-Msgid-Bugs-To: /Report-Msgid-Bugs-To: $author <$email>/g;

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
} # if @files
else
{
  print("no files.\n");
};# else @files

# vim:ai sw=2

