package DBIx::ProcedureCall::Oracle;

use strict;
use warnings;

our $VERSION = '0.04';

sub __run_procedure{
	shift;
	my $dbh = shift;
	my $name = shift;
	my $attr = shift;
	my $params;
	# if there is one more arg and it is a hashref, then we use named parameters
	if (@_ == 1 and ref $_[0] eq 'HASH') {
		return __run_procedure_named($dbh, $name, $attr, $_[0]);
	}
	# otherwise they are positional parameters
	my $sql = "begin $name";
	if (@_){
	$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
	}
	$sql .= '; end;';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	my $i = 1;
	foreach (@_){
		$sql->bind_param($i++, $_);
	}
	# execute
	$sql->execute;
}

sub __run_procedure_named{
	my ($dbh, $name, $attr, $params) = @_;
	my $sql = "begin  $name";
	my @p = sort keys %$params;
	if (@p){
		@p = map { "$_ => :$_" } @p;
		$sql .= '(' . join (',', @p) . ')';
	}
	$sql .= '; end;';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	foreach (keys %$params){
			$sql->bind_param(":$_", $params->{$_});
	}
	# execute
	$sql->execute;
}

sub __run_function{
	shift;
	my $dbh = shift;
	my $name = shift;
	my $attr = shift;
	my $params;
	# if there is one more arg and it is a hashref , then we use with named parameters
	if (@_ == 1 and ref $_[0] eq 'HASH') {
		return __run_function_named($dbh, $name, $attr, $_[0]);
	}
	# otherwise they are positional parameters
	my $sql = "begin ? := $name";
	if (@_){
	$sql .= '(' . join (',' , map ({ '?'} @_  )) . ')';
	}
	$sql .= '; end;';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	my $r;
	my $i = 1;
	$sql->bind_param_inout($i++, \$r, 100);
	foreach (@_){
		$sql->bind_param($i++, $_);
	}
	#execute
	$sql->execute;
	return $r;
}

sub __run_function_named{
	my ($dbh, $name, $attr, $params) = @_;
	my $sql = "begin :perl_oracle_procedures_ret := $name";
	my @p = sort keys %$params;
	if (@p){
		@p = map { "$_ => :$_" } @p;
		$sql .= '(' . join (',', @p) . ')';
	}
	$sql .= '; end;';
	# print $sql;
	# prepare
	$sql = $attr->{cached} ? $dbh->prepare_cached($sql)
		: $dbh->prepare($sql);
	# bind
	my $r;
	$sql->bind_param_inout(':perl_oracle_procedures_ret', \$r, 100);
	foreach (keys %$params){
			$sql->bind_param(":$_", $params->{$_});
	}
	# execute
	$sql->execute;
	return $r;
}



1;
__END__


=head1 NAME

DBIx::ProcedureCall::Oracle - Oracle driver for DBIx:::ProcedureCall

=head1 DESCRIPTION

This is an internal module used by DBIx::ProcedureCall. You do not need
to access it directly.

=head1 AUTHOR

Thilo Planz, E<lt>thilo@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


