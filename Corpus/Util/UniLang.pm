package Corpus::Util::UniLang;

use PerlLib::MySQL;

use Data::Dumper;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / MyMySQL /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyMySQL
    (PerlLib::MySQL->new
     (
      DBName => "unilang",
     ));
}

sub GetUniLangMessageContents {
  my ($self,%args) = @_;
  print Dumper($args{EntryID});
  return
    $self->MyMySQL->Do
      (
       Statement => "select Contents from messages where ID = '".$args{EntryID}."';",
       Array => 1,
      )->[0]->[0];
}

1;
