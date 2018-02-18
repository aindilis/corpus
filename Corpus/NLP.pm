package Corpus::NLP;

use Manager::Dialog qw(QueryUser);

use System::Assert;


use Data::Dumper;
use Tie::MLDBM;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / StorageFile Cache /

  ];

sub init {
  my ($self, %args) = @_;
  $self->StorageFile($args{StorageFile} || "nlp.db");
  my $storagefile = $self->StorageFile;
  tie my %cache, 'Tie::MLDBM',
    {
     'Serialise' =>  'Storable',
     'Store'     =>  'DB_File'
    }, $storagefile, O_CREAT|O_RDWR, 0640 or die $!;
  $self->Cache(\%cache);
}

sub Analyze {
  my ($self, %args) = @_;
  if (! exists $self->Cache->{$args{Text}}) {
    my $analysis = {};
    $analysis->{} = Dumper();
  } else {
    # based on what we know about this, perform various tests
  }
}

1;
