#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;
use YAML::XS;

#set up a few things

# Template path
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
my $prams = $query->Vars;

my $custh = $dbh->prepare( "SELECT * from customer WHERE id = ?");
    $custh->execute($prams->{'custno'}) or die $custh->errstr;
my $customer = $custh->fetch;

my $custwarn;
if ($customer->[9] eq 'first'){
	$custwarn = 'Remember to set stage to quote';
}elsif ($customer->[9] eq 'quote'){
	$custwarn = '';
}else{
	$custwarn = "Are you sure we need to do a quote? Stage is $customer->[9]" ;
}

my ($sql, $panelth, $inverterth);

# this next bit is fucking messy and we've only got two suppliers, there
# must be a better way to do this.

if ( $prams->{'SC'} eq 'yes' && $prams->{'Sundog'} eq 'yes'){
	$panelth = $dbh->prepare( "SELECT * from panels");
    $panelth->execute or die $panelth->errstr;
	$inverterth = $dbh->prepare( "SELECT * from inverters");
	$inverterth->execute or die $inverterth->errstr;
} elsif ( $prams->{'SC'} eq 'no' && $prams->{'Sundog'} eq 'yes'){
	$panelth = $dbh->prepare( "SELECT * from panels WHERE supplier = ?");
    $panelth->execute('Sundog') or die $panelth->errstr;
	$inverterth = $dbh->prepare( "SELECT * from inverters WHERE supplier = ?");
	$inverterth->execute('Sundog') or die $inverterth->errstr;
} elsif ( $prams->{'SC'} eq 'yes' && $prams->{'Sundog'} eq 'no'){
	$panelth = $dbh->prepare( "SELECT * from panels WHERE supplier = ?");
    $panelth->execute('Solar Century') or die $panelth->errstr;
	$inverterth = $dbh->prepare( "SELECT * from inverters WHERE supplier = ?");
	$inverterth->execute('Solar Century') or die $inverterth->errstr;
} else { 
	die "No supplier selected";
}


my ($pan, @panels);
while ( $pan = $panelth->fetchrow_arrayref()){
	push(@panels,"$pan->[1] $pan->[2]");
}

my ($inv, @inverters);
while ( $inv = $inverterth->fetchrow_arrayref()){
	push(@inverters,"$inv->[1] $inv->[2]");
}

my $vars = {
    copyright => 'released under the GPL 2008',
	name => $customer->[1],
	address => $customer->[2],
	reff => $customer->[5],
	paneltype => \@panels,
	invtype => \@inverters,
	custwarn => $custwarn,
	custno => $prams->{'custno'},
};

$tt->process('quotepanel.tmpl', $vars) || die $tt->error(), "\n";

$dbh->disconnect();
