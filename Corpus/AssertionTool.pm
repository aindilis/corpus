package Corpus::AssertionTool;

use Corpus::Sources;
use Manager::Dialog qw(QueryUser);
use PerlLib::MySQL;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Sources /

  ];

sub init {
  my ($self, %args) = @_;
  $self->Sources($args{Sources});
}

sub Execute {
  my ($self, %args) = @_;
  my $conf = $UNIVERSAL::corpus->Config->CLIConfig;
  if (scalar @{$conf->{'--assert'}}) {
    foreach my $goal (@{$conf->{'--assert'}}) {
      $self->Process(Goal => $goal);
    }
  } else {
    while (1) {
      my $goal = QueryUser("Please enter new goal:");
      # $self->Sources->Search(String => $goal);
      $self->Process(Goal => $goal);
    }
  }
}

sub Process {
  my ($self, %args) = @_;
  foreach my $entry
    (@{$self->Sources->SimilaritySearch
	 (
	  # Method => "Capability::SentenceSimilarity",
	  # Method => "Text::Similarity::Overlaps",
	  Method => "String::Similarity",
	  String => $args{Goal},
	 )}) {
    printf "%0.4f %i\n\t%s\n",$entry->[1], $entry->[0]->{ID}, $entry->[0]->{Contents};
  }
}

1;
