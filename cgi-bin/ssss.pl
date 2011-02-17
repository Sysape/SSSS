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
# this can probably be moved inside the else.
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
	# Existing clients are updated using the edit.pl form so this only needs
	# to add in new ones. It's being called via AJAJ so needs to return
	# a JSON object with the details of the database update to write back
	# to the ssss page
	my $reply;
	# and create json object to do the translations.
	my $json = JSON->new->allow_nonref;
	# if we have any of these new cgi parameters then we need a new customer
	# record.
	if ( $parms->{'newname'} ||
		$parms->{'newaddress'} ||
		$parms->{'newphone'} ||
		$parms->{'newemail'} ) {
		# prepare a sql statement for the INSET
		my $newcussth = $dbh->prepare( "INSERT customer (actdate, name, address, phone, email, reff, grantype, lead, first, stage, assign) VALUES (?,?,?,?,?,?,?,?,?,?,?)" );
		# execute the sql using the new parameters from the cgi
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
		# we might need to insert a comment so we need the id of the customet
		# we just inserted
		my $ins_id = $newcussth->{'mysql_insertid'};
		# if we have a newcomment then we need to add a comment using the
		# mysql_insertid which tells us what the customer id is
		if ($parms->{'newcomment'}){
			my $newcommsth = $dbh->prepare(
				'INSERT comment (custid, date, comment) VALUES (?,?,?)');
			$newcommsth->execute($ins_id,$parms->{'newdate'},
									$parms->{'newcomment'});
		}
		$reply = {id => $ins_id,
				  actdate => $parms->{'newactdate'},
				  name => $parms->{'newname'},
				  address => $parms->{'newaddress'},
				  phone => $parms->{'newphone'},
				  email => $parms->{'newemail'},
				  reff => $parms->{'newreff'},
				  grantype => $parms->{'newgrantype'},
				  lead => $parms->{'newlead'},
				  first => $parms->{'newfirst'},
				  stage => $parms->{'newstage'},
				  assign => $parms->{'newassign'}
				};
	}
	# disconnect from the db
	$dbh->commit();
	$dbh->disconnect();
	# send the JSON object back to the browser
	print $query->header('text/html');
	print $json->encode($reply);
	# isssue a redirect to the browser so the user knows something happened.
	# eventually this needs to be the referer url or if there isn't the ssss
	#my $redirect = $query->referer() || "/cgi-bin//ssss.pl";
	#print $query->redirect($redirect);
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

	# If we've not chosen the stage and not selected a single user by id we
	# probably only want ACTIVE jobs so set stage to ACTIVE
	unless ($parms->{'stage'}){
		$parms->{'stage'} = 'ACTIVE' unless $parms->{'id'};
	}
	
	
	# go through the list of is columns and see which are turned on in the
	# cgi parameters, add to the sql statement and the bind values
	foreach(@is){
		if ($parms->{$_} && $parms->{$_} ne 'ALL'){
			if ($sql =~ /WHERE/){
				# Special case for stage which can be ACTIVE and needs 3 values
				if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
					$sql .= " AND stage in ( ?, ?, ?, ?)";
					push(@bind, "quote");
					push(@bind, "first");
					push(@bind, "visited");
					push(@bind, "happen");
				}else{
					$sql .= " AND $_ = ?";
					push(@bind, $parms->{$_});
				}
			} else {
				if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
					$sql .= " WHERE stage in ( ?, ?, ?, ?)";
					push(@bind, "quote");
					push(@bind, "first");
					push(@bind, "visited");
					push(@bind, "happen");
				}else{
					$sql .= " WHERE $_ = ?";
					push(@bind, $parms->{$_});
				}
			}
		}
	}
	
	# Do a similar thing with the list of like parameters passed through from
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
	my $ref = $sth->fetchall_arrayref({});
	
	# We need to have a unique list of the items in the @is array from
	# the db
	# create a hashref to stick the data in.
	my $islist;
	foreach (@is) {
		# prepare the sql statement inside the loop as each one is different
		my $issth = $dbh->prepare("SELECT DISTINCT $_ FROM customer");
		$issth->execute() or die $issth->errstr;
		$islist->{$_} = $issth->fetchall_arrayref();
	}
	
	# we need to list the contents of the files dirs for each dir that
	# exists.
	my $files ;
	my @dirs = `ls -t ../files`;
	foreach (@dirs) {
		if (m/([\d]+)/){
			my @ls = `ls -t "../files/$1/"`;
			$files->{$1} = \@ls;
		}else{ carp "erroneous dir names $_.";}
	}
	my $vars = {
		copyright => 'released under the GPL 2008',
		columns => \@column,
		like => \@like,
		parms => $parms,
		customers => $ref,
#		comments => $commentref,
		today => $today,
		files => $files,
		islist => $islist
	};
	$tt->process('ssss.tmpl', $vars)
	    || die $tt->error(), "\n";
	
	$dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}
