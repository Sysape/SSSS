#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use CGI::Carp;
use Template;
use DBI;
use YAML::XS;
use JSON;

# detaint the path
$ENV{'PATH'} = '/bin:/usr/bin';

#setup a template directory

my $tt = Template->new({
    INCLUDE_PATH => '../templates',
}) || die "$Template::ERROR\n";

# get sql config from ../conf/sql.yaml and open database.
my $sqlconfig  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails = Load $sqlconfig;
my  $dbh = DBI->connect($$sqldetails{db}, $$sqldetails{user},
             $$sqldetails{pass},
            { RaiseError => 1, AutoCommit => 0 })
            or die "Database connection not made: $DBI::errstr";

#set up a new CGI and get the parameters passed through from the browser
my $query = new CGI;
my $parms = $query->Vars;

# The date is required for some form defaults
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
$mon += 1;
$year += 1900;
my $today = "$year-$mon-$mday";

# Read in text and convert to all caps.
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;

if ($ENV{'REQUEST_METHOD'} eq "POST"){
	# This is a lot simpler now we just have one customer's update details
	# for one customer in the customer table.
	# Prepare the customer update sql statement here
	my $upsql = $dbh->prepare('UPDATE customer SET actdate = ?, name = ?, address = ?, phone = ?,email = ?, reff = ?, grantype = ?, lead = ?, first = ?, stage = ?, assign  = ? WHERE id = ?');
	# and execute it using the parms we were passed.
	$upsql->execute($parms->{"actdate"},
						$parms->{'name'},
						$parms->{'address'},
						$parms->{'phone'},
						$parms->{'email'},
						$parms->{'reff'},
						$parms->{'grantype'},
						$parms->{'lead'},
						$parms->{'first'},
						$parms->{'stage'},
						$parms->{'assign'},
						$parms->{'id'}) or die
								"$upsql->errstr : $parms->{'id'}";
	# So we need a json object to pass back to the browser
	my $reply;
	my $json = JSON->new->allow_nonref;
	# fill the reply var with salient details.
	my $reply = {id => $parms->{'id'},
				 name => $parms->{'name'},
				 address => $parms->{'address'},
				 phone => $parms->{'phone'},
				 email => $parms->{'email'},
				 reff => $parms->{'reff'},
				 grantype => $parms->{'grantype'},
				 lead => $parms->{'lead'},
				 first => $parms->{'first'},
				 stage => $parms->{'stage'},
				 actdate => $parms->{'actdate'},
				 assign => $parms->{'assign'}
	};
    # redirect to the referer
    #my $redirect = $query->referer() || "/cgi-bin/ssss.pl";
    #print $query->redirect($redirect);
	# Send the json object back to the browser
    print $query->header('text/html');
    print $json->encode($reply);
	# disconnect from the db
	$dbh->commit() or carp "Commit failed: $DBI::errstr\n";
	$dbh->disconnect() or carp "Disconnection failed: $DBI::errstr\n";

}else{
	#we need to create a sql statement to get the customers details we want.
	my $sth = $dbh->prepare('SELECT * from customer where ID = ?');
	$sth->execute($parms->{'id'}) or die $sth->errstr;
	# there will only be one row returned so we can get it with
	my $ref = $sth->fetchrow_hashref();
	# the javascript needs to have a list of columns, this needs an 
	# inherited conf sometime soon.
	my @column =
    qw(id actdate name address phone email reff grantype lead first stage assign);
	my $vars = {
		copyright => 'released under the GPL 2008',
		parms => $parms,
		customer => $ref,
		columns => \@column,
		today => $today
	};
	$tt->process('edit.tmpl', $vars)
	    || die $tt->error(), "\n";
	$dbh->commit() or carp "Commit failed: $DBI::errstr\n";
	$dbh->disconnect or carp "Disconnection failed: $DBI::errstr\n";
}
