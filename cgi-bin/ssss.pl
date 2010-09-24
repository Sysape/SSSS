#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;
use YAML::XS;
use Data::Dumper;

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
	# so we're writing a quick and dirty update routine which will just update
	# every customer in the db, hopefully the db will be clever enough to not
	# bother actually updating tose records which haven't changed.

	# so the fields are all named in the table.format id.name, we'd probably
	# like it to be wadged into a hash where the first key is the table and 
	# the next id and the last is the field name.
	my $update;
	foreach(keys %{$parms}){
		next unless (/(\D+)(\d+)(\D+)/);
		$update->{$1}->{$2}->{$3} = $parms->{$_};
	}
	# so now we need to see what table we need to update and then build the
	# right sql statement for that table
	foreach my $table (keys %$update){
		if ($table == 'cust'){
			# prepare the updating sql statement outside the loop so we only
			# do it once.
			my $upsql  = $dbh->prepare('UPDATE customer SET actdate = ?, name = ?, address = ?, phone = ?,email = ?, reff = ?, grantype = ?, lead = ?, first = ?, stage = ?, assign  = ? WHERE id = ?');
		 	foreach(keys %{$update->{'cust'}}){
				$upsql->execute($update->{'cust'}->{$_}->{'actdate'},
	                    $update->{'cust'}->{$_}->{'name'},
	                    $update->{'cust'}->{$_}->{'address'},
	                    $update->{'cust'}->{$_}->{'phone'},
	                    $update->{'cust'}->{$_}->{'email'},
	                    $update->{'cust'}->{$_}->{'reff'},
	                    $update->{'cust'}->{$_}->{'grantype'},
	                    $update->{'cust'}->{$_}->{'lead'},
	                    $update->{'cust'}->{$_}->{'first'},
	                    $update->{'cust'}->{$_}->{'stage'},
	                    $update->{'cust'}->{$_}->{'assign'},
						$_) or die "$upsql->errstr : $_";
			}
		}elsif ($table == 'comm'){
			# do the same for the comment table
			my $upsql = $dbh->prepare('UPDATE comment SET comment = ?, date = ? WHERE id = ?');
			foreach(keys %{$update->{'comm'}}){
				$upsql->execute($update->{'comm'}->{$_}->{'comment'},
						$update->{'comm'}->{$_}->{'date'},
						$_) or die "$upsql->errstr : $_";
			}
		}else{
			die "invalid table specified in update loop \n";
		}
	}
	# now we need to do something with the new comments section and so forth
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
	my $redirect = $query->referer() || "/cgi-bin//ssss.pl";
	print $query->redirect($redirect);
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
	
	# get the comments for the customer ids we have.
	# start composing the SQL statemnet we need.
	my $commentsql = "SELECT * FROM comment" ;
	# declare an array to store the bind vars for the SQL
	my @commentbind;
	# Step through the $ref array and push all the customer ids onto
	# the bindvar array whilst also extending the SQL statment with
	# additional ? OR ?'s
	foreach (@$ref) {
		push (@commentbind, $_->{'id'});
		if ($commentsql =~ /WHERE/){
			$commentsql .= " OR ?";
		}else{
			$commentsql .= " WHERE custid = ?";
		}		
	}
	my $custsth = $dbh->prepare($commentsql);
	$custsth->execute(@commentbind) or die $custsth->errstr;
	my $commentref = $custsth->fetchall_arrayref({});
	
	
	my $vars = {
		copyright => 'released under the GPL 2008',
		columns => \@column,
		like => \@like,
		parms => $parms,
		customers => $ref,
		comments => $commentref,
	};
	
	$tt->process('ssss.tmpl', $vars)
	    || die $tt->error(), "\n";
	
	$dbh->disconnect or warn "Disconnection failed: $DBI::errstr\n";
}
