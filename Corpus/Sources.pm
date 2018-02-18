package Corpus::Sources;

use Capability::SentenceSimilarity;
use Capability::TextClustering;
use Corpus::AssertionTool;
use KBS::Util;
use KBS2::Client;
use Manager::Dialog qw(QueryUser);
use PerlLib::MySQL;
use PerlLib::Util;
use String::Similarity;
use UniLang::Util::TempAgent;

use Data::Dumper;
use Lingua::EN::Sentence;
use Text::Conversation;
use Text::Similarity::Overlaps;
use XML::Twig;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / Items Entries Twig MyMySQL MyTextSim MyTempAgent
   AssertedKnowledge AssertionTool Graph MyClient /

  ];

sub init {
  my ($self,%args) = @_;
  # $self->IndexLocation($args{IndexLocation});
  $self->MyMySQL
    (PerlLib::MySQL->new
     (
      DBName => "unilang",
     ));
  $self->AssertedKnowledge({});
}

sub ProcessTextFile {
  # Add a feature to corpus or whatever, that is able to index various
  # "requirements" like files, and then destroy them.
}

sub TopicDetectionAndTracking {
  my ($self,%args) = @_;
  # several  entries  will  often   be  one  the  same  subject.   for
  # classification purposes it will be necessary to break these apart
  # and possibly ocnsider as a single entry.

  # Corpus  should be  sure to  do  things linearly.   That way,  when
  # manually  classifying  things,  we  can  assert  a  "continuation"
  # between entries if they represent the same topic.
}

sub Chunk {
  # Corpus must first chunk, then classify.
}

sub ProcessComplexStatement {
  # Corpus needs  a feature where it can  automatically handle complex
  # statements,  as well  as automatic  classification, and  lastly, a
  # measure  of when something  is done  being classified.   It should
  # also  allow reclassification  using inherent  distinctions present
  # after the addition of new classes.
}

sub CleanUpEntry {
  # Corpus might well take into consideration that mispellings tend to
  # before the user hits return, since often they don\'t check.
}

sub TDTDynamicProgramming {
  # Corpus can concatenate two entries in a row and see how much sense
  # it makes as a test when a connection is suspected.
}

sub TDTDateEvidence {
  # You can  use typing speed  to (help) classify related  thoughts in
  # CORPUS.
}

sub TDTConversationRules {
  # Of course,  make sure  to use Conversation  perl module  in corpus
  # analysis of unilang.xm
}


sub Analyze {
  my ($self,%args) = @_;
  #   $self->UI(Corpus::UI->new());
  #   $self->UI->Load(Entries => $self->Entries);
  #   $self->UI->InteractivelyClassify();
}

sub Execute {
  my ($self,%args) = @_;
  my $conf = $UNIVERSAL::corpus->Config->CLIConfig;
  if (exists $conf->{'-v'}) {
    require Ubigraph;
    $self->Graph(Ubigraph->new);
  }
  if (exists $conf->{'-d'}) {
    $args{Depth} = $conf->{'-d'};
  }
  $self->Entries($self->ListRecentItems(Depth => $args{Depth}));
  if (exists $conf->{'-b'}) {
    $self->BackupClasses;
  }
  if (exists $conf->{'-a'}) {
    $self->Analyze(%args);
  }
  if (exists $conf->{'-r'}) {
    $self->Read(%args);
  }
  if (exists $conf->{'-s'}) {
    $args{Regex} = $conf->{'-s'};
    if (exists $conf->{'-k'}) {
      $self->LoadAssertedKnowledge
	(Context => $conf->{'-k'});
    } elsif (exists $conf->{'--k2'}) {
      $self->LoadAssertedKnowledgeKBS2
	(Context => $conf->{'--k2'});
    }
    foreach my $entry (@{$self->Search(%args)}) {
      if ($entry->{Contents} !~ /^\S+,/ or exists $conf->{'--direct'}) {
	print "'".DumperQuote($entry->{Contents})."'\n";
	if (exists $conf->{'-k'}) {
	  print join
	    ("",
	     map {"\t".
		    RelationToString
		      (
		       Relation => $_,
		       Type => "Emacs",
		      )
			."\n"}
	     @{$self->GetAssertedKnowledgeForEntryID(ID => $entry->{ID})});
	}
      }
    }
  }
  if (exists $conf->{'-S'}) {
    print Dumper($self->SimilaritySearch(String => $conf->{'-S'}));
  }
  if (exists $conf->{'-u'}) {
    $self->UniLangInterface;
  }
  if (exists $conf->{'--assert'}) {
    $self->AssertionTool
      (Corpus::AssertionTool->new(Sources => $self));
    $self->AssertionTool->Execute;
  }
}

sub LoadAssertedKnowledge {
  my ($self,%args) = @_;
  my $conf = $args{Conf} || $UNIVERSAL::corpus->Config->CLIConfig;
  if (! $self->MyTempAgent) {
    $self->MyTempAgent(UniLang::Util::TempAgent->new);
  }
  my $context = defined $args{Context} ? $args{Context}." " : "";
  my $contents = "${context}all-asserted-knowledge";
  my $message = $self->MyTempAgent->MyAgent->QueryAgent
    (
     Receiver => "KBS",
     Contents => $contents,
     Data => {_DoNotLog => 1},
    );
  my $c = $message->Contents;
  $VAR1 = undef;
  eval $c;
  my $rel = $VAR1;
  $VAR1 = undef;
  foreach my $entry (@$rel) {
    foreach my $item (@$entry) {
      if ($item =~ /^\d+$/) {
	if (! exists $self->AssertedKnowledge->{$item}) {
	  $self->AssertedKnowledge->{$item} = [];
	}
	if (exists $conf->{'-g'}) {
	  if ($entry->[0] ne "critic-unilang-classification") {
	    push @{$self->AssertedKnowledge->{$item}}, $entry;
	  }
	} else {
	  push @{$self->AssertedKnowledge->{$item}}, $entry;
	}
      }
    }
  }
}

sub LoadAssertedKnowledgeKBS2 {
  my ($self,%args) = @_;
  my $conf = $args{Conf} || $UNIVERSAL::corpus->Config->CLIConfig;
  my $context = $args{Context} || 'default';
  if (! $self->MyClient) {
    $self->MyClient
      (KBS2::Client->new
       (
	Context => $context,
	Debug => $args{Debug},
       ));
  }
  my $message = $self->MyClient->Send
    (
     QueryAgent => 1,
     Command => "all-asserted-knowledge",
     Context => $context,
    );
  my $assertions = [];
  if (defined $message) {
    $assertions = $message->{Data}->{Result};
  }
  print Dumper({Assertions => $assertions});
  die;
  my $c = $message->Contents;
  $VAR1 = undef;
  eval $c;
  my $rel = $VAR1;
  $VAR1 = undef;
  foreach my $entry (@$rel) {
    foreach my $item (@$entry) {
      if ($item =~ /^\d+$/) {
	if (! exists $self->AssertedKnowledge->{$item}) {
	  $self->AssertedKnowledge->{$item} = [];
	}
	if (exists $conf->{'-g'}) {
	  if ($entry->[0] ne "critic-unilang-classification") {
	    push @{$self->AssertedKnowledge->{$item}}, $entry;
	  }
	} else {
	  push @{$self->AssertedKnowledge->{$item}}, $entry;
	}
      }
    }
  }
}

sub GetAssertedKnowledgeForEntryID {
  my ($self,%args) = @_;
  return $self->AssertedKnowledge->{$args{ID}} || [];
}

sub ListRecentItems {
  my ($self,%args) = @_;
  my $conf = $args{Conf} || $UNIVERSAL::corpus->Config->CLIConfig;
  my $goals = {};
  my @senders = exists $conf->{'--senders'} ? @{$conf->{'--senders'}} : qw(UniLang-Client Manager Recovery-FRDCSA UniLang-IRC-Bot Emacs-Client PSE-X);
  my $approvedsenders = "(".join(" or ",map {"Sender='$_'"} @senders).")";
  my $request;
  if (exists $conf->{'-g'} and exists $conf->{'-k'}) {
    if (! $self->MyTempAgent) {
      $self->MyTempAgent(UniLang::Util::TempAgent->new);
    }
    my $context = $conf->{'-k'} or "default";
    my $message = $self->MyTempAgent->MyAgent->QueryAgent
      (
       Receiver => "KBS",
       Contents => "$context query (\"critic-unilang-classification\" ?X \"goal\")",
       Data => {
		_DoNotLog => 1,
	       },
      );
    my $data = DeDumper($message->Contents);
    my @ids;
    foreach my $key (keys %$data) {
      my $id = $data->{$key}->[1];
      $goals->{$id} = 1;
      push @ids, $id;
    }
    $request = "select * from messages where ".join(" or ", map {"ID='$_'"} @ids)." order by ID DESC;";
  } else {
    if (exists $conf->{'--no-sorting'}) {
      $request = "select * from messages where $approvedsenders and Contents != 'Register' order by ID DESC";
    } else {
      $request = "select * from messages where $approvedsenders and Contents != 'Register' order by Date DESC";
    }
  }
  # or Sender='Emacs-Client'
  if ($args{Depth} and ! exists $conf->{'-g'}) {
    $request .= " limit $args{Depth}";
  }
  my $ret = $self->MyMySQL->Do
    (
     Statement => $request,
    );
  my @array;
  my @entries;
  foreach my $key (sort {$a <=> $b} keys %$ret) {
    my $reject = 0;
    my $length = length($ret->{$key}->{Contents});
    if ($conf->{'--gt'}) {
      if ($length <= $conf->{'--gt'}) {
	$reject = 1;
      }
    } elsif ($conf->{'--lt'}) {
      if ($length >= $conf->{'--lt'}) {
	$reject = 1;
      }
    }
    if ($reject) {
      next;
    }
    if (exists $conf->{'-g'}) {
      if (exists $goals->{$key}) {
	push @array, $ret->{$key};
      }
    } else {
      push @array, $ret->{$key};
    }
  }
  return \@array;
}

sub Read {
  my ($self,%args) = @_;
  print "Saving log\n";

  my $OUT;
  open (OUT,">/tmp/corpus");
  print OUT join("\n",@{$self->Entries});
  close (OUT);
  print "Reading log\n";
  system "cla -r /tmp/corpus";
}

sub Search {
  my ($self,%args) = @_;
  my $regex = $args{Regex};
  my @matches;
  foreach my $item (@{$self->Entries}) {
    if ($item->{Contents} =~ /$regex/i) {
      push @matches, $item;
    }
  }
  return \@matches;
}

sub PostProcess {
  # script to post process clusters since I didn't write them out in the first place
  my ($self,%args) = @_;
  my $file = $args{File};
  my %hash;
  foreach my $line (split /\n/, `cat $file`) {
    if ($line =~ /^(\S+)\s+\/\s+\/(\S+)$/) {
      if (0) {
	system "mkdirhier $2";
	system "ln -s $1 $2";
      } else {
	$hash{$1} = $2;
      }
    }
  }

  my $last = "";
  foreach my $key (sort {$hash{$a} cmp $hash{$b}} keys %hash) {
    if ($last ne $hash{$key}) {
      $last = $hash{$key};
      print "\n################################################################################\n".$last."\n";
    }
    print "+ ".`cat $key`."\n";
  }
}

sub Cluster {
  my ($self,%args) = @_;
  my $file = $args{File};
  Message(Message => "Loading messages");
  my $t = XML::Twig->new();
  my $contents = `cat $file`;
  $t->parse("<messages>\n$contents\n</messages>");
  my $root = $t->root;
  foreach my $e ($root->children) {
    push @strings, $e->first_child('contents')->text;
  }

  Message(Message => "Clustering messages");
  $UNIVERSAL::cluster = Capability::TextClustering->new();
  $UNIVERSAL::cluster->AddTexts(Texts => \@strings);
  $UNIVERSAL::cluster->GetClusters();

  Message(Message => "Outputing clusters");
}

sub SimilaritySearch {
  my ($self,%args) = @_;
  $args{Method} = "String::Similarity" if ! defined $args{Method};
  my $sim = {};
  if ($args{Method} eq "Capability::SentenceSimilarity") {
    foreach my $item (@{$self->Entries}) {
      my $contents = $item->{Contents};
      my $tmp = SentenceSimilarity(WN => 1, A => $args{String},B => $contents)->{score};
      # print Dumper([$contents,$tmp]);
      $sim->{$contents} = $tmp;
    }
  } elsif ($args{Method} eq "Text::Similarity::Overlaps") {
    $self->MyTextSim(Text::Similarity::Overlaps->new) unless $self->MyTextSim;
    foreach my $item (@{$self->Entries}) {
      my $contents = $item->{Contents};
      my $tmp = $self->Similarity($args{String},$contents);
      # print Dumper([$contents,$tmp]);
      $sim->{$contents} = $tmp;
    }
  } elsif ($args{Method} eq "String::Similarity") {
    foreach my $item (@{$self->Entries}) {
      my $contents = $item->{Contents};
      my $tmp = similarity($args{String},$contents);
      # print Dumper([$contents,$tmp]);
      $sim->{$contents} = $tmp;
    }
  }
  my @entries = sort {$sim->{$b->{Contents}} <=> $sim->{$a->{Contents}}} @{$self->Entries};
  my @results = splice @entries, 0, 10;
  my @retval;
  foreach my $entry (@results) {
    push @retval, [$entry,$sim->{$entry->{Contents}}];
  }
  return \@retval;
}

sub Similarity {
  my ($self,$a,$b) = @_;
  $self->MyTextSim->getSimilarityStrings
    (
     $self->MyTextSim->compoundify($self->MyTextSim->sanitizeString($a)),
     $self->MyTextSim->compoundify($self->MyTextSim->sanitizeString($b)),
    );
}

1;
