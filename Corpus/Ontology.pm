package Corpus::Ontology;

use Corpus::Ontology::Class;
use Corpus::Ontology::Distinction;
use PerlLib::Collection;
use PerlLib::UI;

use GraphViz;
use Math::PartialOrder::Std;
use Math::PartialOrder::Loader;

use Class::MethodMaker new_with_init => 'new',
  get_set =>
  [

   qw / MyUI Classes Types Distinctions /

  ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->IndexLocation($args{IndexLocation});
  $self->Classes
    ($args{Classes} ||
     PerlLib::Collection->new
     (Type => "Corpus::Ontology::Class"));
  $self->Classes->Contents({}) unless
    $self->Classes->Contents;
  $self->Types
    (Math::PartialOrder::Std->new
     ({root=>'classes'}));
  $self->Distinctions
    ($args{Distinctions} ||
     PerlLib::Collection->new
     (Type => "Corpus::Ontology::Distinction"));
  $self->Distinctions->Contents({}) unless
    $self->Distinctions->Contents;
}

sub AddClass {
  my ($self,%args) = (shift,@_);
  if ($args{Class}) {
    $self->Classes->Add($args{Class}->Name, $args{Class});
    $self->Types->add($args{Class}->Name,map {$_->Name} @{$args{Parents}});
  }
}

sub RemoveClass {
  my ($self,%args) = (shift,@_);
  if ($args{Class}) {
    $self->Classes->Subtract($args{Class}->Name, $args{Class});
    $self->Types->remove($args{Class}->Name);
  }
}

sub RenameClass {
  my ($self,%args) = (shift,@_);
  $self->AddClass
    (Class => $args{RenamedClass},
     Parents => [$self->Types->parents($args{Class})]);
  $self->RemoveClass
    (Class => $args{Class});
}

sub AddNewDistinctionBetweenClasses {
  my ($self,%args) = (shift,@_);
  # model distinctions simply as second order relations, therefore accept
  my $d = Corpus::Ontology::Distinction->new(
     Name => $args{Name},
     Description => $args{Description},
     InputVector => $args{InputVector},
    );
  $self->Distinctions->Add($d->Name => $d);
}

sub ReclassificationOfAffectedClasses {
  my ($self,%args) = (shift,@_);

}

sub ExplainDistinctionBetweenClasses {
  my ($self,%args) = (shift,@_);

  # Maybe  some  explanation of  the  distinction  between classes  in
  # corpus would be useful.
}

sub ChangeClassLocation {
  my ($self,%args) = (shift,@_);
}

sub FixClassesWhichHaveBeenChanged {
  my ($self,%args) = (shift,@_);
}

sub EditOntology {
  # An ontology editor of sorts.
}

sub ListItemsByClass {
  # Need corpus to list items by class.
}

sub ListClass {
  # A quick corpus thing would be a command like corpus --listall task
}

sub SaveClasses {
  my ($self,%args) = (shift,@_);
  # Corpus needs to also store its classes.
  $self->Types->save($self->StorageFile);
  # $self->Types->store($self->StorageFile);
}

sub LoadClasses {
  my ($self,%args) = (shift,@_);
  # Corpus needs to also store its classes.
  $self->Types->load($self->StorageFile);
  # $self->Types->retrieve($self->StorageFile);
}

sub BackupClasses {
  my ($self,%args) = (shift,@_);
  my $max = 0;
  foreach my $file (split /\n/, `ls data/backup`) {
    if ($file > $max) {
      $max = $file;
    }
  }
  ++$max;
  system "cp data/classes.log data/backup/$max";
}

sub StandardizeClass {
  # It would be  nice if Corpus classified various  types of messages,
  # and came up with a standard way of saying them, then a LM could be
  # created.
}

sub Edit {
  $self->MyUI
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

1;

# $Math::PartialOrder::Base::TYPE_TOP = '__TOP__'; # marks broken joins
# $Math::PartialOrder::Base::VERBOSE = 2;	# how much should we carp?
# $Math::PartialOrder::Base::WANT_USER_HOOKS = 1;	# run the user hooks?

# #
# # Construction & Initialization
# #
# $h = Math::PartialOrder::MyClass->new(%args); # (req) new partial order

# #
# # Hierarchy Manipulation
# #
# $newroot  = $h->root($typ);	# (req) set root-type

# $h = $h->add($typ, @parents);	# (req) add $typ under @parents
# $h = $h->move($typ, @parents);	# (req) move $typ to under @parents
# $h = $h->remove(@types);	# (req) delete all given @types

# $h = $h->add_parents($typ, @parents); # (opt) add @parents over $typ
# $h = $h->replace($old, $new);	# (opt) replace $old with $new
# $h1->ensure_types(@types);	# (opt) ensure that @types are defined

# $h = $h->clear();		# (opt) clear hierarchy
# $h2 = $h1->clone();		# (opt) exact copy
# $h1 = $h1->assign($h2);		# (opt) information-cloning
# $h1 = $h1->merge($h2, $h3, ...); # (opt) merge hierarchies

# #
# # Hierarchy Information
# #
# $size = $h->size();		# (opt) number of types defined
# $root = $h->root();		# (req) get root-type
# @leaves = $h->leaves();		# (opt) list of leaf-types
# @types = $h->types();		# (req) list of all types

# $bool = $h1->is_equal($h2);	# (opt) test structural equivalence
# $bool = $h->is_circular();	# (opt) test for circularity
# $bool = $h->is_deterministic();	# (opt) test for determinism
# ($t1,$t2) = $h->get_nondet_pair(); # (opt) get non-deterministic type-pair
# $bool = $h->is_treelike();	# (opt) test for tree-structure
# $typ = $h->get_multiparent_type(); # (opt) get type with multiple parents

# @types = $h->parents($typ);	# (req) return all parents of $typ
# @types = $h->children($typ);	# (req) return all children of $typ
# @types = $h->ancestors($typ);	# (opt) return all ancestors of $typ
# @types = $h->descendants($typ);	# (opt) return all descendants of $typ

# $bool = $h->has_type($typ);	# (opt) boolean type-check
# $bool = $h->has_types(@types);	# (opt) boolean type-check
# $bool = $h->has_parent($typ, $parent); # (opt) boolean parent-check
# $bool = $h->has_child($typ, $child); # (opt) boolean child-check
# $bool = $h->has_ancestor($typ, $ancestor); # (opt) boolean ancestor-check
# $bool = $h->has_descendant($typ, $descendant); # (opt) boolean descendant-check

# #
# # Inheritance Operations
# #
# $bool = $h->subsumes($t1,$t2);	# (opt) inheritance '<='
# $bool = $h->properly_subsumes($t1,$t2);	# (opt) inheritance '<'
# $bool = $h->extends($t1,$t2);	# (opt) inheritance '>='
# $bool = $h->properly_extends($t1,$t2); # (opt) inheritance '>'

# @lubs = $h->least_upper_bounds($t1,$t2); # (opt) lub operation
# @mcds = $h->min_common_descendants($typ1,$typ2); # (opt) nontrivial lubs
# $join = $h->njoin($t1,$t2,...);	# (opt) determ. n-ary lub
# $join = $h->type_join($typ1,$typ2,...);	# (opt) ... for types only

# @glbs = $h->greatest_lower_bounds($t1,$t2); # (opt) glb operation
# @mcas = $h->max_common_ancestors($typ1,$typ2); # (opt) nontrivial glbs
# $meet = $h->nmeet($t1,$t2,...);	# (opt) determ. n-ary glb
# $meet = $h->type_meet($typ1,$typ2); # (opt) ... for types only

# #
# # User-Defined Attributes
# #
# $hashref = $h->_attributes($typ); # (rcm) get user type-data hash
# $h->_attributes($typ,$hashref);	# (rcm) set user type-data hash

# $hashref = $h->_hattributes();	# (rcm) hierarchy attributes
# $h->_hattributes($hashref);	# (rcm) set hierarchy attributes

# $hashref = $h->get_attributes($typ); # (opt) user type-data
# $val = $h->get_attribute($typ, $attr); # (opt) get user type-data
# $val = $h->set_attribute($typ, $attr, $val); # (opt) set user type-data

# $val = $h->get_hattribute($attr); # (opt) get user hierarchy-data
# $val = $h->set_hattribute($attr, $val);	# (opt) set user hierarchy-data

# #
# # Sorting and Comparison
# #
# $val = $h->compare($t1,$t2);	# (opt) $val is -1, 0, 1, or undef
# $val = $h->_compare($typ1,$typ2); # (opt) ... for types only

# @youngest = $h->min(@types);	# (opt) minimal types in @types
# @eldest   = $h->max(@types);	# (opt) maximal types in @types

# @min = $h->min_extending($base,@types);	# (opt) minimal extending $base
# @max = $h->max_subsuming($base,@types);	# (opt) maximal subsuming $base

# @sorted = $h->subsort(@types);	# (opt) sort by type-subsumption
# @strata = $h->stratasort(@types); # (opt) stratify by type-subsumption
# $strata = $h->get_strata(@types); # (opt) get stratification-hash

# #
# # Compiling-Hierarchy Conventions
# #
# $bool = $h->compiled()		# (opt) for compilable hierarchies
#   $bool = $h->compiled($bool2)	# (opt) ensure (not) compiled
#   $bool = $h->compile();	# (opt) force compilation

# #
# # Iteration Utilities
# #
# $h->iterate(\&next,\&callback,\%args); # (opt) abstract iterator
# $h->iterate_step(\&next,\&callback,\%args); # (opt) abstract iterator
# $h->iterate_tracking(\&next,\&callback,\%args);	# (opt) abstract iterator
# $h->iterate_strata(\&next,\&callback,\%args); # (opt) abstract iterator

# $h->iterate_pc(\&callback,\%args); # (opt) parent-to-child
# $h->iterate_cp(\&callback,\%args); # (opt) child-to-parent
# $h->iterate_pc_step(\&callback,\%args);	# (opt) parent-to-child
# $h->iterate_cp_step(\&callback,\%args);	# (opt) child-to-parent
