#########################


use Test::More tests => 3;

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





