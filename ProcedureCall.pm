package DBIx::ProcedureCall;

use strict;
use warnings;

use Carp qw(croak);


our $VERSION = '0.03';

our %__loaded_drivers;

sub __run_procedure{
		my $dbh =$_[0];
		croak "expected a database handle as first parameter, but got nothing" unless $dbh;
		my $name = $_[1];
		croak "expected a procedure name to run against the database, but got nothing" unless $name;
		
		# determine database type
		my $dbtype = eval { $dbh->get_info(17); };  #  17 : SQL_DBMS_NAME  
		croak "could not determine the database type from $dbh: $@. Is that really a DBI database handle? " unless $dbtype;
		# delegate to the driver
		unless ($__loaded_drivers{$dbtype}){
			eval  "require DBIx::ProcedureCall::$dbtype; \$__loaded_drivers{$dbtype} = 1;" 
				or croak "failed to load driver for $dbtype database: $@";	
		}
		
		"DBIx::ProcedureCall::$dbtype"->__run_procedure(@_);
}

sub __run_function{
		my $dbh = $_[0];
		croak "expected a database handle as first parameter, but got nothing" unless $dbh;
		my $name = $_[1];
		croak "expected a function name to run against the database, but got nothing" unless $name;
		
		# determine database type
		my $dbtype = eval { $dbh->get_info(17); };  #  17 : SQL_DBMS_NAME  
		croak "could not determine the database type from $dbh: $@. Is that really a DBI database handle? " unless $dbtype;
		# delegate to the driver
		unless ($__loaded_drivers{$dbtype}){
			eval  "require DBIx::ProcedureCall::$dbtype; \$__loaded_drivers{$dbtype} = 1;" 
				or croak "failed to load driver for $dbtype database: $@";	
		}	
		
		return "DBIx::ProcedureCall::$dbtype"->__run_function(@_);
}

sub __run{
	my $w = shift;
	my $name = shift;
	my $attr = shift;
	my $dbh = shift;
	# check function/procedure attribute
	$w = 0 if $attr->{function};
	$w = undef if $attr->{procedure};
	# in void context run a procedure
	return __run_procedure($dbh, $name, $attr, @_) unless defined $w;
	# in non-void context run a function
	return __run_function($dbh, $name, $attr, @_);
}

sub run{
	my $dbh = shift;
	my $n = shift;
	my ($name, @attr) = split ':', $n;
	my %attr = map { (lc($_) => 1) } @attr;
	return __run(wantarray, $name, \%attr, $dbh, @_);
}


sub import {
    my $class = shift;
    my $caller = (caller)[0];
    no strict 'refs';
    foreach (@_) {
	my ($name, @attr) = split ':';
	my %attr = map { (lc($_) => 1) } @attr;
	my $subname = $name;
	$subname =~ s/\W/_/g;
        *{"$caller\::$subname"} = sub { 
			DBIx::ProcedureCall::__run(wantarray,$name,\%attr, @_)
		};
    }
}


1;
__END__



=head1 NAME

DBIx::ProcedureCall - Perl extension to make database stored procedures look like Perl subroutines

=head1 SYNOPSIS

  use DBIx::ProcedureCall qw(sysdate);
  
  my $conn = DBI->connect(.....);
  
  print sysdate($conn);
  

=head1 DESCRIPTION

When developing applications for an Oracle database, it is a good
idea to put all your database access code into stored procedures.
This module provides a convenient way to call these stored
procedures from Perl by creating wrapper subroutines that
produce the necessary SQL statements, bind parameters and run
the query.

While the this module's interface is database-independent,
only Oracle is currently supported.


=head2 EXPORT

DBIx::ProcedureCall exports subroutines for any stored procedures
(and functions) that you ask it to. You specify the list of
procedures that you want when using the module:

    use DBIx::ProcedureCall qw[ sysdate ]
    
    # gives you
    
    print sysdate($conn);
    

Calling such a subroutine will invoke the stored procedure.
The subroutines expect a DBI database handle as
their first parameter.

=head3 Subroutine names

The names of the subroutine is derived from the name
of the stored procedure. Because the procedure name can
contain characters that are not valid in a Perl procedure name,
it will be sanitized a little:

Everything that is not a letter or a number becomes underscores. 
This will happen for all
procedures that are part of a PL/SQL package, where
the package name and the procedure name are divided by a dot.

	use DBIx::ProcedureCall qw( 
		sysdate
		dbms_random.random
		hh\$\$uu
		);
		
	# gives you
	
	sysdate();					# no change
	dbms_random_random();		# note the underscore
	hh__uu();					# dollar signs removed


You can request stored procedures that do not exist.
This will not be detected by DBIx::ProcedureCall, but
results in a database error when you try to call them.


=head3 Procedures and functions

DBIx::ProcedureCall needs to know if you are about
to call a function or a procedure (because the SQL is different).
You have to make sure you call the wrapper subroutines
in the right context (or you can optionally declare
the correct type, see below)

You have to call procedures in void context.

	# works
	dbms_random_initialize($conn, 12345);
	# fails
	print dbms_random_initialize($conn, 12345);

You have to call functions in non-void context.

	# works
	print sysdate($conn);
	# fails
	sysdate($conn);

If you try to call a function as a procedure, you will get
a database error.

If you do not want to rely on this mechanism, you can
declare the correct type using the attributes :procedure
and :function:

	use DBIx::ProcedureCall qw[
		sysdate:function
		dbms_random.initialize:procedure
		];

If you use these attributes, the calling context will be
ignored and the call will be dispatched according to 
your declaration.


=head3 Parameters

You can pass parameters to the subroutines
(only IN parameters are supported at the moment)
You can use both positional and named parameters,
but cannot mix the two styles in the same call.

Positional parameters are passed in after the 
database handle, which is always the first parameter:

	dbms_random_initialize($conn, 12345);

Named parameters are passed as a hash reference:

	dbms_random_initialize($conn, { val => 12345678 } );

The parameters you use have to match the parameters
defined (in the database) for the stored procedure. 
If they do not, you 
will get a database error at runtime.

=head3 Attributes

When importing the subroutines, you can optionally specify
one or more attributes. 

	use DBIx::ProcedureCall qw[
		sysdate:function:cached
		];

Currently known attributes are:

=head4 :procedure / :function

Declares the stored procedure to be a function or a procedure,
so that the context in which you call the subroutine is of no importance
any more.

=head4 :cached

Uses DBI's prepare_cached() instead of the default prepare() ,
which can increase database performance. See the DBI documentation 
on how this works.





=head2 ALTERNATIVE INTERFACE

If you do not want to import wrapper functions, you can still
use the SQL generation and parameter binding mechanism
of DBIx::ProcedureCall:

	DBIx::ProcedureCall::run($conn, 'dbms_random.initialize', 12345);

	print DBIx::ProcedureCall::run($conn, 'sysdate');

This can be useful if you do not know the names of the 
stored procedures at compilation time.
You still have to know if it is a function or a procedure, though,
because you need to call DBIx::ProcedureCall::run in the appropriate
context.

You can also use attributes, with the same syntax as normal:

	DBIx::ProcedureCall::run($conn, 'sysdate:function');

=head1 SEE ALSO

This module is built on top of DBI, and
you need to use that module to establish a database connection.

DBIx::Procedures::Oracle offers similar functionality.
Unlike DBIx::ProcedureCall, it takes the additional step of
checking in the data dictionary if the procedures you want
exist, and what parameters they need.

=head1 LIMITATIONS

The module wants to provide an extremely simple interface to the most common forms of stored procedures.
It will not be able to handle very complex cases.
That is not the goal, if it can eliminate 90% of hand-written SQL 
and bind calls, I am happy.


Only Oracle is supported now. 
If you want to implement a driver for another data base system,
have a look at the source code for the Oracle version, see if you can adapt it.
If this leads to working code, let me know, so that I can bundle it.


You cannot mix named and positional parameters

You can only have IN parameters now (this is expected to be fixed in a future release)

Cursors and LOB (except for small ones probably) do not work now.

=head1 TODO

OUT parameters

Cursors

Anonymous blocks


=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
