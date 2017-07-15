use File::Temp qw/ tempfile tempdir /;

my ($dir, $fh, $filename, $line);

$dir = tempdir( CLEANUP =>  1 );
($fh, $filename) = tempfile( DIR => $dir );

binmode($fh);

GetOptions('file=s' => \@files);
