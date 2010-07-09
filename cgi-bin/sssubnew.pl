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
my $prams = $query->Vars;
my @comact;
my @active;

if ($prams->{'id'}){
	my @submit;
	my $insert;
	my $update;
	my $custth = $dbh->prepare( "SELECT * from customer WHERE id = ?");
	$custth->execute($prams->{'id'}) or die $custth->errstr;
	my $customer = $custth->fetch; 
		# As we are selecting by id there is only one row.
	push(@active,'name') unless ($$customer[1] eq $prams->{'name'});	
	push(@active,'address') unless ($$customer[2] eq $prams->{'address'});	
	push(@active,'phone') unless ($$customer[3] eq $prams->{'phone'});	
	push(@active,'email') unless ($$customer[4] eq $prams->{'email'});	
	push(@active,'reff') unless ($$customer[5] eq $prams->{'reff'});	
	push(@active,'grantype') unless ($$customer[6] eq $prams->{'grantype'});	
	push(@active,'lead') unless ($$customer[7] eq $prams->{'lead'});	
	push(@active,'first') unless ($$customer[8] eq $prams->{'first'});	
	push(@active,'stage') unless ($$customer[9] eq $prams->{'stage'});	
	push(@active,'actdate') unless ($$customer[10] eq $prams->{'actdate'});	
	push(@active,'assign') unless ($$customer[11] eq $prams->{'assign'});	
	# The above checks the input from tne cgi against the db and sees which
	# columns are 'active'
	if ($active[0]){
		for my $i (0..$#active){
			 if ($i == 0){ $update .= " $active[$i] = ?";}
			 else {$update .= ", $active[$i] = ? ";}
		} 
		my $upcussth = $dbh->prepare("UPDATE customer SET $update WHERE id=?");
		foreach (@active){
			push(@submit, $prams->{"$_"});
		}
		push(@submit, $prams->{'id'});
		$upcussth->execute(@submit) or die "$upcussth->errstr : $update";
	}
	my $commth = $dbh->prepare( "SELECT * from comment WHERE custid = ?");
	$commth->execute($prams->{'id'}) or die $commth->errstr;
	my $comment = [];
	my @comup;
	while($comment = $commth->fetch){
		push(@comact,$$comment[0]) unless 
						($$comment[2] eq $prams->{"$$comment[0]date"} &&
						$$comment[3] eq $prams->{"$$comment[0]comment"});
	}
	if ($comact[0]){
		my $upcomsth = $dbh->prepare
				("UPDATE comment SET date = ?, comment = ? WHERE id = ?");
		foreach (@comact){
			push(@comup, $prams->{$_.'date'});
			push(@comup, $prams->{$_.'comment'});
			push(@comup, $_);
			$upcomsth->execute(@comup); 
			#die "!!! $comup[0] !!! $comup[1] !!! $comup[2] !!!";
			@comup = [];	
		}
	}
	if($prams->{'comment'}){
		my $newcomsth = $dbh->prepare
        	( "INSERT comment (custid, date, comment) VALUES (?,?,?)" );
		$newcomsth->execute( $prams->{'id'}, $prams->{'date'},
					 $prams->{'comment'}) or die $newcomsth->errstr;
	}
}
else{ 
	my $newcussth = $dbh->prepare( "INSERT customer (actdate, name, address, phone, email, reff, grantype, lead, first, stage, assign) VALUES (?,?,?,?,?,?,?,?,?,?,?)" );
	$newcussth->execute( $prams->{'actdate'}, $prams->{'name'}, $prams->{'address'}, $prams->{'phone'}, $prams->{'email'}, $prams->{'reff'}, $prams->{'grantype'}, $prams->{'lead'}, $prams->{'first'}, $prams->{'stage'}, $prams->{'assign'}) or die $newcussth->errstr;	
}
my $vars = {
    copyright => 'released under the GPL 2008',
	active => \@active,
	comact => \@comact,
};

$tt->process('sssubmit.tmpl', $vars) || die $tt->error(), "\n";

$dbh->commit();

$dbh->disconnect();
