#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use CGI::Carp;
use DBI;
use YAML::XS;
use JSON;

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
my $file = $query->param('file');
# a basic check to see we're not being cracked, should probably check the
# referer too, but that can wait
carp unless ($table eq 'customer' || $table eq 'comment' || $table eq 'file');

# first deal with the special case of $table eq file
if ($table eq 'file'){
	# Untaint the vars
	$id =~ /([\d]+)/ ; $id = $1;
	$file =~ /([\w.]+)/ ; $file = $1;
	unlink("../files/$id/$file");
}else{
	# delete the thing identified by id from the table.
	my $del = $dbh->prepare("DELETE FROM $table WHERE id = ?");
	$del->execute($id);
}

$dbh->disconnect();

#now we need to create a json object to send back to the browser.
my $json = JSON->new->allow_nonref;
# create a reply var to send back to the browser
# don't know quite what to send back yet so create this empty for now
# probably want to trap errors and warn about failures
my $reply;

# redirect back to where we came from.
#my $redirect = $query->referer() || "/cgi-bin//ssss.pl";
#print $query->redirect($redirect);
print $query->header('text/html');
print $json->encode($reply);
