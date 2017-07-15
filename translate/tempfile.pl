#!/usr/bin/perl

# erzeugt Samstag, 15. Juli 2017 16:31 (C) 2017 von Leander Jedamus
# modifiziert Samstag, 15. Juli 2017 16:42 von Leander Jedamus

use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use Getopt::Long;

my ($dir, $fh, $filename, $line);
my (@files, $project, $version);

$version = "1.0"; $project = "project";

$dir = tempdir( CLEANUP =>  1 );
($fh, $filename) = tempfile( DIR => $dir );

binmode($fh);
print "dir = $dir, filename = $filename\n";

GetOptions('file=s' => \@files,
           'project=s' => \$project,
	   'version=s' =>  \$version);

foreach my $file (@files) {
  print "file = $file\n";
};# foreach
print "project = $project\n";
print "version = $version\n";
# vim:ai sw=2
