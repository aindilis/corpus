#!/usr/bin/perl -w

use Capability::NER;
use PerlLib::MySQL;

use Data::Dumper;
use DB_File;
use FreezeThaw qw(freeze thaw);
use Memoize;

my $ne = Capability::NER->new
  (EngineName => "Stanford");

my $mysql = PerlLib::MySQL->new
  (DBName => "unilang");

my $res = $mysql->Do
  (
   Statement => "select * from messages where Sender='UniLang-Client' and Contents != 'Register'",
   Array => 1,
  );

my $filename = "/var/lib/myfrdcsa/codebases/internal/corpus/data/named-entitys.db";
tie my %cache => 'DB_File', $filename, O_RDWR|O_CREAT, 0666;

sub NERExtract {
  my $text = shift;
  # print Dumper($text);
  return Dumper
    ($ne->Engine->NERExtract
     (Text => $text));
}

memoize 'NERExtract', SCALAR_CACHE => [HASH => \%cache];

my $data;
foreach my $entry (@$res) {
  my $text = $entry->[4];
  next unless $text =~ /\w/;
  my $item = NERExtract($text);
  eval $item;
  my $res = $VAR1;
  my @persons;
  foreach my $entry2 (@$res) {
    if ($entry2->[1] eq "PERSON") {
      my $person = join(" ",@{$entry2->[0]});
      push @persons, $person;
      $data->{$person}->{$entry->[0]} = 1;
    }
  }
  if (scalar @persons) {
      print Dumper
	([
	  $entry->[3],
	  $entry->[4],
	  join (", ",@persons),
	 ]);
  }
}

print Dumper($data);
