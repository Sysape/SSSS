#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
use DBI;

my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

my $query = new CGI;
my $id = $query->param('id') or die "No id !";


my $vars = {
    copyright => 'released under the GPL 2008',
	id => $id
};

$tt->process('ssusure.tmpl', $vars) || die $tt->error(), "\n";
