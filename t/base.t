#########################


use Test::More tests => 5;
use strict;

BEGIN { use_ok('DBIx::ProcedureCall') };

#########################

{

my $testname = 'generate subroutines, no attributes';

{
	package T1;
	eval q{
		use DBIx::ProcedureCall qw(
				sysdate
				greatest
				);};
}

ok (
	T1->can('sysdate')
	and T1->can('greatest'),
	$testname
	);

}		

#########################

{

my $testname = 'generate subroutines, with attributes';

{
	package T2;
	eval q{
		use DBIx::ProcedureCall qw(
				sysdate:function
				dummy:procedure:cached
				);};
}

ok (
	T2->can('sysdate')
	and T2->can('dummy'),
	$testname
	);
}		


#########################

{

my $testname = 'generate a package ';

eval q{
	use DBIx::ProcedureCall qw(
			MySchema.MyPackage:package
			);
	MySchema::MyPackage::myprocedure(1,2,3);
	};

ok (
	MySchema::MyPackage->can('myprocedure'),
	$testname
	);
}		

#########################

{

my $testname = 'generate some packaged procedures ';

eval q{
	use DBIx::ProcedureCall qw(
			MySchema.MyPackage.anotherprocedure:packaged:procedure
			MySchema.MyPackage.myfunction:packaged
			);
	};

ok (
	MySchema::MyPackage->can('anotherprocedure')
	&& 
	MySchema::MyPackage->can('myfunction'),
	$testname
	);
}		





