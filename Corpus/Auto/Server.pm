package Corpus::Server;

# This manages starting, stopping, and calls to a rainbow classification server

use Manager::Dialog qw (ApproveCommands);

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '1.00';

use Class::MethodMaker new_with_init => 'new',
  get_set => [ qw / Server / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Server($args{Server});
}

1;
