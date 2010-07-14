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

#set up a new CGI and get the parameters passed through from the browser
my $query = new CGI;
my $parms = $query->Vars;
my $order = $parms->{'order'}|| 'id';

# create an array to store the bind variables for the sql statement coming
my @bind; 

#start creating the sql statement to get all the customer info
my $sql = "SELECT * FROM customer";

# go through the list of is columns and see which are turned on in the
# cgi parameters, add to the sql statement and the bind values
foreach(@is){
	if ($parms->{$_} ne 'ALL' && $parms->{$_}){
		if ($sql =~ /WHERE/){
			if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
			# Special case for stage which can be ACTIVE and needs 3 values
				$sql .= " AND stage in ( ?, ?, ?)";
				push(@bind, "quote");
				push(@bind, "first");
				push(@bind, "happen");
			}else{
				$sql .= " AND $_ = ?";
				push(@bind, $_);
			}
		} else {
			if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
				$sql .= " WHERE stage in ( ?, ?, ?)";
				push(@bind, "quote");
				push(@bind, "first");
				push(@bind, "happen");
			}else{
				$sql .= " WHERE $_ = ?";
				push(@bind, $_);
			}
		}
	}
}

# Do a similar think with the list of like parameters passed through from
# the cgi.
foreach(@like){
	if ($parms->{$_} ne 'ALL' && $parms->{$_}){
		if ($sql =~ /WHERE/){
			$sql .= " AND $_ LIKE ?";
			push(@bind, "\%$_\%");
		} else {
			$sql .= " WHERE $_ LIKE ?";
			push(@bind, "\%$_\%");
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
	comments => $commentref
	
};

$tt->process('ssss.tmpl', $vars)
    || die $tt->error(), "\n";
