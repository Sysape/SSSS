#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;

# set up a few things
my $tt = Template->new({
    INCLUDE_PATH => '../templates',
        INTERPOLATE  => 1,
        }) || die "$Template::ERROR\n";

my  $vars = { copyright => 'released under the GPL 2009'};

$tt->process('quote.start.tmpl', $vars) || die $tt->error(), "\n";

