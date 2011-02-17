#!/usr/bin/perl -Tw
use strict;
use CGI;
use CGI::Carp;
use Template;
use DBI;
use YAML::XS;
use Data::Dumper;

#setup a template directory

my $tt = Template->new({ INCLUDE_PATH => '../templates', }) ||
		die "$Template::ERROR\n";

# get sql config from ../conf/sql.yaml and open database
my $sqlconfig = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails = Load $sqlconfig;
my $dbh = DBI->connect($$sqldetails{db}, $$sqldetails{user},
			$$sqldetails{pass},
			{ RaiseError => 1, AutoCommit => 0 })
			or die "Database connection not made: $DBI::errstr";

# set up a new CGI and get the parameteres passed through from the browser
my $query = new CGI;
my $parms = $query->Vars;

# read in request method from ENV and convert to all caps

$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

# check to see how we were called and do appropriate stuff
if ($ENV{'REQUEST_METHOD'} eq "POST"){
	# we'v been called to post a comment or change to a comment.
	# this is a first past quick and dirty hack to just update all the comments
	# we might use dirtyform later
	# declare a var to store what needs to be updated.
	my $upsql = $dbh->prepare(
		'UPDATE comment SET comment = ?, date = ? WHERE id = ?');
	my $comsql = $dbh->prepare(
		'INSERT comment (custid, date, comment) VALUES (?,?,?)');
	my $delsql = $dbh->prepare('DELETE FROM comment WHERE id =?');
	# step thru the parms and updates the updateable comments
	foreach(keys %{$parms}){
		if (/^(\d+)comment/){
			if ($parms->{$1.'del'} eq "Delete"){
				
				$delsql->execute($1);	
			}else{
				$upsql->execute($parms->{$1.'comment'},
					$parms->{$1.'date'}, $1); 
			}
			# we probably want to do some kind of logging here.
		}elsif (/^new(\d+)comment/){
			next unless $parms->{'new'.$1.'comment'};
			$comsql->execute($1,$parms->{'new'.$1.'date'},
				$parms->{'new'.$1.'comment'});
			# logging?
		} # I feel there should be an else here.
	}
	# redirect to the referer
	my $redirect = $query->referer() || "/cgi-bin/comment.pl";
	print $query->redirect($redirect);
	# close db handle
	$dbh->commit;
	$dbh->disconnect();

}else{
	# should be just GETs so we need to grab the comments we've been called
	# to provide and splurge out the template.

	# We need today's date as a default for the comments.
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
	$mon += 1;
	$year += 1900;
	my $today = "$year-$mon-$mday";
	# declare a var for the comment query sql handle
	my $commsth = $dbh->prepare("SELECT * FROM comment WHERE custid =?");
	# execute the sql query using the passed id from the cgi paramaters
	$commsth->execute($parms->{'custid'}) or croak $commsth->errstr;
	my $commentref = $commsth->fetchall_arrayref({});
	my $vars = {
		comments => $commentref,
		custid => $parms->{'custid'},
		today => $today
	};
	$tt->process('comment.tmpl', $vars) || croak $tt->error(), "\n";

	$dbh->disconnect or carp "Disconnection failed: $DBI::errstr\n";
}
