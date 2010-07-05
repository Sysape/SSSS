#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;

my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

my  $dbh = DBI->connect('dbi:mysql:solsys', 'solsys', 'w0kk4', 
			{ RaiseError => 1, AutoCommit => 0 }) 
			or die "Database connection not made: $DBI::errstr";


my $query = new CGI;
my $id = $query->param('id') or die "No id!";

my $commentdel = $dbh->prepare("DELETE FROM comment WHERE id = ?");
$commentdel->execute($id);

my $vars = {
    copyright => 'released under the GPL 2008',
	id => $id
};

$tt->process('ssdelcom.tmpl', $vars) || die $tt->error(), "\n";

$dbh->disconnect();
