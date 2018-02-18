#!/usr/bin/perl -w

# this is a program to recommend codebases to the user based on review
# of the software

use Manager::Dialog qw(QueryUser);
use PerlLib::MySQL;

use Data::Dumper;
use Search::ContextGraph;

my $cg = Search::ContextGraph->new();

my $docs = {};
my $over = {};

my $mysql = PerlLib::MySQL->new
  (DBName => "unilang");
my $res = $mysql->Do(Statement => "select * from messages where Sender='UniLang-Client'"); #  where ID > 500000");
foreach my $entry (values %$res) {
  my $title = $entry->{ID};
  my $desc = $entry->{Contents};
  if ($desc) {
    $over->{$title} = $desc;
    my $items = [map {lc($_)} split /\W+/, $desc];
    $docs->{$title} = $items if scalar @$items;
  }
}

$cg->bulk_add( %$docs );

while (1) {
  my $it = QueryUser(Message => "Search?");
  my ($things,$words) = $cg->search( $it );
  print Dumper($words);
  print Dumper($things);
}
