#!/usr/bin/perl -w

use Corpus::Auto::AICategorizer;
use Corpus::Sources;

# train it

my $sources = Corpus::Sources->new();
$sources->Entries
  ($sources->ListRecentItems
   (Conf => {}));

foreach my $entry (@{$sources->Entries}) {
  if ($entry->{Contents} =~ /^(\S+),\s*(.+)$/s) {
    Add($1,$2);
  } else {
    Add("unknown",$entry->{Contents});
  }
}

