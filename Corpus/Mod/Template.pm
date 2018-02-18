package Corpus::Mod::Template;

use Data::Dumper;
use Manager::Dialog qw(Message);
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
}

sub Stop {
  my ($self,%args) = (shift,@_);
}

sub Execute {
  my ($self,%args) = (shift,@_);
}

sub Send {
  my ($self,%args) = (shift,@_);

}

sub Receive {
  my ($self,%args) = (shift,@_);
}

sub DESTROY {
  my ($self,%args) = (shift,@_);
}

1;

sub UniLangInterface {
  my ($self,%args) = (shift,@_);
  # One  possible thing  to do  is  write something  for UniLang  that
  # interfaces with the corpus classifier.

  # start acting as a classification server
}

sub RouteMessage {
  my ($self,%args) = (shift,@_);
  my $message = $args{Message};

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

1;
