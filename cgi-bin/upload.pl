#!/usr/bin/perl -Tw

# Copyright Michael J G Day, 2010 
# contact via code[at]gatrell[dot]org 

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use CGI qw(:standard);
use URI;
use CGI::Carp;
use URI::QueryParam;
use JSON;
use Template;

my $uploaddir = '../files';

my $in = new CGI;

# We're adding in a get request handler to display the files so we need to
# see how we were called.
# Read in text and convert to all caps.
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
if ($ENV{'REQUEST_METHOD'} eq "POST"){
	
	# because the filuploader.js submits data as application/octet-stream the
	# file data will be in POSTDATA and the query string will not be accessible
	# using CGI's param or Vars methods.
	
	my $file = $in->param('POSTDATA');
	
	# get the URI from the environment.
	
	my $url = $ENV{'REQUEST_URI'};
	
	my $uri = URI->new($url, "http");
	
	# so now we create a hash of the params
	my $params = $uri->query_form_hash;
	
	# create a vars for the JSON reply
	my $reply;
	
	# and create json object to do the translations.
	my $json = JSON->new->allow_nonref;
	
	# set the customer directory to the cust cgi parameter.
	my $custdir = $params->{'cust'};
	# set the filename to the qqfile dgi parameter.
	my $filename = $params->{'qqfile'};
	# now we need to detaint the directory name and file name
	unless ($filename =~ /^[\w\.]+$/ && $custdir =~ /^[\w\.]+$/){
		 $reply = {error => "Illegal characters in filename - please only use [A-Z] [a-z] [0-9] . and _"};
	}
	
	mkdir("$uploaddir/$custdir", 0775) or carp "mkdir failed: $!\n";
	
	
	print $in->header('application/json');
	
	# if the reply var has been already set it's an error.
	
	if ($reply)	{
		print $json->encode($reply);
	}else{
		# set message to sucess message
		$reply = {success => JSON::true};
		# open the file for writing or set reply to failure
		open(WRITEIT, ">$uploaddir/$custdir/$filename") or
		 $reply = {error => "Cant write to $uploaddir/$custdir/$filename. Reason: $!"};
		print WRITEIT $file;
		close(WRITEIT);
		# write to logfile about failure.
		carp $json->encode($reply) if (keys (%$reply) eq "error");
		# return error to browser via json.
		print $json->encode($reply);
	}
}else{
	# setup a template directory
	my $tt = Template->new({ INCLUDE_PATH => '../templates',
	}) || die "$Template::ERROR\n";
	# get the query vars
	my $parms = $in->Vars;
	# create a var for the list of files.
	my $files;
	# Detaint the path
	$ENV{'PATH'} = '/bin:/usr/bin';
	#we first test to see if there is a dir for this client
	if (-e "../files/$parms->{'custid'}"){
		# detaint the custid
		if ($parms->{'custid'} =~ /([\d]+)/){
			@$files = `ls -t "../files/$1/"`;
			chomp @$files;
		}
	}
	# prepare the vars for the template 
	my $vars = {
		custid => $parms->{'custid'},
		files => $files
	};
	$tt->process('upload.tmpl', $vars) || carp $tt->error(), "\n";
}
