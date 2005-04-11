use Test::More tests => 5;
use strict;
no warnings;

BEGIN {
	use_ok('DBIx::ProcedureCall::CLI') 
};

SKIP:{

eval {
	require Test::Output;
} or skip "needs Test::Output", 4;


SKIP:{
	skip "pending DBD::Mock update", 1;
	eval {
		require DBD::Mock;
	} or skip "skipping DBD::Mock tests", 1;
	
	sub DBD::Mock::st::bind_param_inout{
		my ($sth, $param_num, $val, $max_len) = @_;
		# check that $val is a scalar ref
		die "need a scalar ref to bind_param_inout, not $val" unless UNIVERSAL::isa $val, 'SCALAR'; 
		# check for positive $max_len
		die "need to specify a maximum length to bind_param_inout" unless $max_len > 0;
		my $tracker = $sth->FETCH( 'mock_my_history' );
		$tracker->bound_param( $param_num, $val );
		return 1;
	}
	
	sub  DBIx::ProcedureCall::CLI::conn{
		my ($dsn) = @_;
		$Test::conn = DBI->connect($dsn, undef, undef, { 
			RaiseError => 1, AutoCommit => 1, PrintError => 0,
			});
	}
	
local $ENV{DBI_USER} = 'foo';
	
@ARGV = qw[
	dbi:Mock:
	dbms_output.get_line
	:line=blah
	:status=1
	];
	
	my $combined = Test::Output::combined_from ( \&procedure );
	my $history = $Test::conn->{mock_all_history};
	is (<<CHECK, <<EXPECTED, 'Mock Oracle procedure with OUT params (dbms_output.get_line)');
$combined
$history->[0]{statement}
CHECK
executed procedure 'dbms_output.get_line'. 
------ parameters -------
:line = blah
:status = 1
------------------------

begin dbms_output.get_line(?,?); end;
EXPECTED

}#END SKIP Mock

SKIP:{

my $dbuser = $ENV{ORACLE_USERID};

skip 'environment ORACLE_USERID is not set, skipping Oracle tests', 2 unless $dbuser;
local $ENV{DBI_USER} = $dbuser;

@ARGV = qw[
	dbi:Oracle:
	greatest
	A
	C
	I
	D
	];

Test::Output::combined_is (
	 \&function,<<'OUTPUT','Oracle function(greatest)');
executed function 'greatest'. 
------ result -----------
I
------------------------
OUTPUT


@ARGV = qw[
	dbi:Oracle:
	dbms_output.get_line
	:line
	:status
	];

Test::Output::combined_is (
	 \&procedure,<<'OUTPUT','Oracle procedure with OUT params (dbms_output.get_line)');
executed procedure 'dbms_output.get_line'. 
------ parameters -------
:line = <null>
:status = 1
------------------------
OUTPUT
}


SKIP:{

my $dbuser = $ENV{PGUSER};
skip 'environment PGUSER is not set, skipping PostgreSQL test', 1 unless $dbuser;

@ARGV = qw[
	dbi:Pg:
	power
	5
	3
	];
	
Test::Output::combined_is (
	 \&function,<<'OUTPUT','Postgres');
executed function 'power'. 
------ result -----------
125
------------------------
OUTPUT
}


}
