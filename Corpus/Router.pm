package Corpus::Router;

use KBS::Util qw(PrettyPrintSubL);
use PerlLib::Collection;
use PerlLib::MySQL;

use Data::Dumper;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / Classifiers MyMySQL /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Classifiers
    ($args{Classifiers} ||
     PerlLib::Collection->new
     (Type => "Corpus::Auto"));
  $self->MyMySQL
    (PerlLib::MySQL->new
     (DBName => "unilang"));
}

sub Route {
  my ($self,%args) = (shift,@_);
  my $m = $args{Message};
  # print Dumper($m);
  if (0) {
    my $debug = 0;
    if ($m->Contents =~ /^route (\d+)$/) {
      my $id = $1;
      # lookup this message and send the contents to formalize
      my $res = $self->MyMySQL->Do
	(
	 Statement => "select * from messages where ID=$id",
	 AOH => 1,
	);
      my $contents = $res->[0]->{Contents};
      print Dumper($contents) if $debug;
      if (1) {
	my $agent = $UNIVERSAL::corpus->MyModManager->Mods->Contents->{UniLang}->UniLangAgent;
	my $res = $agent->QueryAgent
	  (
	   Receiver => "Formalize",
	   Contents => $contents,
	  );
	my $ref = ref $res;
	print Dumper($ref) if $debug;
	if ($ref eq "UniLang::Util::Message") {
	  my $string = $res->Data->{Results}->[0]->Contents;
	  $string =~ s/^(\d+)\s+//s;
	  print Dumper($string) if $debug;
	  print Dumper
	    (PrettyPrintSubL
	     (String => $string));
	}
      }
    }
  }
  # We are to figure out to which agent to send this message.  Complex
  # problem.  Basic algorithm is as follows.

  # If it  is specifically addressed  to an agent, well  that's pretty
  # simple

  # Still  go  through the  motions,  simply  adding  to the  evidence
  # processor that it was addressed to the agent.

  # evidence processor  seeks to prove  what the message is  with high
  # confidence and send it on its way

  # A generic response agent, working  either for the agent or corpus,
  # is in  place for every agent.   This simply looks at  a variety of
  # factors and responds on that basis.

  # various feature learners are in  place to detect aspects about the
  # message that may make routing  it to one place significant.  Also,
  # trying  to determine  who  or what  wrote  the message  is a  high
  # priority.  It  would simplify  things to include  that information
  # from the  get-go, yet  it would make  it more specific.   In other
  # words, this whole process is a form of speculation.

  # the  message may  be tagged  with various  helpers,  like important,
  # dangerous, fragile, time critical, etc,etc,etc.

  # if no tag has been registered,  they are not treated like (not tag),
  # but like (unknown tag)

  # some messages are intended for multiple systems

  # so the system  can work as follows.  It can send  the message to the
  # respective  agent  with  an  instruction  to try  to  formalize  the
  # message, and tell us more about it.

  # we  don't  want to  do  this very  often  as  this causes  bandwidth
  # problems, etc.

  # from these  responses, a better  model is made.  The  agents writing
  # back can say if they accept and/or reject the message.

  # various  translators,  language recognizers,  etc,  are employed  as
  # needed to route the message.

  # if  the  message seems  important,  and  crosses  some threshold  of
  # importance, and  a human is  available, if the message  appears with
  # high confidence to not be time-critical, the classification question
  # is queued to the human.

  # if the human is unavailable, the  system may have to make a decision
  # for them.

  # yet another method  of functioning might be to  know various needs
  # of each of the systems, and what they are anticipating to receive.
  # Some how viterbi models seem appropriate.
}

sub IntegrateEvidence {
  my ($self,%args) = (shift,@_);
  # the evidence system is mainly about trying to prove that a message
  # is being routed to the correct  location, and if not, that no real
  # damage is being done.
}

sub IntegrateEvidenceFromClassifiers {
  my ($self,%args) = (shift,@_);
}

sub IntegrateEvidenceFromDispatchers {
  my ($self,%args) = (shift,@_);
}

sub Dispatcher {
  my ($self,%args) = (shift,@_);
}

sub QueryAgentsAboutICL {
  # remember the  corpus system  is really the  front end  to UniLang,
  # should have  multiple sources of evidence for  choosing a message,
  # also  should have  a  protocol for  querying  agents whether  they
  # recognize and/or accept the ICL mesg.  Also, look in logs for more
  # on how to do this part of the unilang classification
}

1;
