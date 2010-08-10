#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;
use YAML::XS;

my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

#Load the mysql login info from a YAML file in the conf directory

my $sqlconfig  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails = Load $sqlconfig;

my  $dbh = DBI->connect($$sqldetails{db}, $$sqldetails{user},
             $$sqldetails{pass},
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