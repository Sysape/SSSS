#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use DBI;
use YAML::XS;

#Load the mysql login info from a YAML file in the conf directory

my $sqlconfig  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails  = Load $sqlconfig;

#die "$$sqldetails{db} $$sqldetails{user} $$sqldetails{pass}";

my  $dbh = DBI->connect($$sqldetails{db}, $$sqldetails{user},
             $$sqldetails{pass},
			{ RaiseError => 1, AutoCommit => 0 }) 
			or die "Database connection not made: $DBI::errstr";
use Template;

#setup a template directory

my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

my $query = new CGI;
my $id = $query->param('id') || 'new';
my @ary;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime time;
$mon += 1;
$year += 1900;
my $today = "$year-$mon-$mday";

# If we're editing an old record we need to pass on the info  
if ($id ne "new" && $id !~ /\D/){
	my $sth = $dbh->prepare( "SELECT * FROM customer WHERE id = ?" );
	$sth->execute( $id ) or die $sth->errstr;	
	@ary = $sth->fetchrow_array;	 #query can only return one row
# If not just the date
}elsif($id eq "new"){
	$ary[0] ='new';
	$ary[8] = $today;
}
else{ die 'CRACK ATTACK';}

my $vars = {
    copyright => 'released under the GPL 2008',
	id => $ary[0],
	actdate => $ary[10],
	name => $ary[1],
	address => $ary[2],
	phone => $ary[3],
	email => $ary[4],
	reff => $ary[5],
	grantype => $ary[6],
	lead => $ary[7],
	first => $ary[8],
	stage => $ary[9],
	assign => $ary[11],
	today => $today
};

$tt->process('ssnewform.tmpl', $vars) || die $tt->error(), "\n";

$dbh->disconnect();
