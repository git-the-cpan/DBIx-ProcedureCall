use Test::More tests => 12;
use strict;

SKIP: {


my $dbuser = $ENV{ORACLE_USERID};

skip 'environment ORACLE_USERID is not set, skipping Oracle tests', 12 unless $dbuser;

eval {
	require DBI;
} or skip "could not load DBI module: $@", 12;


my $conn = DBI->connect('dbi:Oracle:', $dbuser, '', { PrintError => 0 , RaiseError=>1});


{
	package T1;
	eval q{
		use DBIx::ProcedureCall qw(
				sysdate
				greatest:function
				dbms_random.initialize:procedure
				);};
}



#########################

{

my $testname = 'simple call to sysdate';


ok ( T1::sysdate($conn), $testname );
		
}

#########################

{

my $testname = 'call to greatest() with positional parameters';

ok ( T1::greatest($conn, 1,2,42) == 42, $testname );
		
}

#########################

{

my $testname = 'call to greatest() using the run() interface';

ok ( DBIx::ProcedureCall::run($conn, 'greatest:function', 1,2,42) == 42, $testname );
		
}

#########################

{

my $testname = 'call to dbms_random.initialize with a named parameter';

T1::dbms_random_initialize($conn, 12345678);
ok ( 1 , $testname );
		
}


#########################

{

my $testname = 'call to greatest in the wrong context but with proper declaration';

T1::greatest($conn, 12345678,11,11);
ok ( 1 , $testname );
		
}

#########################

{

my $testname = 'calls to dbms_random using a package';

eval q{
	use DBIx::ProcedureCall qw[ 
		dbms_random:package
		];
	};

dbms_random::initialize($conn,123456);
my $a =  dbms_random::random($conn);

ok ( $a == 1826721802 , $testname );
		
}

#########################

{

my $testname = 'calls to dbms_random using packaged functions';

eval q{
	use DBIx::ProcedureCall qw[ 
		DBMS_random.initialize:packaged:procedure
		DBMS_random.random:packaged
		];
	};

my $b = DBMS_random::initialize($conn,123456);
my $a =  DBMS_random::random($conn);

ok ( $a == 1826721802 , $testname );
		
}

#########################

{

my $testname = 'fetch()';

my $sql = q{ 
begin
	open ? for select 'A', 'B' from dual;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my ($a, $b) = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( "$a$b" eq 'AB', $testname);

}

#########################

{

my $testname = 'fetch[[]]';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ref $data eq 'ARRAY' 
	&& ref $data->[0] eq 'ARRAY'
	, $testname
);

}

#########################

{

my $testname = 'fetch[{}]';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ref $data eq 'ARRAY' 
	&& ref $data->[0] eq 'HASH'
	, $testname
);

}

#########################

{

my $testname = 'fetch{}';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ref $data eq 'HASH' 
	, $testname
);

}

#########################

{

my $testname = 'fetch[]';

my $sql = q{ 
begin
	open ? for select * from all_tables;
	end;};
		
my $sth = $conn->prepare($sql);
my $r;
$sth->bind_param_inout(1, \$r,  0, 
	{ora_type => DBD::Oracle::ORA_RSET()});
$sth->execute;

my $attr =  { $testname => 1} ;
my $data = DBIx::ProcedureCall::__fetch($r, $attr, 'Oracle');

ok ( ((ref $data eq 'ARRAY') 
	and not (ref $data->[0]))
	, $testname
);

}

# END SKIP
};
