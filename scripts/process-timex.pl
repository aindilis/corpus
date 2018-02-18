#!/usr/bin/perl -w

use PerlLib::MySQL;

use Lingua::EN::Extract::Dates;

use Data::Dumper;

my $de = Lingua::EN::Extract::Dates->new;

my $mysql = PerlLib::MySQL->new
  (DBName => "unilang");

my $res = $mysql->Do
  (
   Statement => "select * from messages where Sender='UniLang-Client' and Contents != 'Register'",
   Array => 1,
  );

foreach my $entry (@$res) {
  print Dumper
    ([
      $entry->[3],
      $entry->[4],
     ]);
  print Dumper
    (
     $de->TimeRecognizeText
     (
      Date => $entry->[3],
      Text => $entry->[4],
     )
    );
}
