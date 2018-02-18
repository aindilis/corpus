package Corpus::Ontology::Class;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw /  /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Name($args{Name});
}

1;
