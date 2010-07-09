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

my  $dbh = DBI->connect('dbi:mysql:$sqldetails=>db', '$sqldetails=>user',
             '$sqldetails=>pass',
			{ RaiseError => 1, AutoCommit => 0 }) 
			or die "Database connection not made: $DBI::errstr";


my $query = new CGI;
my $custid = $query->param('custid');
my $date = $query->param('date');
my $comment = $query->param('comment');


my $sth = $dbh->prepare
		( "INSERT comment (custid, date, comment) VALUES (?,?,?)" );
$sth->execute( $custid, $date, $comment) or die $sth->errstr;	

my $vars = {
    copyright => 'released under the GPL 2008'
};

$tt->process('sssubmit.tmpl', $vars) || die $tt->error(), "\n";

$dbh->commit();

$dbh->disconnect();
