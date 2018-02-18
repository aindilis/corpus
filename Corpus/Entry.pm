package Corpus::Entry;

use PerlLib::Collection;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw /  /

  ];

sub init {
  my ($self,%args) = (shift,@_);
}

sub ManuallyVerifyAutoClassificationResults {
  my ($self,%args) = (shift,@_);
  # In  lieu of  a complete  solution, we  can simply  manually verify
  # Corpus auto classification results at the end of each cycle.

}

sub PropertyAddedManuallyOrAutomatically {
  my ($self,%args) = (shift,@_);
  # Features  to add  to  Corpus -  need  to add  system to  determine
  # whether a property was manually or automatically selected.

}

sub MeasureOfClassificationCompleteness {
  my ($self,%args) = (shift,@_);

}

sub FormalizeEntry {
  my ($self,%args) = (shift,@_);
  # Maybe  corpus  could handle  formalization  of  everything -  from
  # Verber and PSE entries too?

}

sub MarkEntryAsProcessed {
  my ($self,%args) = (shift,@_);
  # Also need UniLang or corpus  to record which messages have already
  # been addressed.

}

1;
