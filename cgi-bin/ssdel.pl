#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use DBI;
use YAML::XS;

#Load the mysql login info from a YAML file in the conf directory

my $sqlconfig  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails = Load $sqlconfig;

my  $dbh = DBI->connect($$sqldetails{db}, $$sqldetails{user},
             $$sqldetails{pass},
			{ RaiseError => 1, AutoCommit => 0 }) 
			or die "Database connection not made: $DBI::errstr";


my $query = new CGI;
my $id = $query->param('id') or die "No id!";
my $table = $query->param('table');
# a basic check to see we're not being cracked, should probably check the
# referer too, but that can wait
die unless ($table eq 'customer' || $table eq 'comment');

# delete the thing identified by id from the table.
my $del = $dbh->prepare("DELETE FROM $table WHERE id = ?");
$del->execute($id);

$dbh->disconnect();

# redirect back to where we came from.
my $redirect = $query->referer() || "/cgi-bin//ssss.pl";
print $query->redirect($redirect);

