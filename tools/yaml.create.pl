#!/usr/bin/perl -Tw

use strict;
use YAML::XS;

my $sql = {db=>'solsystest',
		   user=>'solsys',
		   pass=>'w0kk4'};

print Dump $sql;

