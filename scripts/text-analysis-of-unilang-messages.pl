#!/usr/bin/perl -w

use Capability::TextAnalysis;
use PerlLib::MySQL;

use Data::Dumper;

my $analyzer = Capability::TextAnalysis->new
  (
   DBName => "sayer_corpus",
   Skip => {
	    # SemanticAnnotation => 1,
	    # NamedEntityRecognition => 1,
	   },
  );

my $mysql = PerlLib::MySQL->new
  (DBName => "unilang");

my $res = $mysql->Do
  (
   Statement => "select * from messages where Sender='UniLang-Client' and Contents != 'Register'",
   Array => 1,
  );

my $data;
foreach my $entry (@$res) {
  my $text = $entry->[4];
  next unless $text =~ /\w/;

  my $string = $entry->[3];
  if ($string =~ /^(\S+) .*/) {
    my $date = $1;
    print Dumper(
		 $analyzer->ProcessText
		 (
		  Text => $text,
		  Date => $date,
		 ),
		);
  } else {
    print "ERROR no date: $string\n";
    print Dumper($entry);
  }
}
