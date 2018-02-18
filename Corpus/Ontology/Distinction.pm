package Corpus::Ontology::Distinction;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / Name Description InputVector /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Description($args{Description});
  $self->Name($args{Name});
  $self->InputVector($args{InputVector});
}

1;
