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


my $sqlconfig  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails = Load $sqlconfig;

#The next 3 mys should probably go in some kind of inheretied conf file.
my @column =
qw(id actdate name address phone email reff grantype lead first stage assign);
	# list of columns in order.
my @like = qw(id name address phone email reff);
	# list of columns to text search
my @is = qw(actdate grantype lead first stage assign);
	# list of columns to drop-down index. 
	# NB columns can only be on one of these lists, Thinks will break if
	# they're on both.

my $query = new CGI;
my $parms = $query->Vars;
my $order = $parms->{'order'}|| 'id';
my @active; # To store which options are in use.

my $sql = "SELECT * FROM customer";

foreach(@is){
	if ($parms->{$_} ne 'ALL' && $parms->{$_}){
		if ($sql =~ /WHERE/){
			if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
			# Special case for stage which can be ACTIVE and needs 3 values
				$sql .= " AND stage in ( ?, ?, ?)";
			}else{
				$sql .= " AND $_ = ?";
			}
			push(@active, $_);
		} else {
			if ($_ eq 'stage' && $parms->{$_} eq 'ACTIVE'){
				$sql .= " WHERE stage in ( ?, ?, ?)";
			}else{
				$sql .= " WHERE $_ = ?";
			}
			push(@active, $_);
		}
	}
}
foreach(@like){
	if ($parms->{$_} ne 'ALL' && $parms->{$_}){
		if ($sql =~ /WHERE/){
			$sql .= " AND $_ LIKE ?";
			push(@active, $_);
		} else {
			$sql .= " WHERE $_ LIKE ?";
			push(@active, $_);
		}
	}
}
$sql = $sql." ORDER BY $order";

my $vars = {
	copyright => 'released under the GPL 2008',
	sql => "$sql",
	column => \@column,
	parms => $parms,
	active => \@active,
	like => \@like,
	is => \@is,
	dbname => '$sqldetails=>db',
	dbuser => '$sqldetails=>user',
	dbpass => '$sqldetails=>pass'
};

$tt->process('ssss.tmpl', $vars)
    || die $tt->error(), "\n";
