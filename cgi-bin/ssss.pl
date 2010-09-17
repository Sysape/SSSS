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

if ($ENV{'REQUEST_METHOD'} eq "POST"){
	# we need to know what slice of the customer table the page we're on
	# is dealing with. Firstly declare a variable to take the sql statement
	# and one for the results.
	my ($postsql, $postresult);
	#So we check if there is one and if it's not the 
	# default url NB this is bad as we've just hardcoded the url in here
	# maybe want to only match the last bit (ssss.pl) but it'll do for now.
	if ($ENV{'HTTP_REFERER'} && $ENV{'HTTP_REFERER'} ne 
			'http://testinternal.solsticeenergy.co.uk/cgi-bin/ssss.pl') &&
		$ENV{'HTTP_REFERER'} ne 'http://testinternal.solsticeenergy.co.uk/cgi-bin/ssss.pl?id=&actdate=&name=&address=&phone=&email=&reff=&grantype=&lead=&first=&stage=&assign='{
		# debugging message so we can see in the logs what HTTP_REFERER
		# looks like
		die "Boom! $ENV{'HTTP_REFERER'}";
	}else{
		# no referrer, or default url so we are deailing with the whole customer
		# table.
		$postsql = 'SELECT * from customer';
		# prepare the sql statement.
		$postresult = $dbh->prepare($postsql);
		# and execute it.
		$postresult->execute or die $postresult->errstr;
	}
	# prepare the updating sql statement outside the loop so we only do it once.
	my $upsql  = $dbh->prepare('UPDATE customer SET actdate = ?, name = ?, address = ?, phone = ?,email = ?, reff = ?, grantype = ?, lead = ?, first = ?, stage = ?, assign  = ? WHERE id = ?');
	#Step through the customers we're deailing with
	while (my $customer = $postresult->fetchrow_arrayref() ){
		# set the id field to the current one from the db row.
		my $id = $$customer[0];
		die $id;
		# if the row from the db ($customer) and the same info from the cgi
		# are the same, we don't need to update this row. the sorts are
		# there because the order doesn't really matter and this will still
		# w**k if we get the order wrong.
		next if (join ('', sort @$customer) eq join('', sort(
							 $id,
							  $parms->{"$id.actdate"},
							  $parms->{"$id.name"},
							  $parms->{"$id.address"},
							  $parms->{"$id.phone"},
							  $parms->{"$id.email"},
							  $parms->{"$id.reff"},
							  $parms->{"$id.grantype"},
							  $parms->{"$id.lead"},
							  $parms->{"$id.first"},
							  $parms->{"$id.stage"},
							  $parms->{"$id.assign"})));
		# else we need to update so execute the sql with the cgi parameters.
		die $parms->{"$id.name"};
		$upsql->execute($parms->{"$id.actdate"},
	                    $parms->{"$id.name"},
	                    $parms->{"$id.address"},
	                    $parms->{"$id.phone"},
	                    $parms->{"$id.email"},
	                    $parms->{"$id.reff"},
	                    $parms->{"$id.grantype"},
	                    $parms->{"$id.lead"},
	                    $parms->{"$id.first"},
	                    $parms->{"$id.stage"},
	                    $parms->{"$id.assign"},
						$id) or die "$upsql->errstr : $id";
	}
	# now we need to do something with the comments section and so forth
	# I've left his coment in as placeholder for all the old code I deleted
	
	# if we have any new cgi parameters then we need a new customer record.
	if ( $parms->{'newactdate'} ||
		$parms->{'newname'} ||
		$parms->{'newaddress'} ||
		$parms->{'newphone'} ||
		$parms->{'newemail'} ||
		$parms->{'newreff'} ||
		$parms->{'newgrantype'} ||
		$parms->{'newlead'} ||
		$parms->{'newfirst'} ||
		$parms->{'newstage'} ||
		$parms->{'newassign'}) {
		# prepare a sql statement for the INSET
		my $newcussth = $dbh->prepare( "INSERT customer (actdate, name, address, phone, email, reff, grantype, lead, first, stage, assign) VALUES (?,?,?,?,?,?,?,?,?,?,?)" );
		# execute is using the new parameters from the cgi
		$newcussth->execute( $parms->{'newactdate'},
						$parms->{'newname'},
						$parms->{'newaddress'},
						$parms->{'newphone'},
						$parms->{'newemail'},
						$parms->{'newreff'},
						$parms->{'newgrantype'},
						$parms->{'newlead'},
						$parms->{'newfirst'},
						$parms->{'newstage'},
						$parms->{'newassign'}) or die $newcussth->errstr;	
	}
	# disconnect from the db
	$dbh->commit();
	$dbh->disconnect();
	# isssue a redirect to the browser so the user knows something happened.
	# eventually this needs to be the referer url or if there isn't the ssss
	print $query->redirect('/cgi-bin//ssss.pl');
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
