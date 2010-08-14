#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;
use YAML::XS;

#setup a template directory

my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
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
#See how we were called
if ($ENV{'REQUEST_METHOD'} eq "POST"){
	# decalre a couple of arrays to hold lists of what needs altering.	
	my (@comact, @active);
	# if we're updating an old record we should have an id number
	if ($prams->{'id'}){
		# declare some vars as db handles and bind var arrays.
		my (@submit, $insert, $update);
		# prepare and execute a SQL statement getting the current values
		# from the customer table for that id.
		my $custth = $dbh->prepare( "SELECT * from customer WHERE id = ?");
		$custth->execute($prams->{'id'}) or die $custth->errstr;
			# As we are selecting by id there is only one row.
		my $customer = $custth->fetch; 
		# Check the input from tne cgi against the db and see which columns
		# are 'active'
		push(@active,'name') unless ($$customer[1] eq $prams->{'name'});	
		push(@active,'address') unless ($$customer[2] eq $prams->{'address'});	
		push(@active,'phone') unless ($$customer[3] eq $prams->{'phone'});	
		push(@active,'email') unless ($$customer[4] eq $prams->{'email'});	
		push(@active,'reff') unless ($$customer[5] eq $prams->{'reff'});	
		push(@active,'grantype') unless ($$customer[6] eq
													$prams->{'grantype'});	
		push(@active,'lead') unless ($$customer[7] eq $prams->{'lead'});	
		push(@active,'first') unless ($$customer[8] eq $prams->{'first'});	
		push(@active,'stage') unless ($$customer[9] eq $prams->{'stage'});	
		push(@active,'actdate') unless ($$customer[10] eq $prams->{'actdate'});	
		push(@active,'assign') unless ($$customer[11] eq $prams->{'assign'});	
		# if anything is active, step through the list of active things 
		# and add them to $update as a SQL snippet.
		if ($active[0]){
			for my $i (0..$#active){
				 if ($i == 0){ $update .= " $active[$i] = ?";}
				 else {$update .= ", $active[$i] = ? ";}
			} 
			# prepare the SQL thus created
			my $upcussth =
				$dbh->prepare("UPDATE customer SET $update WHERE id=?");
			# step through the active array again ans push the variable
			# passed through by the cgi onto an array called submit which
			# will be used as the SQL bind vars.
			foreach (@active){
				push(@submit, $prams->{"$_"});
			}
			# push the id on as the last bind var.
			push(@submit, $prams->{'id'});
			# execute the sql with the @submit bind vars array.
			$upcussth->execute(@submit) or
								die "$upcussth->errstr : $update";
		}
		# prepare and execute a SQL call to get all the comments from the
		# comment table for that custid.
		my $commth = $dbh->prepare( "SELECT * from comment WHERE custid = ?");
		$commth->execute($prams->{'id'}) or die $commth->errstr;
		# declare an array for the comments pulled from the db and another for
		# the updated comment from the cgi.
		my $comment = [];
		my @comup;
		# Step through the comments fetched from the db and push the comment
		# id onto the comact array unless the value from the db and the value
		# from the cgi are equal.
		while($comment = $commth->fetch){
			push(@comact,$$comment[0]) unless 
							($$comment[2] eq $prams->{"$$comment[0]date"} &&
							$$comment[3] eq $prams->{"$$comment[0]comment"});
		}
		# if we have anything in the comact array we need to update some
		# comments
		if ($comact[0]){
			# prepare the SQL to update the comment
			my $upcomsth = $dbh->prepare
					("UPDATE comment SET date = ?, comment = ? WHERE id = ?");
			# step through the comments in @comact and 
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
$dbh->disconnect();
}else{
	# now we do the normal thing to display rows of 
	#The next 3 mys should probably go in some kind of inheretied conf file.
	my @column =
	qw(id actdate name address phone email reff grantype lead first stage assign);
		# list of columns in order.
	my @like = qw(id name address phone email reff);
		# list of columns to text search
	my @is = qw(actdate grantype lead first stage assign);
		# list of columns to drop-down index. 
		# NB columns can only be on one of these lists, Things will break if
		# they're on both.
	# create an array to store the bind variables for the sql statement coming
	my @bind; 
	
	#start creating the sql statement to get all the customer info
	my $sql = "SELECT * FROM customer";
	
	# set the sort order for the sql statement.
	my $order = $parms->{'order'}|| 'id';
	
	# go through the list of is columns and see which are turned on in the
	# cgi parameters, add to the sql statement and the bind values
	foreach(@is){
		if ($parms->{$_} && $parms->{$_} ne 'ALL'){
			if ($sql =~ /WHERE/){
				if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
				# Special case for stage which can be ACTIVE and needs 3 values
					$sql .= " AND stage in ( ?, ?, ?)";
					push(@bind, "quote");
					push(@bind, "first");
					push(@bind, "happen");
				}else{
					$sql .= " AND $_ = ?";
					push(@bind, $parms->{$_});
				}
			} else {
				if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
					$sql .= " WHERE stage in ( ?, ?, ?)";
					push(@bind, "quote");
					push(@bind, "first");
					push(@bind, "happen");
				}else{
					$sql .= " WHERE $_ = ?";
					push(@bind, $parms->{$_});
				}
			}
		}
	}
	
	# Do a similar think with the list of like parameters passed through from
	# the cgi.
	foreach(@like){
		if ($parms->{$_} && $parms->{$_} ne 'ALL'){
			if ($sql =~ /WHERE/){
				$sql .= " AND $_ LIKE ?";
				push(@bind, "\%$parms->{$_}\%");
			} else {
				$sql .= " WHERE $_ LIKE ?";
				push(@bind, "\%$parms->{$_}\%");
			}
		}
	}
	$sql = $sql." ORDER BY $order";
	
	#retrieve from mysql the customers details we want.
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind) or die $sth->errstr;
	my $ref = $sth->fetchall_hashref('id');
	
	# get the comments for the customer ids we have.
	my $commentsql = "SELECT * FROM comment" ;
	my @commentbind;
	foreach my $key (sort (keys %{$ref})) {
		push (@commentbind, $key);
		if ($commentsql =~ /WHERE/){
			$commentsql .= " OR ?";
		}else{
			$commentsql .= " WHERE custid = ?";
		}		
	}
	my $custsth = $dbh->prepare($commentsql);
	$custsth->execute(@commentbind) or die $custsth->errstr;
	my $commentref = $custsth->fetchall_hashref('id');
	
	
	my $vars = {
		copyright => 'released under the GPL 2008',
		column => \@column,
		parms => $parms,
		like => \@like,
		is => \@is,
		customer => $ref,
		comments => $commentref,
		sql => $sql,
		bindvars => @bind
	};
	
	$tt->process('ssss.tmpl', $vars)
	    || die $tt->error(), "\n";
	
	$dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}
