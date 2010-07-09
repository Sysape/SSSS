#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;

#set up a few things
my $tt = Template->new({
   INCLUDE_PATH => '../templates',
   INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

my $query = new CGI;
my $prams = $query->Vars;

#Most of the data for this passed by the cgi, we need only calculate the 
#sub-total vatamaount and total

#die "$prams->{'pancost'} + $prams->('invcost') + $prams->('balcost') + $prams->('icacost')";

#my @k;
#@k = sort keys %$prams;
#die "@k";

#die "incost1: $prams->{'invcost1'} :: $prams->{'invcost'} :: $prams->{'invcost1'}";

my $subtotal = $prams->{'pancost'} + $prams->{'invcost'} + $prams->{'balcost'} + $prams->{'icacost'} + $prams->{'mountcost'};
$subtotal += $prams->{'invcost1'} if ($prams->{'invcost1'});
$subtotal += $prams->{'invcost2'} if ($prams->{'invcost2'});

my $vatamount = $prams->{'VAT'} * $subtotal / 100 ;
my $total = $subtotal + $vatamount;

my ($numinv1, $invcost1, $invman1, $invtype1);
my ($numinv2, $invcost2, $invman2, $invtype2);

my $vars = {
    copyright => 'released under the GPL 2008',
	name => $prams->{'nameadd'},
	reff => $prams->{'reff'},
	id => $prams->{'id'},
	size => $prams->{'size'},
	type => $prams->{'type'},
	numpanel => $prams->{'numpanel'},
	panman => $prams->{'panman'},
	panwatt => $prams->{'panwatt'},
	pancost => $prams->{'pancost'},
	numinv => $prams->{'numinv'},
	invman => $prams->{'invman'},
	invtype => $prams->{'invtype'},
	invcost => $prams->{'invcost'},
	numinv1 => $prams->{'numinv1'},
	invcost1 => $prams->{'invcost1'},
	invman1 => $prams->{'invman1'},
	invtype1 => $prams->{'invtype1'},
	numinv2 => $prams->{'numinv2'},
	invman2 => $prams->{'invman2'},
	invtype2 => $prams->{'invtype2'},
	invcost2 => $prams->{'invcost2'},
	mountcost => $prams->{'mountcost'},
	balcost => $prams->{'balcost'},
	icacost => $prams->{'icacost'},
	subtotal => $subtotal,
	vatamount => $vatamount,
	total => $total,
	facing => $prams->{'facing'},
	output => $prams->{'output'},	
	vat => $prams->{'VAT'},
	date => $prams->{'date'},

};

#die "Total:$vars->{'total'}";

#die "$prams->{'final'}";

if ($prams->{'final'}){
	$tt->process('quote.final.tmpl', $vars) || die $tt->error(), "\n";
}else{
	$tt->process('quote.tmpl', $vars) || die $tt->error(), "\n";
}

sub round {
# returns a value rounded so the VAT will be in whole pounds and marksup the
# price by the markup
	my $markup = shift;
	my $price = shift;
	$markup = $markup/100 + 1;
	return ( (int($price * $markup / 10)*10) + 10); 
}
