package Corpus;

use BOSS::Config;
use Corpus::ModManager;
use Corpus::Router;
use Corpus::Sources;
use Manager::Dialog qw (Message QueryUser);
use PerlLib::UI;
use UniLang::Util::Message;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config MyEntries MyUI MyPerlLibUI MyModManager MyRouter MySources /

  ];

sub init {
  my ($self, %args) = (shift,@_);
  $specification = "
	-l			Process log files
	-f <files>...		Process files as input
	-u [<host> <port>]	Run as a UniLang agent classifying messages
	-W [<delay>]		Exit as soon as possible (with optional delay)

	-a			Automatically classify
	-c			Semi-automatically classify
	-m			Manually classify

	-r			Read
	-s <regex>		Search
	-k [<context>]		Augment search results with all asserted knowledge
	--k2 [<context>]	Augment search results with all asserted knowledge using FreeKBS2
	-g			Only use entries classified by critic as a goal

	--senders <senders>...	Filter by these agents as Senders
	--no-sorting		Don't sort entries by date
	--direct		Include directly addressed items
	-S <text>		Similarity Search
	-C <categories>...	Search Categories
	-d <depth>		Restrict to recent
	--lt <length>		Restrict to items less than this length
	--gt <length>		Restrict to items greater than this length

	--assert <entries>...	Assert entries with similarity search

	-b			Backup class data
	-t			Use test file

	--mods <mods>...	Start Modules
";

  $self->Config
    (BOSS::Config->new
     (Spec => $specification,
      ConfFile => ""));
  my $conf = $self->Config->CLIConfig;
  # parse and load
  my @mods = ();
  if (exists $conf->{'--mods'}) {
    push @mods, @{$conf->{'--mods'}};
  }
  if (exists $conf->{'-u'}) {
    push @mods, "UniLang";
  }
  $self->MyModManager
    (Corpus::ModManager->new
     (Mods => \@mods));
  $self->MyRouter
    (Corpus::Router->new());
}

sub Execute {
  my ($self,%args) = (shift,@_);
  my $conf = $self->Config->CLIConfig;
  if (exists $conf->{'-s'} || exists $conf->{'-S'} || exists $conf->{'--assert'} || exists $conf->{'--fes'}) {
    $self->MySources(Corpus::Sources->new);
    $self->MySources->Execute;
  } elsif (exists $conf->{'-u'}) {
    $self->MyModManager->StartMods;
    $self->MyModManager->Execute;
  } elsif (exists $conf->{'-c'}) {
    $self->MyPerlLibUI
      (PerlLib::UI->new
       (Menu => [
		 "Main Menu", [
			       "ACLs", "ACLs",
			      ],
		 "ACLs", [
			  "Show Rules", "Show Rules",
			  "Add Rule", "Add Rule",
			  "Remove Rule", "Remove Rule",
			 ],
		],
	CurrentMenu => "Main Menu"));
    Message(Message => "Starting Event Loop...");
    $self->MyPerlLibUI->BeginEventLoop;
  }
}

1;
