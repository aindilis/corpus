package Corpus::ModManager;

use Manager::Dialog qw(Message);
use PerlLib::Collection;

use Data::Dumper;
use Time::HiRes qw( usleep );

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw { Mods InvokedMods }

  ];

sub init {
  my ($self,%args) = (shift,@_);
  Message(Message => "Starting ModManager...");
  $self->InvokedMods
    ($args{Mods} || []);
  $self->Mods
    (PerlLib::Collection->new
     (Type => "Corpus::Mod"));
  $self->Mods->Contents({});
  foreach my $mod (@{$self->InvokedMods}) {
    if (OneOf(Item => $mod,
	      Set => \@registeredmods)) {
      require "Corpus/Mod/$mod.pm";
      my $a = "Corpus::Mod::$mod"->new();
      $self->Mods->Add
	($mod => $a);
    }
  }
}

sub OneOf {
  return 1;
}

sub StartMods {
  my ($self,%args) = (shift,@_);
  Message(Message => "Starting mods...");
  foreach my $mod ($self->Mods->Values) {
    $mod->Start;
  }
}

sub StopMods {
  my ($self,%args) = (shift,@_);
  Message(Message => "Stopping mods...");
  foreach my $mod ($self->Mods->Values) {
    $mod->Stop;
  }
}

sub Execute {
  my ($self,%args) = (shift,@_);
  while (1) {
    # for each of the other mods listen for them
    usleep(10000);
    foreach my $mod ($self->Mods->Values) {
      $mod->Execute(TimeOut => 1);
    }
  }
}

1;
