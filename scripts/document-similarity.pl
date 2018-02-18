#!/usr/bin/perl -w

# this is a system to recommend results

use BOSS::Config;
use Manager::Dialog qw(Approve ChooseByProcessor SubsetSelect QueryUser);
use PerlLib::Collection;
use PerlLib::HTMLConverter;
use PerlLib::MySQL;
use PerlLib::UI;
use KBFS::Cache;

use YAML;
use IO::File;
use Parse::Debian::Packages;
use Data::Dumper;

use Text::Wrap;


my $specification = "
	-m			Use barely any systems
	-a			Use all systems

	-s <file>		Purpose file
";

my $config = BOSS::Config->new
  (Spec => $specification,
   ConfFile => "");
my $conf = $config->CLIConfig;

my $storagefile = $conf->{'-s'} || "data/input/purposes.pl";

my @order;
my $startingweight = 10;
my $currentsystem = "";
my $iorder = {};
my $docs = {};
my $docratings = {};
my $termratings = {};
my $scoring = {};

my $purposes = PerlLib::Collection->new
  (
   Type => "String",
   StorageFile => $storagefile,
  );
$purposes->Load;

my $selectedpurposes = {};
my $tokens = {};
my $itokens = {};
my $tf = {};
my $idf = {};
my $tfidf = {};
my $cache;
my $converter;
my $mainmenu = PerlLib::UI->new
  (Menu => [
	    "Main Menu", [
			  "Purposes",
			  "Purposes",

			  "Navigation",
			  "Navigation",

			  "Rate system",
			  sub {RateCurrentSystem()},

			  "Reorder",
			  sub {Reorder()},

			  "Queue system",
			  sub {QueueSystem()},

			  "Show scores for system",
			  sub {ShowScoresForSystem()},

			  "Show tokens for purpose",
			  sub {ShowTokensForPurpose()},

			  "Generate Top Systems",
			  sub {GenerateTopSystems()},
			 ],
	    "Purposes", [
			  "Select purposes",
			  sub {SelectPurposes()},

			  "Add purpose",
			  sub {AddPurpose()},

			  "Remove purposes",
			  sub {RemovePurposes()},
			],
	    "Navigation", [
			  "First system",
			  sub {FirstSystem()},

			  "Previous page",
			  sub {PreviousPage()},

			  "Previous system",
			  sub {PreviousSystem()},

			  "Jump to system",
			  sub {JumpToSystem()},

			  "Next system",
			  sub {NextSystem()},

			  "Next page",
			  sub {NextPage()},

			  "Last system",
			  sub {LastSystem()},
			  ],
	   ],
   CurrentMenu => "Main Menu");
my $closed;
my $fh;

sub Init {
  $selectedpurposes->{$purposes->GetSortedValues->[0]} = 1 if ! $purposes->IsEmpty;

  print "Loading the UniLang data\n";
  my $mysql = PerlLib::MySQL->new
    (DBName => "unilang");
  # load results from database for use in learning
  my $statement;
  if (exists $conf->{'-a'}) {
    $statement = "select * from messages";
  } elsif (exists $conf->{'-m'}) {
    $statement = "select * from messages limit 300",
  } else {
    $statement = "select * from messages where Sender='UniLang-Client'",
  }
  my $docs2 = $mysql->Do
    (Statement => $statement,
     KeyField => "ID");
  foreach my $key (keys %$docs2) {
    my $name = $docs2->{$key}->{ID};
    my @content;
    push @content, $docs2->{$key}->{Contents} if defined $docs2->{$key}->{Contents};
    if (@content) {
      $docs->{$name} = {
			ID => $name,
			Contents => join(" ",@content),
		       };
    }
  }

  print "Getting tokens\n";
  # now compute tfidf
  foreach my $doc (keys %$docs) {
    foreach my $token (GetTokens($docs->{$doc}->{Contents})) {
      $tokens->{$token}->{$doc}++;
      $itokens->{$doc}->{$token}++;
    }
  }
  print "Computing TFIDF\n";
  foreach my $token (keys %$tokens) {
    my $numdocs = scalar keys %$itokens;
    my $numdocscontainingterm = scalar keys %{$tokens->{$token}};
    # $idf->{$token} = log ($numdocs/$numdocscontainingterm);
    $idf->{$token} = ($numdocs/$numdocscontainingterm);
    foreach my $doc (keys %{$tokens->{$token}}) {
      my $length = scalar keys %{$itokens->{$doc}};
      if ($length < 20) {
	$length = 20;
      }
      $tf->{$token}->{$doc} = $tokens->{$token}->{$doc} / $length;
      $tfidf->{$token}->{$doc} = $tf->{$token}->{$doc} * $idf->{$token};
    }
  }
}

sub GetTokens {
  map {lc($_)} split /\W+/, (shift);
}

sub Score {
  my $item = shift;
  if (exists $scoring->{$item}) {
    return $scoring->{$item};
  }
  return 0;
}

sub Reorder {
  print "Reordering\n";
  $scoring = {};
  foreach my $purpose (keys %$selectedpurposes) {
    foreach my $token (keys %{$termratings->{$purpose}}) {
      if (exists $idf->{$token} and $idf->{$token} > 100) {
	foreach my $doc (keys %{$tokens->{$token}}) {
	  $scoring->{$doc} += $termratings->{$purpose}->{$token} * $tfidf->{$token}->{$doc};
	}
      }
    }
  }
  # sort by scoring of documents
  @order = sort {Score($b) <=> Score($a)} keys %$docs;
  my $i = 0;
  foreach my $item (@order) {
    $iorder->{$item} = $i++;
  }
}

sub SelectPurposes {
  my $hash = {};
  foreach my $entry (SubsetSelect
    (Set => $purposes->GetSortedValues,
     Selection => $selectedpurposes)) {
    $hash->{$entry} = 1;
  }
  $selectedpurposes = $hash;
  RebuildTermRatings();
}

sub AddPurpose {
  my $newpurpose = QueryUser("Purpose?");
  if (Approve("Add this purpose?")) {
    $purposes->AddAutoIncrement
      (Item => $newpurpose);
    $purposes->Save;
  }
}

sub RemovePurposes {
  my $hash = {};
  $purposes->SubtractByValue
    ($purposes->SelectValuesByProcessor
     (Processor => sub {$_}));
  $purposes->Save;
}

sub min {
  my ($a, $b) = @_;
  return $a if ($a < $b);
  $b;
}

sub max {
  my ($a, $b) = @_;
  return $a if ($a > $b);
  $b;
}

sub DisplaySystem {
  my $system = shift;
  my $score =  exists $scoring->{$system} ? $scoring->{$system} : "0";
  my $summary = $docs->{$system}->{Contents};
  my $count;
  my $rating;
  foreach my $purpose (keys %$selectedpurposes) {
    if (exists $docratings->{$purpose}->{$system}) {
      $rating += $docratings->{$purpose}->{$system};
      ++$count;
    }
  }
  if ($count) {
    $rating /= $count;
    $rating = sprintf("%1.1f",$rating);
  } else {
    $rating = "";
  }
  $summary =~ s/[\n\r]+/ /g;
  $summary =~ s/(.{80}).*/$1/;
  my $txt = $system;
  $txt =~ s/\s+//g;
  $txt =~ s/\#.*//;

  my $retval .= sprintf("%s %i %-15s %3.3f",$rating,$iorder->{$system},$txt,$score);
  if ($_ eq $currentsystem) {
    $retval .= "\n".wrap("\t","\t", $docs->{$currentsystem}->{Contents});
  } else {
    $retval .= " ".sprintf("%80s",$summary);
  }
  return $retval;
}

sub RateCurrentSystem {
  # just jump to the next system for now
  my $rating = QueryUser("Rating for current system");
  if ($rating =~ /[\-\.\d]+/) {
    AdjustRatings($rating);
  }
  NextSystem();
}

sub QueueSystem {
  print "Queue System: $currentsystem\n";
}

sub ShowScoresForSystem {
  print "Showing Scores for System: $currentsystem\n";
  # we want to show each word in the description and how much its worth to the total

  # okay the score for the system should be the sum of the values for
  # the terms in it, divided by length of the document

  # so what we want is to compute for each token, its score / length of the document

  # where are the contents of the current system
  foreach my $token (GetTokens($docs->{$currentsystem}->{Contents})) {
    my $score = 0;
    foreach my $purpose (keys %$selectedpurposes) {
      my $a = $termratings->{$purpose}->{$token};
      my $b = $tfidf->{$token}->{$currentsystem};
      if ($a and $b) {
	# print "($a,$b)\n";
	$score +=  $a * $b;
      }
    }
    print "$token\t\t$score\n";
  }
  print "\n\n";
}

sub ShowTokensForPurpose {
  print "Showing Tokens for Purposes\n";
  # we want to show and edit the top scores for tokens
  # just show for now

  foreach my $token (GetTokens($docs->{$currentsystem}->{Contents})) {
    my $score = 0;
    foreach my $purpose (keys %$selectedpurposes) {
      my $a = $termratings->{$purpose}->{$token};
      my $b = $tfidf->{$token}->{$currentsystem};
      if ($a and $b) {
	# print "($a,$b)\n";
	$score +=  $a * $b;
      }
    }
    print "$token\t\t$score\n";
  }
  print "\n\n";
}

sub DisplayContext {
  # skip for now
  # okay we want to do
  # take the 20 systems in the vicinity of the current
  DisplayPurposes();

  my $window = 20;
  my $min;
  my $max;
  my $i = $iorder->{$currentsystem};
  if ($i < $window / 2) {
    $min = 0;
    $max = $window;
  } elsif ($i > $#order - $window / 2) {
    $min = $#order - $window;
    $max = $#order;
  } else {
    $min = $i - $window / 2;
    $max = $i + $window / 2;
  }
  my @seq = $min .. $max;
  my @res = @order[@seq];
  foreach (@res) {
    print DisplaySystem($_)."\n";
  }
  print "\n";
}

sub DisplayPurposes {
  # print Dumper($selectedpurposes)."\n";
}

sub AdjustRatings {
  my $adjustment = shift;
  foreach my $purpose (keys %$selectedpurposes) {
    $docratings->{$purpose}->{$currentsystem} = $adjustment;
  }
  # rebuild term ratings
  RebuildTermRatings();
}

sub RebuildTermRatings {
  print "Rebuilding term ratings\n";
  $termratings = {};
  foreach my $purpose (keys %$selectedpurposes) {
    foreach my $system (keys %{$docratings->{$purpose}}) {
      foreach my $token (GetTokens($docs->{$system}->{Contents})) {
	if (exists $idf->{$token} and $idf->{$token} > 100) {
	  $termratings->{$purpose}->{$token} = $docratings->{$purpose}->{$system};
	}
      }
    }
  }
  foreach my $purpose (@{$purposes->GetSortedValues}) {
    # now retrieve the purpose correctly here
    my $text = RetrieveTextForPurpose($purpose);
    foreach my $token (GetTokens($text)) {
      if (exists $idf->{$token} and $idf->{$token} > 100) {
	print "$token\t".$idf->{$token}."\n";
	$termratings->{$purpose}->{$token} = $startingweight;
      }
    }
  }
}

sub RetrieveTextForPurpose {
  my $purpose = shift;
  if ($purpose =~ /^file:\/\/(.*)$/) {
    return `cat "$1"`;
  } elsif ($purpose =~ /^http:\/\/.*$/) {
    # don't do anything for onw
    if (! defined $cache) {
      $cache = KBFS::Cache->new
	(
	 CacheDir => "/tmp/system-recommender",
	 CacheType => "web",
	);
      $converter = PerlLib::HTMLConverter->new();
    }
    my $item = $cache->CacheNewItem(URI => $purpose);
    return $converter->ConvertToTxt(Contents => $item->Contents);
  } else {
    return $purpose;
  }
}

sub NextPage {
  my $i = $iorder->{$currentsystem};
  print "$i\n";
  if (exists $order[$i + 20]) {
    $currentsystem = $order[$i + 20];
  } else {
    print "Last Page\n";
  }
}

sub NextSystem {
  my $i = $iorder->{$currentsystem};
  print "$i\n";
  if (exists $order[$i + 1]) {
    $currentsystem = $order[$i + 1];
  } else {
    print "Last System\n";
  }
}

sub PreviousSystem {
  my $i = $iorder->{$currentsystem};
  print "$i\n";
  if (exists $order[$i - 1]) {
    $currentsystem = $order[$i - 1];
  } else {
    print "First System\n";
  }
}

sub PreviousPage {
  my $i = $iorder->{$currentsystem};
  print "$i\n";
  if ($i > 0 and exists $order[$i - 20]) {
    $currentsystem = $order[$i - 20];
  } else {
    print "First Page\n";
  }
}

sub FirstSystem {
  $currentsystem = $order[0];
}

sub JumpToSystem {
  my $size = scalar @order;
  my $int = QueryUser("Jump to which of $size systems");
  if ($int =~ /^\d+$/) {
    if ($int <= $#order and $int >= 0) {
      $currentsystem = $order[$int];
    } else {
      print "out of range\n";
    }
  } else {
    print "not a number\n";
  }
}

sub LastSystem {
  $currentsystem = $order[-1];
}

sub GenerateTopSystems {
  
}

Init();
RebuildTermRatings();
Reorder();

$currentsystem = $order[0];
$mainmenu->Hooks->{Refresh} = sub {DisplayContext()};
$mainmenu->BeginEventLoop;
