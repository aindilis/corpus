package Corpus::Auto::AICategorizer;

# this is an adaptation of the auto-debtags script to index the
# contents of sourceforge and freshmeat as well

use BOSS::Config;
use Corpus::Sources;
use MyFRDCSA;
use PerlLib::MySQL;

use AI::Categorizer;
use AI::Categorizer::Learner::NaiveBayes;
use AI::Categorizer::Learner::SVM;
use Data::Dumper;
use IO::File;
use MIME::Base64;

sub init {
  my ($self,%args) = @_;
  $UNIVERSAL::systemdir = ConcatDir(Dir("internal codebases"),"corpus");
  my $learnertype = "SVM";
  my $identifier = "entries";
  $statepath = "$UNIVERSAL::systemdir/data/auto/AICategorizer/$identifier-$learnertype";

  # Create the Learner, and restore state if need be
  my $learner;
  my $needstraining;

  if ($learnertype eq "SVM") {
    if (-d $statepath) {
      print "Restoring state\n";
      $learner = AI::Categorizer::Learner::SVM->restore_state($statepath);
    } else {
      $learner = AI::Categorizer::Learner::SVM->new();
      $needstraining = 1;
    }
  } elsif ($learnertype eq "NaiveBayes") {
    if (-d $statepath) {
      print "Restoring state\n";
      $learner = AI::Categorizer::Learner::NaiveBayes->restore_state($statepath);
    } else {
      $learner = AI::Categorizer::Learner::NaiveBayes->new();
      $needstraining = 1;
    }
  }

  if ($needstraining) {
    # LOAD THE SOURCE DATA
    my $categories = $retval->{Categories};
    my $results = $retval->{Results};

    my $sources = Corpus::Sources->new();
    $sources->Entries
      ($sources->ListRecentItems
       (Conf => {}));

    foreach my $entry (@{$sources->Entries}) {
      if ($entry->{Contents} =~ /^(\S+),\s*(.+)$/s) {
	Add($1,$2);
      } else {
	Add("unknown",$entry->{Contents});
      }
    }

    # CREATE CATEGORIES
    my @categorynames = keys %$categories;
    my @categories;
    my %mycategories;
    foreach my $categoryname (@categorynames) {
      my $cat = AI::Categorizer::Category->by_name(name => $categoryname);
      $mycategories{$categoryname} = $cat;
      push @categories, $cat;
    }

    # load "documents"
    # randomly add documents to both the categories and knowledge sets
    my @documents;
    my @test;
    my @train;

    my $traincutoff;
    if (exists $conf->{'--traintest'}) {
      print "Doing a train test\n";
      $percentage = $conf->{'--traintest'};
      die "Invalid percentage: $percentage\n" unless ($percentage >= 0 and $percentage <= 100);
    }

    my $i = 0;
    foreach my $key (keys %$results) {
      if (! ($i % 100)) {
	print $i."\n";
      }
      ++$i;
      push @documents, $d;
      if (defined $percentage and int(rand(100)) > $percentage) {
	my $d = AI::Categorizer::Document->new
	  (name => $results->{$key}->{ID},
	   content => $results->{$key}->{Contents});
	push @test, $d;
	#     } else {
	#       # add $d to a random category  << What the heck is this all about?
	#       my $category = $categories[int(rand(scalar @categories))];
	#       my $d = AI::Categorizer::Document->new
	# 	(name => $results->{$key}->{ID},
	# 	 content => $results->{$key}->{Contents},
	# 	 categories => $results->{$key}->{Categories});
	#       $category->add_document($d);
	#       push @train, $d;
      } else {
	my $d = AI::Categorizer::Document->new
	  (name => $results->{$key}->{ID},
	   content => $results->{$key}->{Contents},
	   categories => $results->{$key}->{Categories});
	foreach my $catname (keys %{$results->{$key}->{Categories}}) {
	  $mycategories{$catname}->add_document($d);
	}
	push @train, $d;
      }
    }

    # create a knowledge set
    my $k = new AI::Categorizer::KnowledgeSet
      (categories => \@categories,
       documents => \@train);

    print "Training, this could take some time...\n";
    $learner->train(knowledge_set => $k);
    $learner->save_state($statepath) if $statepath;
  }

  # LOAD TARGET
  my $tgt = $conf->{'--target'};
  my $tgtfile = "$UNIVERSAL::systemdir/Folksonomy/Target/$tgt.pm";
  if (-f $tgtfile) {
    require $tgtfile;
  } else {
    die "No such tgtfile exists: $tgtfile\n";
  }
  my $target = "Folksonomy::Target::$tgt"->new
    (
     Filters => $conf->{'--filters'},
    );
  $target->GetUnlabelledData
    (
     Tiny => $conf->{'--tiny'},
    );


  # CATEGORIZE AND SAVE RESULTS
  my $mysql = PerlLib::MySQL->new
    (DBName => "folksonomy");
  if (exists $conf->{'--to-text'}) {
    my $fn = "$UNIVERSAL::systemdir/data/results/$identifier";
    if (! -f $fn) {
      mkdir $fn;
    }
  }
  my $catids = {};
  my $nameids = {};
  my $runid = GetRunID;
  while ($target->HasNext) {
    my $item = $target->GetNext;
    Categorize(Item => $item) if defined $item;
  }
}

sub Categorize {
  my %args = @_;
  my $d = $args{Item}->{D};
  # check whether this has already been categorized
  my $name = $d->name;
  my $encoded = encode_base64($name);
  my $fn = "$UNIVERSAL::systemdir/data/results/$identifier/$encoded";
  my $needscategorization = 0;
  my $answer;
  if (exists $conf->{'--to-text'}) {
    if (-f $fn) {
      # $answer = stuff
    }
  } else {
    if (0) {
      # $answer = stuff
    }
  }
  if (! defined $answer) {
    my $hypothesis = $learner->categorize($d);
    my $cats = $args{Item}->{Categories};
    $answer = {
	       Name => $name,
	       Contents => $args{Item}->{Contents},
	       EstimatedCats => [$hypothesis->categories],
	       ActualCats => [map {$_->name} @$cats],
	      };
    if (exists $conf->{'--to-text'}) {
      $fh = new IO::File ">$fn";
      if (defined $fh) {
	print $fh Dumper($answer);
	$fh->close;
      }
    } else {
      WriteToDB($answer);
    }
  }
  # now we have the answer!
  # what to do with it...
  print Dumper($answer);
}

sub WriteToDB {
  # now we add this to the database
  my $answer = shift;
  my $nameid = GetNameID($answer->{Name});
  # first retrieve all the instances of the cats
  my $cats = $answer->{EstimatedCats};
  my $count = scalar @$cats;
  $mysql->Do
    (Statement => "insert into count values ('$runid', '$nameid', '$count')");
  foreach my $cat (@$cats) {
    my $tagid = GetCatID($cat);
    $mysql->Do
      (Statement => "insert into entries values (NULL, '$runid', '$nameid', '$tagid')");
  }
}

sub GetRunID {
  my $quotedsource = $mysql->Quote($conf->{'--source'});
  my $quotedtarget = $mysql->Quote($conf->{'--target'});
  my $quotedlearner = $mysql->Quote($conf->{'--learner'});
  $mysql->Do
    (Statement => "insert into runs values (NULL,$quotedsource,$quotedtarget,$quotedlearner,NOW())");
  return $mysql->InsertID(Table => "runs");
}

sub GetNameID {
  my $name = shift;
  if (! exists $nameids->{$name}) {
    my $quotedname = $mysql->Quote($name);
    my $res = $mysql->Do
      (Statement => "select * from names where Name=$quotedname");
    if (keys %$res) {
      foreach my $key (keys %$res) {
	$nameids->{$name} = $key;
      }
    } else {
      my $res2 = $mysql->Do
	(Statement => "insert into names values (NULL,$quotedname)");
      $nameids->{$name} = $mysql->InsertID(Table => "names");
    }
  }
  return $nameids->{$name};
}

sub GetCatID {
  my $cat = shift;
  if (! exists $catids->{$cat}) {
    my $quotedtag = $mysql->Quote($cat);
    my $res = $mysql->Do
      (Statement => "select * from tags where Tag=$quotedtag");
    if (keys %$res) {
      foreach my $key (keys %$res) {
	$catids->{$cat} = $key;
      }
    } else {
      my $res2 = $mysql->Do
	(Statement => "insert into tags values (NULL,$quotedtag)");
      $catids->{$cat} = $mysql->InsertID(Table => "tags");
    }
  }
  return $catids->{$cat};
}

sub Add {
  my ($self,$id,$category,$contents) = @_;
  $self->Results->{$i} = {
			  ID => $id,
			  Contents => $contents,
			  Categories => [$category],
			 };
}

1;
