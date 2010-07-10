#!/usr/bin/perl -Tw
# a comment to test git
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;
use List::Compare;
use Date::Calc qw( Today Month_to_Text English_Ordinal );
use YAML::XS;

# date first why not.
my ($year,$month,$day) = Today();

my $today = sprintf("%s %s, %d",
                English_Ordinal($day),
                Month_to_Text($month),
                $year);

#set up a few things

#Template path
my $tt = Template->new({
   INCLUDE_PATH => '../templates',
   INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

my $sqlconfig  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sqldetails = Load $sqlconfig;

my  $dbh = DBI->connect($$sqldetails{db}, $$sqldetails{user},
             $$sqldetails{pass},
           { RaiseError => 1, AutoCommit => 0 })
          or die "Database connection not made: $DBI::errstr";

my $query = new CGI;
my $prams = $query->Vars;

# We need to send some warnings back so lets make a hash for warnings
my ($warn, $ref);

my $custh = $dbh->prepare( "SELECT * from customer WHERE id = ?");
    $custh->execute($prams->{'custno'}) or die $custh->errstr;
my $customer = $custh->fetch;

#die "nee! $prams->{'custno'} $customer";

# We need to use this query a few times later so we'll declare it now

my $pansupsh = $dbh->prepare
 ("SELECT * FROM panels WHERE make = ? AND model = ? AND supplier = ?");

# might as well declare the one for invertes now too

my $invsupsh = $dbh->prepare
 ("SELECT * FROM inverters WHERE make = ? AND model = ? AND supplier = ?");

# The first thing we need to do is find out which supplier(s) we are ording
# from, so we check the suppliers of panels and inverters. 

my $pansh = $dbh->prepare
	("SELECT supplier FROM panels WHERE make = ? AND model = ?");
$pansh->execute(split(/ /,$prams->{'panels'},2)) or die $pansh->errstr;
my $pansup;  
while ($ref = $pansh->fetch){ push(@$pansup,@{$ref}); }

my $invsh = $dbh->prepare
		("SELECT supplier FROM inverters WHERE make = ? AND model = ?");
$invsh->execute(split(/ /,$prams->{'invs'},2)) or die $invsh->errstr;
my $invsup ;
while ($ref = $invsh->fetch){ push(@$invsup,@{$ref}); }

#die "$invsup AAAA $pansup BBBB $pansup->[0] foo $invsup->[0]";

# so we pack the refs into an array for later

my @compare = ($pansup, $invsup);

# inv1 and inv2 might be set as well so we check these too,

my ($invsup1, $invsup2);
if ($prams->{'numinv1'}){
	$invsh->execute(split(/ /,$prams->{'invs1'},2)) or die $invsh->errstr;
	while ($ref = $invsh->fetch){ push(@$invsup1,@{$ref}); }
	push(@compare, $invsup1);
}
if ($prams->{'numinv2'}){
	$invsh->execute(split(/ /,$prams->{'invs2'},2)) or die $invsh->errstr;
	while ($ref = $invsh->fetch){ push(@$invsup2,@{$ref}); }
	push(@compare, $invsup2);
}


# so now we create another array of suppliers that we can get all our kit from
# so we use List::Compare

my $lcm = List::Compare->new('-u', @compare);

my @kitsup = $lcm->get_intersection;
my @kitdie = $lcm->get_union;

#die "BANG $kitdie[0] $kitdie[1]";

# if there's now only one value in @kitsup then that is our supplier

my $supplier;
if ($#kitsup == 0){
	$supplier = $kitsup[0];
# if we haven't got any supplier capable of supplying all the kit
# in the next case we have to choose a supplier based on something else. 
# Probably the price of panels as they cost the most so.
}elsif (@kitsup) {
	my %suppliers;
	foreach (@kitsup){
		$pansupsh->execute(split(/ /,$prams->{'panels'},2),$_)
								or die $pansupsh->errstr;
		$suppliers{$pansupsh->fetchall_arrayref([-2])} = $_ ;
	}
	my @sort = sort { $a <=> $b } keys %suppliers;
	$supplier = $suppliers{shift @sort };
}else{
	die "brain failure!!!! $supplier @compare @kitsup wank! $invsup $pansup";
# Actually my brain hurts when this happens so we'll have to just warn for now
}

#Ok so now we can get on with calculating the prices of things

$pansupsh->execute(split(/ /,$prams->{'panels'},2), $supplier) 
								or die $pansupsh->errstr;
# This should only return one row.
 
my $paneldata;
while($ref = $pansupsh->fetch){ push(@$paneldata,@{$ref});}

# as we potentially need 3 different inverters I gunna write a sub for the
# inverter data gatherer.

my @invdata = invdata(split(/ /,$prams->{'invs'},2),$supplier);

my (@invdata1, @invdata2);

if ($prams->{'numinv1'}){
	@invdata1 = invdata(split(/ /,$prams->{'invs1'},2),$supplier);
}
if ($prams->{'numinv2'}){
	@invdata2 = invdata(split(/ /,$prams->{'invs2'},2),$supplier);
}
# We need the facing of the array in words

my ($facing, $sapfac);

if ($prams->{'facing'} eq 'S'){
	$facing = 'South'; $sapfac = 'S';
}elsif($prams->{'facing'} eq 'SE'){
	$facing = 'SouthEast'; $sapfac = 'Sx';
}elsif($prams->{'facing'} eq 'SW'){
	$facing = 'SouthWest'; $sapfac = 'Sx';
}elsif($prams->{'facing'} eq 'E'){
	$facing = 'East'; $sapfac = 'EW';
}elsif($prams->{'facing'} eq 'W'){
	$facing = 'West'; $sapfac = 'EW';
}elsif($prams->{'facing'} eq 'NE'){
	$facing = 'NorthEast'; $sapfac = 'Nx';
}elsif($prams->{'facing'} eq 'NW'){
	$facing = 'NorthWest'; $sapfac = 'Nx';
}elsif($prams->{'facing'} eq 'N'){
	$facing = 'North'; $sapfac = 'N';
}else{die "facing is borked";}

# so we need a table of data from the BRE's Standard assement procedure to
# work out the annual yield of our array.

my %annual = ( S=>{0=>933,30=>1042,45=>1023,60=>960,90=>724},
			Sx=>{0=>933,30=>997,45=>968,60=>900,90=>684},
			EW=>{0=>933,30=>886,45=>829,60=>753,90=>565},
			Nx=>{0=>933,30=>762,45=>666,60=>580,90=>485},
			N=>{0=>933,30=>709,45=>621,45=>485,90=>360},
		  	);

# So now we can get the radiation and work out the anuual power output like
# so.

my $output = 0.75 * $annual{$sapfac}->{$prams->{'pitch'}} * 
				$prams->{'numpanel'} * $paneldata->[3]/1000 ;
#then we round down to nearest 10 kWh

$output = int($output/10)*10;

# we need the type of Installation 
my $type;

if ($prams->{'mount'} eq 'RF'){
	$type = 'Retro-Fit';
}elsif ($prams->{'mount'} eq 'Semi'){
	$type = 'Semi-Integrated';
}elsif  ($prams->{'mount'} eq 'Bespoke'){
	$type = 'Bespoke';
}else{
	$type = 'Flat-Roof';
}

# okay so now be build an array of prices.

my $cost;

# panels

$cost->[0] = round($prams->{'markup'},
			$prams->{'numpanel'} * $paneldata->[3] * $paneldata->[7]);

# inverters

$cost->[1] = round($prams->{'markup'}, $prams->{'numinv'} * $invdata[2]);

# Ninja@Dead Souls <dchat> $result = $var == 0 ? 14 : 7
# Tique@Discworld <dchat> condition ? trueval : falseval;
# Ninja@Dead Souls <dchat> the test on "$var == 0" is first evaluated.
# Ninja@Dead Souls <dchat> if true, then result is 14, else 7


$cost->[2] = $prams->{'numinv1'} ? round($prams->{'markup'},
			$prams->{'numinv1'} * $invdata1[2]) : 0 ;

$cost->[3] = $prams->{'numinv2'} ? round($prams->{'markup'},
			$prams->{'numinv2'} * $invdata2[2]) : 0 ;

# we need to work out the mounting system cost, which will be a few lines
# so we'll do it here.

if ($prams->{'mount'} eq 'RF'){
	$cost->[4] = round($prams->{'markup'},800 * ($prams->{'numpanel'}/18));
}elsif($prams->{'mount'} eq 'Semi'){
	$cost->[4] = round($prams->{'markup'},1350 * ($prams->{'numpanel'}/18));
}elsif($prams->{'mount'} =~ 'U'){
	$cost->[4] = round($prams->{'markup'},1.2*(25*($prams->{'numpanel'}/1.5)));
}else{
	$cost->[4] = round($prams->{'markup'},1000 * ($prams->{'numpanel'}/18));
	$warn->{'mountcost'} =
		'The cost for the mounting system is based on nothing much really';
}

# Now the Balance of system

$cost->[5] = 100 + 200 * $prams->{'numinv'};

# and the Installation commisioning and admin.

$cost->[6] = int(600 * $prams->{'numpanel'} * $paneldata->[3]/10000)*10+510;

# the subtotal

$cost->[7] = $cost->[0] + $cost->[1] + $cost->[2] + $cost->[3] +
				$cost->[4] + $cost->[5] + $cost->[6];

# the VAT

my $vat = $customer->[6] eq 'st2' ? 15 : 5;

$cost->[8] = $cost->[7] * $vat /100 ;

# The Total

$cost->[9] = $cost->[7] + $cost->[8];

my $vars = {
    copyright => 'released under the GPL 2008',
	name => $customer->[1],
	address => $customer->[2],
	reff => $customer->[5],
	id => $customer->[0],
	size => $prams->{'numpanel'} * $paneldata->[3]/1000,
	type => $type,
	numpanel => $prams->{'numpanel'},
	panman => $paneldata->[1],
	panwatt => $paneldata->[3],
	pancost => $cost->[0], 
	numinv => $prams->{'numinv'},
	invman => $invdata[0],
	invtype => $invdata[1],
	invcost => $cost->[1],
	numinv1 => $prams->{'numinv1'},
	invcost1 => $cost->[2],
	invman1 => $invdata1[0],
	invtype1 => $invdata1[1],
	numinv2 => $prams->{'numinv2'},
	invman2 => $invdata2[0],
	invtype2 => $invdata2[1],
	invcost2 => $cost->[3],
	mountcost => $cost->[4],
	balcost => $cost->[5],
	icacost => $cost->[6],
	subtotal => $cost->[7],
	vatamount => $cost->[8],
	total => $cost->[9],
	facing => $facing,
	output => $output,	
	vat => $vat,
	date => $today,
};

$tt->process('quote.tmpl', $vars) || die $tt->error(), "\n";

$dbh->disconnect();

sub invdata {
# returns appostie inverter data from a db query.
	my ($invdata, $ref);
	$invsupsh->execute(@_) or die $invsup->errstr;
	while($ref = $invsupsh->fetch){push(@$invdata,@{$ref});}
	return ($invdata->[1], $invdata->[2],$invdata->[5],$invdata->[6]);
}

sub round {
# returns a value rounded to the next £10 will be in whole pounds and
# marksup the price by the markup
	my $markup = shift;
	my $price = shift;
	$markup = $markup/100 + 1;
	return ( (int($price * $markup / 10)*10) + 10); 
}
