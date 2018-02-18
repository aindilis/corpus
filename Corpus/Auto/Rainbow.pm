package Corpus::Auto::Rainbow;

use Manager::Dialog qw (ApproveCommands);

use Digest::MD5 qw(md5 md5_hex md5_base64);

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '1.00';

use Class::MethodMaker new_with_init => 'new',
  get_set => [ qw / UI ClassifierDataLocation Built / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->UI($args{UI});
  $self->ClassifierDataLocation($args{ClassifierDataLocation} || "classifier-data");
  die "Need to know the index location." unless $self->ClassifierDataLocation;
}

sub RebuildIndex {
  my ($self,%args) = (shift,@_);
  # first make sure that in our classifier-data location all the directories for the current classes exist

  my $classifierdatadir = $self->ClassifierDataLocation;
  if (! -d $classifierdatadir) {
    system "mkdir $classifierdatadir";
  }

  # make hash of dir names
  my $classhash = {};
  foreach my $class (@{$self->UI->Classes}) {
    $class =~ s/[^\w]/-/g;
    $classhash->{$class} = 1;
  }

  # ensure that no dir names are present that aren't in the UI
  my @commands;
  foreach my $dir (split /\n/,`ls $classifierdatadir`) {
    # $dir =~ s/[^\w]/-/g;
    if (! exists $classhash->{$dir}) {
      push @commands, "rm -rf \"$classifierdatadir/$dir\"";
    }
  }
  # ensure that all dir names are present that are in the UI
  foreach my $dir (keys %$classhash) {
    if (! -d "$classifierdatadir/$dir") {
      push @commands, "mkdir \"$classifierdatadir/$dir\"";
    }
  }
  if (@commands and
      ApproveCommands(Method => "parallel",
		      Commands => \@commands)) {
    foreach my $entry (@{$self->UI->GetAllEntries}) {
      foreach my $class (keys %{$self->UI->Properties->{$entry}}) {
	my $dir = $class;
	$dir =~ s/[^\w]/-/g;
	# create  a hashed  document  containing these  statements in  a
	# directory for each class
	my $OUT;
	my $hashname = $self->HashName(Entry => $entry);
	my $filename = "$classifierdatadir/$dir/$hashname";
	print $filename."\n";
	open (OUT,"> $filename") or
	  die "Ouch!\n";
	print OUT $entry;
	close(OUT);
      }
    }
    system "rainbow -i ".$self->ClassifierDataLocation."/*";
    $self->Built(1);
  }
}

sub HashName {
  my ($self,%args) = (shift,@_);
  return md5_hex($args{Entry});
}

sub ClassifyEntry {
  my ($self,%args) = (shift,@_);
  if (! $self->Built) {
    $self->RebuildIndex;
  }
  my $entry = $args{Entry};
  # my $file = $entry->Loc;
  my $file = "/tmp/critic-classifier";
  my $OUT;
  open (OUT,"> $file") or
    die "Ouch!\n";
  print OUT $entry;
  close(OUT);
  my %score;
  # my $options = "--skip-header --skip-html --no-stoplist --prune-vocab-by-occur-count=2 --prune-vocab-by-infogain=2000";
  # my $results = `rainbow $options --query=$file 2> /dev/null`;
  my $results = `rainbow --query=$file 2> /dev/null`;
  $results =~ s/.*^$//s;
  foreach my $line (split(/\n/,$results)) {
    if ($line ne "") {
      my @result = split(/ /,$line);
      $score{$result[0]} = $result[1];
    }
  }
  return \%score;
}

1;
