#!/usr/bin/perl -w

use Lingua::EN::Extract::Dates;

use Data::Dumper;

my $de = Lingua::EN::Extract::Dates->new;

foreach my $arg (@ARGV) {
  print Dumper
    (
     $de->TimeRecognizeText
     (
      Text => $arg,
     )
    );
}

