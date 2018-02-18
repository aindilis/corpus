package Corpus::Auto::Person;

use PerlLib::Collection;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / /

  ];

sub init {
  my ($self,%args) = (shift,@_);
}

sub ManuallyVerifyAutoClassificationResults {
  # In  lieu of  a complete  solution, we  can simply  manually verify
  # Corpus auto classification results at the end of each cycle.

  # actually  what we  want from  the user  is an  explanation  of the
  # proper command to run

  # for instance, "I wouldn't be surprised if an advanced system has
  # hacked my machine.", then we would want to put this into some kind
  # of general knowledge base.

  # choosing more carefully: http://vismod.media.mit.edu/pub/ looks useful.
  # "RADAR, index $1"

  # a problem is changing the command language, in which case - should
  # developing backward compatibility mappings.


}

1;
