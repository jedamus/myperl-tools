#!/usr/bin/perl

# created Mittwoch, 05. Dezember 2012 06:32 (C) 2012 by Leander Jedamus
# modifiziert Mittwoch, 26. August 2015 12:59 von Leander Jedamus
# modifiziert Dienstag, 14. Juli 2015 13:27 von Leander Jedamus
# modifiziert Dienstag, 23. Juni 2015 14:59 von Leander Jedamus
# modifiziert Samstag, 16. Februar 2013 17:59 von Leander Jedamus
# modifiziert Samstag, 16. Februar 2013 17:58 von Leander Jedamus
# modified Mittwoch, 05. Dezember 2012 06:42 by Leander Jedamus

# .is_mounted sollte vor .mycopy.conf getestet werden!

# {{{1 POD-Manual
=head1 NAME

mycopy.pl

=head1 SYNOPSIS

mycopy.pl --help

mycopy.pl --warn

mycopy.pl --debug --debug --debug

=head1 DESCRIPTION

The B<mycopy.pl> script copies files and directories from one place to another.
It relies heavily on the date and time stamp of files. It only copies them, if
the source files are newer or don't exist at the destination. It was written
for the need to copy C<JPG>-files from a SDHC-card to the home directory. Also
it should copy them to another SD-card. The card itself now knows what data it
contains. It has a configuration file, which tells the program what to copy.  A
main configuration file tells the script where it has to look for those
configuration files. Under Ubuntu 10.04 USB-sticks and the like are mounted to
I</media/>, so all you have to tell the script in the main configuration file,
that it should look under I</media/*> and, for example, my home directory
I</home/ljedamus>. Symlinks to files are B<NOT> copied (they can be broken, so
they are ignored).

=head2 global configuration file C<mycopy.conf>

# source or destination

/home/ljedamus

/home/ljedamus/Dropbox

/media/*

/mnt/nas/*

Here you put the main source or destination directories, which have a
I<.mycopy.conf> and a I<.is_mounted>. These two files are needed to tell the
program, that for example the USB-stick is mounted and wants to be treated as a
source or destination target.

=head2 configuration file C<~/.mycopy.conf>

# Target:Source:Destination:Rekursive:Use_Stamp:Subdir:File(s)

canon_dc_jpg:y:y:n:n:Bilder/Fotos/CANON_DC:*.JPG

bin:y:y:y:n:bin:*.sh *.pl *.po *.mo

Here the first word is the target, the second if used as a source (y/n), the
third if used as a destination (y/n). The fourth word marks working recursively
(y/n).

The next word is useful, if you want to use a stamp-file, so that only files,
which are newer than the destination stamp are copied. It can be (y/n).

The sixth word is the sub directory (from the dir, which has the
I<.mycopy.conf> and the I<.is_mounted>).

The last word lists the file(s), which should be copied (and only them). Most
of the time it is C<*>.

=head2 corresponding configuration file C</media/CANON_DC/.mycopy.conf>

# Target:Source:Destination:Rekursive:Use_Stamp:Subdir:File(s)

canon_dc_jpg:y:n:n:n:DCIM/100CANON:*

Here the two configuration files have the same target C<canon_dc_jpg>. Also the
last file says, it is source, but not destination.

=cut
# }}}1

use strict;
use warnings;
use Term::ANSIColor;

use Locale::gettext qw( gettext bindtextdomain textdomain bind_textdomain_codeset );
use POSIX;
use FindBin '$Bin';
use File::Spec;

my $domain = "mycopy.pl";
bindtextdomain($domain,File::Spec->catfile($Bin,"translate"));
textdomain($domain);
bind_textdomain_codeset($domain,"UTF-8");
sub _ ($) { &gettext; }

my $mounted = ".is_mounted";
my $global_conffile = "mycopy.conf";
my $conffile = ".mycopy.conf";
my $stampfile = ".stamp";
my $globalfile = File::Spec->catfile($Bin,$global_conffile);
my $reffile = "/tmp/mycopy.tmp.$$";
my $used_reffile = 0;

my $warn = 0;# set to 1 if you want warnings always
my $debug = 0;
my $run_dry = 0;# if set to 1 to not copy, just report

# {{{1 sub usage
sub usage
{
  print _("usage:")."\n";
  print "--help    "._("this text")."\n";
  print "--run_dry "._("only try, do not copy")."\n";
  print "--warn    "._("set warnings")."\n";
  print "--debug   "._("set debug information and warnings")."\n";
};# sub usage
# }}}1

# {{{1 sub green
sub green
{
  print color 'green';
};# sub green
# }}}1

# {{{1 sub yellow
sub yellow
{
  print color 'yellow';
};# sub green
# }}}1

# {{{1 sub red
sub red
{
  print color 'red';
};# sub green
# }}}1

# {{{1 sub normal
sub normal
{
  print color 'reset';
};# sub normal
# }}}1

# {{{1 sub warning
sub warning
{
  my $text = shift;

  yellow;
  printf($text."\n",@_);
  normal;
};# sub warning
# }}}1

# {{{1 sub debug
sub debug
{
  my $text = shift;

  red;
  printf($text."\n",@_);
  normal;
};# sub debug
# }}}1

# {{{1 sub message
sub message
{
  my $text = shift;

  green;
  printf($text."\n",@_);
  normal;
};# sub message
# }}}1

# {{{1 sub stamp
sub stamp
{
  return (stat($_[0]))[9];
};# sub stamp
# }}}1

# {{{1 sub md5sum
sub md5sum
{
  open(FILE,">$reffile");
  print FILE "$_[0]\n";
  close(FILE);
  open(OUT,"PATH=$ENV{\"PATH\"} md5sum.pl $reffile|");
  my $line = <OUT>;
  chomp($line);
  $line =~ s/(.*) [\ \*].*/$1/;
  close(OUT);
  $used_reffile = 1;
  return $line;
};# sub md5sum
# }}}1

# {{{1 sub mycopy
sub mycopy
{
  (my $sdir, my $ddir, my $sfiles, my $rekursive, my $use_stamp, my $stamp) =
   @_;

  my @sfiles    = split(" ",$sfiles);
  my $copy;
  my $ret = "";
  my $retstamp = 0;

  if(! -d $ddir)
  {
    warning(_("Creating dir %s"),$ddir);
    if($run_dry eq "0") { system "mkdir", "-p", $ddir; };
  };# if
  chdir($sdir);
  my $sstamp;
  foreach my $file (@sfiles)
  {
    foreach (<${file}>)
    {
      if(-f $_)
      {
	$copy = "n";
	my $sfile = "$sdir/$_";
	my $dfile = "$ddir/$_";
	if(! -d $sfile)
	{
	  $sstamp=stamp($sfile);
	  if(-e $dfile)
	  {
	    my $dstamp=stamp($dfile);
	    if($debug >= 2) { debug(_("%s already exists"),$dfile); };

	    if($sstamp > $dstamp)
	    {
	      if($debug >= 2)
	      {
		if($debug >= 2)
		{
		  debug(_("%s is newer than %s"),$sfile, $dfile);
		};
	      };
	      if((-s $sfile == -s $dfile) && (md5sum($sfile) eq md5sum($dfile)))
	      {
		debug(_("%s is identical to %s"),$sfile,$dfile);
		utime $sstamp, $sstamp, $sfile, $dfile;
		if($debug >= 3) { debug("md5sum = ".md5sum($sfile)); };
	      } # if (-s $sfile == -s $dfile) && (md5sum($sfile) eq md5sum($dfile))
	      else
	      {
		if($use_stamp eq "y")
		{
		  if($sstamp > $stamp)
		  {
		    if($debug >= 2)
		    {
		      debug(_("%s is newer than stamp"), $sfile);
		    };
		    $copy="y";
		  } # if $sstamp > $stamp
		  else
		  {
		    if($debug >= 2)
		    {
		      debug(_("%s is not newer than stamp"),$sfile);
		    };
		  };# else $sstamp > $stamp
		} # if $use_stamp eq "y"
		else
		{
		  if($debug >= 2) { debug(_("%s is newer"),$sfile); };
		  $copy = "y";
		};# else $use_stamp eq "y"
	      };# else (-s $sfile == -s $dfile) && (md5sum($sfile) eq md5sum($dfile))
	    } # if $sstamp > $dstamp
	    else
	    {
	      if($debug >= 2) {debug(_("let %s unchanged"),$dfile);};
	    };# else $sstamp > $dstamp
	  } # if -e $dfile
	  else
	  {
	    if($use_stamp eq "y")
	    {
	      if($sstamp > $stamp)
	      {
		if($debug >= 2)
		{
		  debug(_("%s is newer than stamp"),$sfile);
		};
		$copy="y";
	      } # if $sstamp > $stamp
	      else
	      {
		if($debug >= 2)
		{
		  debug(_("%s is not newer than stamp"),$sfile);
		};
	      };# else $sstamp > $stamp
	    } # if $use_stamp eq "y"
	    else
	    {
	      if($debug >= 2) { debug(_("%s does not exist"),$dfile); };
	      $copy = "y";
	    };# else $use_stamp eq "y"
	  };# else -e $dfile
	};# if ! -d "$sfile"
	if($copy eq "y")
	{
	  if(! -l $_ )
	  {
	    message(_("I copy %s from %s to %s"),$_,$sdir,$ddir);
	    if($run_dry eq "0")
	    {
	      system "cp", "-p", $sfile, $ddir;
	      utime $sstamp, $sstamp, $sfile, $dfile;
	    };
	    if($sstamp > $stamp)
	    {
	      $ret = $sfile;
	      $retstamp = $sstamp;
	      if($debug >= 2) { debug(_("set ret to %s"),$ret); };
	      if($debug >= 2) { debug(_("set retstamp to %s"),$retstamp); };
	    };# if $sstamp > $stamp
	  } # if ! -l $_
	  else
	  {
	    if($warn >= 1) { warning(_("symlink %s is ignored"),$_); };
	  } # else ! -l $_
	};#if $copy eq "y"
      };# if -f $_
    };# foreach (<${file}>)
  };# foreach my $file (@sfiles)
  if($rekursive eq "y")
  {
    my @subdir;
    opendir(DIR,$sdir) || die sprintf(_("Cannot open dir %s!"),$sdir);
    if($debug >= 2) { debug(_("reading dir %s"),$sdir); };
    while(my $line = readdir(DIR))
    {
      if($line =~ /^\.$/) { next; };
      if($line =~ /^\.\.$/) { next; };
      my $sline = "$sdir/$line";
      if(-d "$sline")
      {
	unshift(@subdir,"$line");
	if($debug >= 2) { debug(_("%s is subdir"),$line); };
      };# if -d "$sdir/$_"
    };# while readdir(DIR)
    closedir(DIR);
    foreach my $line (@subdir)
    {
      if($debug >= 3) { debug(_("rekursive call from %s"),$sdir); };
      my $retmycopy =
	mycopy($sdir."/".$line,$ddir."/".$line,$sfiles,$rekursive,$use_stamp,
	       $stamp);
      if($debug >= 3)
      {
	debug(_("rekursive call finished. I'm in %s"),$sdir);
      };
      if($retmycopy ne "")
      {
	my $retmycopystamp = stamp($retmycopy);
	if($retmycopystamp > $retstamp)
	{
	  $ret = $retmycopy;
	  $retstamp = $retmycopystamp;
	};# if stamp($retmycopy) > $retstamp
      };# if $retmycopy ne ""
    };# foreach my $sub (@subdir)
  };# if $rekursive eq "y"
  return $ret;
};# sub mycopy
# }}}1

foreach my $param (@ARGV)
{
  my $ok = 0;
  if($param eq "--help") { usage; exit; $ok = 1; };
  if($param eq "--run_dry") { $run_dry = 1; $ok = 1; };
  if($param eq "--warn") { $warn = 1; $ok = 1; };
  if($param eq "--debug") { $debug++; $warn = 1; $ok = 1; };
  if($ok == 0) { usage; exit; };
};# foreach

my @wo;

if($debug >= 2)
{
  debug(_("Open global configuration file %s"),$globalfile);
};
open(WO,$globalfile);
while(<WO>)
{
  chomp;
  if($debug >= 3) { debug("%s: %s",$globalfile,$_); };
  if(! /^#/)
  {
    if(/\*/)
    {
      if(/\*\S+$/)
      {
	die _("* in global configuration file at wrong position!");
      } # if /\*\S+$/
      else
      {
	s/(.*)\*/$1/;
	opendir(DIR,$_) || die sprintf(_("Cannot open dir %s!"),$_);
	if($debug >= 2) { debug(_("  reading dir %s"),$_); };
	while(my $line = readdir(DIR))
	{
	  if($debug >= 3) { debug("  %s: %s",$_,$line); };
	  if($line =~ /^\./) { next; };
	  if($line =~ /^\.\./) { next; };
	  my $sdir = $_ . $line;
	  if(-d $sdir)
	  {
	    if($debug >= 2)
	    {
	      debug(_("  %s: %s is subdir"),$globalfile,$sdir);
	    };
	    unshift(@wo,$sdir);
	  };# if -d $line
	};# while readdir(DIR)
	closedir(DIR);
      };# else /\*\S+$/
    } # if /*/
    else
    {
      if($debug >= 2) { debug(_("  %s: %s is dir"),$globalfile,$_); };
      unshift(@wo,$_);
    };# else /*/
  };# if ! /^#/
};# while WO
close(WO);

foreach my $source (@wo)
{
  foreach my $dest (@wo)
  {
    if($source ne $dest)
    {
      if($debug >= 2) { debug(_("Comparing %s with %s"),$source,$dest); };
      if(-e $source . "/" . $mounted)
      {
	if($debug >= 2)
	{
	  debug(_("%s is mounted"),$source);
	};
	if(-e $dest . "/" . $mounted)
	{
	  if($debug >= 2)
	  {
	    debug(_("%s is mounted"),$dest);
	  };
	  my $sfconf = $source . "/" . $conffile;
	  if(-e $sfconf)
	  {
	    if($debug >= 2)
	    {
	      debug(_("Reading configuration file %s"),$sfconf);
	    };
	    open(SOURCE,$sfconf) || die sprintf(_("Cannot open %s!"),$sfconf);
	    my $scount = 0;
	    while(<SOURCE>)
	    {
	      $scount++;
	      chomp;
	      if($debug >= 3) { debug(_("Source %s: %s"),$sfconf,$_); };
	      if(! /^#/)
	      {
		(my $starget,my $ssrc,my $sdst,my $srek, my $sstamp,
		 my $ssubdir, my $sfiles) = split(/:/);
		if(! defined $sfiles)
		{
		  die sprintf(_("Error in configuration file %s line:%s"),
			      $sfconf,$scount);
		};# if ! defined $sfiles
		my $dfconf = $dest ."/" . $conffile;
		if(-e $dfconf)
		{
		  if($debug >= 2)
		  {
		    debug(_("Reading configuration file %s"),$dfconf);
		  };
		  open(DEST,$dfconf) || die sprintf(_("Cannot open %s!"),$dfconf);
		  my $dcount = 0;
		  while(<DEST>)
		  {
		    $dcount++;
		    chomp;
		    if($debug >= 3) { debug(_("Dest %s: %s"),$dfconf,$_); };
		    if(! /^#/)
		    {
		      (my $dtarget,my $dsrc,my $ddst,my $drek, my $dstamp,
		       my $dsubdir, my $dfiles) = split(/:/);
		      if(! defined $dfiles)
		      {
			die sprintf(_("Error in configuration file %s ".
					    "line:%s"),$dfconf,$dcount);
		      };# if ! defined $dfiles
		      if($starget eq $dtarget)
		      {
			if($debug >= 2)
			{
			  debug(_("target for Source and Dest is the same"));
			};# if $debug >= 2
			if(($ssrc =~ /^[yYjJ]/) and ($ddst =~ /^[yYjJ]/))
			{
			  if($debug >= 2)
			  {
			    debug(_("Source is yes und Dest is yes"));
			  };# if $debug >= 2
			  my $trek = "";
			  my $rekursive = "n";
			  if($srek =~ /^[yYjJ]/)
			  {
			    if($debug >= 2) { debug(_("rekursive is yes")); };
			    $trek = _(" rekursive");
			    $rekursive = "y";
			  };
			  my $sdir = $source;
			  if($ssubdir ne "")
			  {
			    if($debug >= 2)
			    {
			      debug(_("Source subdir is %s"),$ssubdir);
			    };
			    $sdir .= "/" . $ssubdir;
			    if(! -d $sdir)
			    {
			      if($warn >= 1)
			      {
				warning(_("Source subdir %s does not exist. ".
					    "Error in %s?"),
					$ssubdir,$sfconf);
			      };# if $warn >= 1
			      next;
			    };# if ! -d $sdir
			  };# if $ssubdir ne ""
			  my $ddir = $dest;
			  if($dsubdir ne "")
			  {
			    if($debug >= 2)
			    {
			      debug(_("Dest subdir is %s"),$dsubdir);
			    };
			    $ddir .= "/" . $dsubdir;
			  };# if $dsubdir ne ""
			  my $dstampfile = "$dest/$stampfile";

			  if($debug >= 1)
			  {
			    message(_("Copying%s %s from %s to %s"),
				    $trek,$sfiles,$sdir,$ddir);
			  };
			  my $stamp = "n";
			  my $STAMP;
			  if(-e "$dstampfile")
			  {
			    $STAMP = stamp("$dstampfile");
			  } # if -e "$dstampfile"
			  else
			  {
			    $STAMP = 0;
			  };# else -e "$dstampfile"
			  if($dstamp =~ /^[yYjJ]/)
			  {
			    if($debug >= 1)
			    {
			      message(_("Use STAMP %s"),$STAMP);
			    };
			    $stamp = "y";
			  };# if $dstamp =~ /^[yYjJ]/
			  my $retmycopy = mycopy($sdir,$ddir,$sfiles,
						 $rekursive,$stamp,$STAMP);
			  if($debug >= 2)
			  {
			    message(_("retmycopy is %s"),$retmycopy);
			  };
			  if($retmycopy ne "")
			  {
			    if($stamp eq "y")
			    {
			      if($run_dry eq "0")
			      {
				system "touch", "-r", $retmycopy, $dstampfile;
			      };
			      if($debug >= 1)
			      {
				message(_("putting STAMPFILE %s to new ".
						"value"),$dstampfile);
			      };
			    };# if $stamp eq "y"
			  };# if $retmycopy ne ""
			} # if ($ssrc =~ /^[yYjJ]/) and ($ddst =~ /^[yYjJ]/)
			else
			{
			  if($debug >= 2)
			  {
			    debug(_("Source and Dest are not yes"));
			  };# if $debug >= 2
			};# else ($ssrc =~ /^[yYjJ]/) and ($ddst =~ /^[yYjJ]/)
		      } # if $starget eq $dtarget
		      else
		      {
			if($debug >= 2)
			{
			  debug(_("target for Source and Dest is not the same"));
			};# if $debug >= 2
		      };# else $starget eq $dtarget
		    };# if ! /^#/
		  };# while DEST
		  close(DEST);
		} # if -e $dfconf
		else
		{
		  if($warn >= 1) { warning(_("Cannot find %s"),$dfconf); };
		};# else -e $dfconf
	      };# if ! /^#/
	    };# while SOURCE
	    close(SOURCE);
	  } # if -e $sfconf
	  else
	  {
	    if($warn >= 1) { warning(_("Cannot find %s"),$sfconf); };
	  };# else -e $sfconf
	} # if dest is mounted
	else
	{
	  if($warn >= 1)
	  {
	    warning(_("%s is not mounted"),$dest);
	  };
	};# else -e $dest . "/" . $mounted
      } # if source is mounted
      else
      {
	if($warn >= 1)
	{
	  warning(_("%s is not mounted"),$source);
	};
      };# else -e $source . "/" . $mounted
    };# if $source ne $dest
  };# foreach @wo (inner loop)
};# foreach @wo (outer loop)
if($used_reffile == 1)
{
  if($debug >= 3) { debug(_("Removing obsolete tmp-file %s"),$reffile); };
  unlink $reffile;
};# if $used_reffile == 1
