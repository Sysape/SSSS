#!/usr/bin/perl -Tw

use strict;
use YAML::XS;

my $config  = do{local(@ARGV,$/)='../conf/sql.yaml';<>};
my $sql = Load $config;

print Dump $sql;
