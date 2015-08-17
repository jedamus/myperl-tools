#!/usr/bin/perl

# written 21.11.2012 Leander Jedamus
# modifiziert Dienstag, 23. Juni 2015 18:19 von Leander Jedamus
# modified Dienstag, 05. Februar 2013 14:57 by Leander Jedamus
# modified Dienstag, 05. Februar 2013 12:02 by Leander Jedamus
# modified Montag, 04. Februar 2013 11:50 by Leander Jedamus

use strict;
use warnings;

use Locale::gettext qw( gettext bindtextdomain textdomain bind_textdomain_codeset );
use POSIX;
use FindBin '$Bin';
use File::Spec;

use Tk;
use Tk::DialogBox;
use Tk::PNG;

bindtextdomain("myconf",File::Spec->catfile("$Bin","translate"));
textdomain("myconf");
bind_textdomain_codeset("myconf","ISO-8859-1");

my $global_conffile = File::Spec->catfile("$Bin","mycopy.conf");
my $conffile = ".mycopy.conf";

sub _ ($) { &gettext; }

sub toggle
{
  my $button = shift;
  my $var = shift;

  # buttons-text:
  my $yes = _("Yes");
  my $no  = _("No");

  my $answer = $button->cget('-text') eq $yes ? $no : $yes;
  $button->configure(-text => $answer);
  $$var = $answer eq $yes ? 'y' : 'n';
};# toggle

sub edit
{

  my $list = $_[0];

  # buttons-text:
  my $save   = _("Save");
  my $cancel = _("Cancel");
  my $yes    = _("Yes");
  my $no     = _("No");

  my $eingabe_top = $list->DialogBox(-title => 'myconf edit',
                                     -buttons => [$save, $cancel]);

  my ($target, $src, $dest, $rek, $stamp, $subdir, $files) =
    split(/:/,$list->get('active'));

  my $target_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                                 -anchor => 'w');
  my $target_label = $target_frame->Label(-text => _("Target:"))
                       ->pack(-side => 'left');
  my $target_text = $target_frame->Entry(-text => $target)
                       ->pack(-side => 'left');

  my $source_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                                 -anchor => 'w');
  my $source_label = $source_frame->Label(-text => _("Source:"))
                       ->pack(-side => 'left');
  my $source_button =
       $source_frame->Button(-text => $src eq 'y' ? $yes : $no);
  $source_button->configure(-command => [ \&toggle, $source_button, \$src ]);
  $source_button->pack(-side => 'left');

  my $dest_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                               -anchor => 'w');
  my $dest_label = $dest_frame->Label(-text => _("Destination:"))
                     ->pack(-side => 'left');
  my $dest_button =
       $dest_frame->Button(-text => $dest eq 'y' ? $yes : $no);
  $dest_button->configure(-command => [ \&toggle, $dest_button, \$dest ]);
  $dest_button->pack(-side => 'left');

  my $rek_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                              -anchor => 'w');
  my $rek_label = $rek_frame->Label(-text => _("recursive:"))
                    ->pack(-side => 'left');
  my $rek_button =
       $rek_frame->Button(-text => $rek eq 'y' ? $yes : $no);
  $rek_button->configure(-command => [ \&toggle, $rek_button, \$rek ]);
  $rek_button->pack(-side => 'left');

  my $stamp_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                                -anchor => 'w');
  my $stamp_label = $stamp_frame->Label(-text => _("Use stamp:"))
                      ->pack(-side => 'left');
  my $stamp_button =
       $stamp_frame->Button(-text => $stamp eq 'y' ? $yes : $no);
  $stamp_button->configure(-command => [ \&toggle, $stamp_button, \$stamp ]);
  $stamp_button->pack(-side => 'left');

  my $subdir_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                                 -anchor => 'w');
  my $subdir_label = $subdir_frame->Label(-text => _("Subdir:"))
                       ->pack(-side => 'left');
  my $subdir_text = $subdir_frame->Entry(-text => $subdir)
                       ->pack(-side => 'left');

  my $files_frame = $eingabe_top->Frame()->pack(-side => 'top',
                                                -anchor => 'w');
  my $files_label = $files_frame->Label(-text => _("Files:"))
                      ->pack(-side => 'left');
  my $files_text = $files_frame->Entry(-text => $files)
                      ->pack(-side => 'left');

  my $button = $eingabe_top->Show;
 
  if($button eq $save)
  {
    $target = $target_text->cget('-text');
    $subdir = $subdir_text->cget('-text');
    $files = $files_text->cget('-text');

    my $index = $list->index('active');
    $list->delete('active');
    $list->insert($index,"$target:$src:$dest:$rek:$stamp:$subdir:$files");
  };# if $button eq $save
};# edit

my $tlist;

sub conf_dialog
{
  my $top = shift;
  my $conffile = $tlist->get('active');
  my $title = 'myconf '.$conffile;

  # buttons-text:
  my $save   = _("Save");
  my $cancel = _("Cancel");

  my $dialog = $top->DialogBox(-title => $title,
			       -buttons => [$save, $cancel]);

  my $frame_top = $dialog->Frame()->pack();
  my $frame_bottom = $dialog->Frame()->pack();

  my $list = $frame_top->Listbox(-width => 80,
			-height => 5
		       )->pack(-side => 'left');
  my $scroll = $frame_top->Scrollbar(-command => ['yview', $list])
		   ->pack(-side => 'right', -fill => 'y');
  $list->configure(-yscrollcommand => ['set', $scroll]);

  open(CONF,$conffile) || die sprintf(_("Cannot open %s!"),$conffile);
  while(<CONF>)
  {
    chomp;
    if(! /^#/)
    {
      $list->insert('end',$_);
    };# if ! /^#/
  };# while <CONF>
  close(CONF);

  $list->bind("<Double-Button-1>" => [\&edit, $list]);

  my $insert_button =
       $frame_bottom->Button(-text => _("Insert"),
                             -command =>
			       sub {$list->insert('active',
			                          'new_target:y:y:n:n::*');} )
         ->pack(-side => 'left');
  my $delete_button =
       $frame_bottom->Button(-text => _("Delete"),
                             -command => sub { $list->delete('active'); })
         ->pack(-side => 'left');

  my $response = $dialog->Show;

  if($response eq $save)
  {
    open(CONF,">$conffile") || die sprintf(_("Cannot open %s!"),$conffile);
    print CONF "#Target:Source:Destination:Rekursive:Use_Stamp:Subdir:".
               "File(s)\n";

    my $last_index = $list->index('end');
    for(my $i = 0; $i < $last_index; $i++)
    {
      print CONF $list->get($i),"\n";
    };# for $i

    close(CONF);
  };# if $response eq $save
};# sub conf_dialog

my $top = MainWindow->new();
$top->title("myconf");
my $machine = `uname -n`;
chomp($machine);
my $file;
if($machine eq 'marvin')
{
  $file = "/usr/share/icons/oxygen/32x32/categories/applications-office.png";
} # if marvin
else
{
  if($machine eq 'MacBooks-MBP.fritz.box')
  {
    $file = "/Applications/Skype.app/Contents/Resources/WebLogin/images/normal/logo-office-25x25.png";
  } # if MacBooks-MBP.fritz.box
  else
  {
    $file = "/usr/share/icons/gnome/32x32/categories/applications-office.png";
  };# else MacBooks-MBP.fritz.box
};# else marvin
my $icon = $top->Photo(-file => $file,
                       -format => 'PNG',
		       -width => 32,
		       -height => 32);
$top->iconimage($icon);

my $frame_top = $top->Frame()->pack();
my $frame_bottom = $top->Frame()->pack();

$tlist = $frame_top->Listbox(-width => 80,
                             -height => 5)
            ->pack(-side => 'left');
my $scroll = $frame_top->Scrollbar(-command => ['yview', $tlist])
                 ->pack(-side => 'right', -fill => 'y');
$tlist->configure(-yscrollcommand => ['set', $scroll]);

open(GLOBALCONF,$global_conffile) ||
 die sprintf(_("Cannot open %s!"),$global_conffile);
while(<GLOBALCONF>)
{
  chomp;
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
	while(my $line = readdir(DIR))
	{
	  if($line =~ /^\./) { next; };
	  if($line =~ /^\.\./) { next; };
	  my $dir = $_ . $line;
	  if(-d $dir)
	  {
	    my $file = File::Spec->catfile($dir,$conffile);
	    if(-f $file)
	    {
	      $tlist->insert('end', $file);
	    };# if -f $file
	  };# if -d $dir
	};# while
	closedir(DIR);
      };# else if /\*\S+$/
    } # if /\*/
    else
    {
      my $file = File::Spec->catfile($_,$conffile);
      if(-f $file)
      {
        $tlist->insert('end', $file);
      };# if -f $dir.'/.mycopy.conf'
    };# else /\*/
  };# if ! /^#/
};# while 
close(GLOBALCONF);

$tlist->bind("<Double-Button-1>" => [\&conf_dialog, $top]);

my $exit_button = $frame_bottom->Button(-text => _("Exit"),
                                        -command => sub { $top->destroy; } )
     ->pack(-side => 'left');


MainLoop();
