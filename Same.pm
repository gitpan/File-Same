package File::Same;

use strict;
use vars qw/$VERSION/;
$VERSION = '0.01';

use Digest::MD5;
use File::Spec;

my %md5s;

sub scan_files {
    my ($original, $files) = @_;
    
    my @results;
    my $orig_md5 = $md5s{$original};
    
    if (!$orig_md5) {
        my $ctx = Digest::MD5->new();
        open(FILE, $original) || die "Cannot open '$original' : $!";
        $ctx->addfile(*FILE);
        $orig_md5 = $ctx->hexdigest;
    }
    
    foreach my $file (@$files) {
        if (my $md5 = $md5s{$file}) {
            if ($orig_md5 eq $md5) {
                push @results, $file;
            }
        }
        else {
            my $ctx = Digest::MD5->new();
            open(FILE, $file) || die "Cannot open '$file' : $!";
            $ctx->addfile(*FILE);
            if ($orig_md5 eq $ctx->hexdigest) {
                push @results, $file;
            }
        }
    }

    return grep {$_ ne $original} @results;
}

sub scan_dir {
    my ($original, $dir) = @_;

    opendir(DIR, $dir) || die "Cannot opendir '$dir' : $!";
    my @files = grep { -f } map { File::Spec->catfile($dir, $_) } readdir(DIR);
    closedir(DIR);

    return scan_files($original, \@files);
}

sub scan_dirs {
    my ($original, $dirs) = @_;

    my @results;

    foreach my $dir (@$dirs) {
        push @results, scan_dir($original, $dir);
    }

    return @results;
}

1;
__END__

=head1 NAME

File::Same - Detect which files are the same as a given one

=head1 SYNOPSIS

  use File::Same;
  my @same = File::Same::scan_dirs($original, ['other', '.']);

  or
  my @same = File::Same::scan_files($original, [@list]);

      or
  my @same = File::Same::scan_dir($original, 'somedir');

=head1 DESCRIPTION

File::Same uses MD5 sums to tell you which files are the same in a given directory,
set of directories, or set of files. It was originally written to test which files
are the same picture in multiple directories or under multiple filenames, but can
be generally useful for other systems.

File::Same will use an internal cache, for performance reasons.

File::Same will also be careful not to return $original in the list of matched files.

=head1 API

=head2 File::Same::scan_files($original, $list)

Scan a list of files to compare against a given file. $list is an array reference,

=head2 File::Same::scan_dir($original, $dir)

Scan an entire directory to find files the same as this one.

=head2 File::Same::scan_dirs($original, $dirs)

Scan a list of directories to find files the same as this one. $dirs is an array
reference.

All of the above functions return a list of files that match, with their full path
expanded.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

Digest::MD5

=cut
