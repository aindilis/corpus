#!/usr/bin/perl -w

use Sayer;
use PerlLib::MySQL;

use Data::Dumper;
use DB_File;

my $sayer = Sayer->new;
#  (StorageFile => "/var/lib/myfrdcsa/codebases/internal/corpus/data/nlp.db");

my $mysql = PerlLib::MySQL->new
  (DBName => "unilang");

my $res = $mysql->Do
  (
   Statement => "select * from messages where Sender='UniLang-Client' and Contents != 'Register'",
   Array => 1,
  );

foreach my $entry (@$res) {
  my $text = $entry->[4];
  next unless $text =~ /\w/;
  $sayer->Analyze
    (Data => $text);
}
