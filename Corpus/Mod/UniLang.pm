package Corpus::Mod::UniLang;

use Data::Dumper;
use Manager::Dialog qw(Message);
use UniLang::Agent::Agent;
use UniLang::Util::Message;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / UniLangAgent /

  ];

sub init {
  my ($self,%args) = (shift,@_);
}

sub Start {
  my ($self,%args) = (shift,@_);
  my $conf = $UNIVERSAL::corpus->Config->CLIConfig;
  $self->UniLangAgent
    (UniLang::Agent::Agent->new
     (Name => "Corpus",
      ReceiveHandler => sub {$self->ReceiveMessage(@_)}));
  $self->UniLangAgent->DoNotDaemonize(1),
  $self->UniLangAgent->Register
    (Host => defined $conf->{-u}->{'<host>'} ?
     $conf->{-u}->{'<host>'} : "localhost",
     Port => defined $conf->{-u}->{'<port>'} ?
     $conf->{-u}->{'<port>'} : "9000");
}

sub Execute {
  my ($self,%args) = (shift,@_);
  if (exists $UNIVERSAL::corpus->Config->CLIConfig->{'-W'}) {
    $self->UniLangAgent->Deregister;
    exit(0);
  }
  $self->UniLangAgent->Listen(TimeOut => $args{TimeOut});
}

sub ReceiveMessage {
  my ($self,%args) = (shift,@_);
  my $c = $args{Message}->Contents;
  if ($c) {
    if ($c =~ /^(quit|exit)$/) {
      $self->UniLangAgent->Deregister;
      exit(0);
    } elsif ($c =~ /^route (.*)$/) {
      $self->SendMessage
	(Contents => $UNIVERSAL::corpus->MyRouter->Route
	 (Message => $args{Message}));
    } elsif ($c =~ /^similarity-search (.+)$/) {
      my $searchstring = $1;
      if (! $UNIVERSAL::corpus->MySources) {
	$UNIVERSAL::corpus->MySources(Corpus::Sources->new);
	$UNIVERSAL::corpus->MySources->Entries($UNIVERSAL::corpus->MySources->ListRecentItems(Depth => $args{Depth}));
      }
      my $results = $UNIVERSAL::corpus->MySources->SimilaritySearch
	(String => $searchstring);
      my $new = UniLang::Util::Message->new
	(Sender => "Corpus",
	 Receiver => $args{Message}->Sender,
	 Date => $self->UniLangAgent->GetDate,
	 Contents => "",
	 Data => Dumper({
			 _DoNotLog => 1,
			 Results => $results,
			}));
      $self->UniLangAgent->Send
	(Handle => $self->UniLangAgent->Client,
	 Message => $new);
    } else {
      print "Got but don't know what to do with it: $c\n";
      $self->SendMessage
	(Contents => "Received: $c");
    }
  }
}

sub SendMessage {
  my ($self,%args) = (shift,@_);
  my $new = UniLang::Util::Message->new
    (Sender => "Corpus",
     Receiver => "UniLang-Client",
     Date => $self->UniLangAgent->GetDate,
     Contents => $args{Contents});
  $self->UniLangAgent->Send
    (Handle => $self->UniLangAgent->Client,
     Message => $new);
}

1;
