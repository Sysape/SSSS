#!/usr/bin/perl -Tw
use strict;
use CGI;  # don't reinvent the wheel
use Template;
my $tt = Template->new({
    INCLUDE_PATH => '../templates',
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";

my $query = new CGI;
my $length = $query->param('len');
my $width = $query->param('wid');
my $print_format = $query->param('sort');
my $roof_type = $query->param('flat');
my @results;
open MODULES, "modules";

if ($length) {
	while (<MODULES>) {
       	 next if /^\s?#/;
       	 chomp;
       	 my @line = split ( /\s*,\s*/, $_ );
       	 if ($roof_type == 0) { # pitched roof bit.
       	         my $use_length = $length - $width/10;
       	         my $use_width = $width - $length/100;
       	         my @temp = pitchcalc ($use_length, $use_width, @line);
       	         push @results, [ $temp[0], $line[4], $line[5], $temp[1], "Watts", "£", $temp[2], "landscape", $line[6], $temp[3],"x",$temp[4]];
       	         @temp = pitchcalc ($use_width, $use_length, @line);
       	         push @results, [ $temp[0], $line[4], $line[5], $temp[1], "Watts", "£", $temp[2], "portrait", $line[6], $temp[3],"x",$temp[4]];
       	 } elsif ($roof_type == 1 ) { # flat roof section
       	 # For wind loading reasons we don't want to be in the edge zone.
       	         my $use_length = $length - $width/10;
       	         my $use_width = $width - $length/10;
       	 # We're doing this for 20deg unistand first. We'll need another IF here
       	          my @temp = flatcalc ($use_width, $use_length, 20, @line);
       	          push @results, [ $temp[0], $line[4], $line[5], $temp[1], "Watts", "£", $temp[2], "portrait", $line[6], $temp[3],"x",$temp[4]];
       	          @temp = flatcalc ($use_length, $use_width, 20, @line);
       	          push @results, [ $temp[0], $line[4], $line[5], $temp[1], "Watts", "£", $temp[2], "landscape", $line[6], $temp[3],"x",$temp[4]];
       	 } else { die "RTFM!"}
	@results = order ($print_format, @results);
	}
}
my $vars = {
		copyright => 'released under the GPL 2008',
		result => \@results
};

$tt->process('spac.tmpl', $vars)
    || die $tt->error(), "\n";

sub pitchcalc {
        my $len = shift;
        my $wid = shift;
        my @line = @_;
        my $pan_length = int ( $len/$line[0] );
        my $pan_width = int ( $wid/$line[1] );
        my $pan_total = $pan_width*$pan_length ;
        my $output = $pan_total*$line[2] ;
        my $cost = $output*$line[3] ;
        return $pan_total, $output, $cost, $pan_length, $pan_width;
}

sub flatcalc {
        my $len = shift;
        my $wid = shift;
        my $pit = shift;
        my @line = @_;
        my $proj_length = $line[0]*cos$pit;
        my $gap_length = $line[0]*sin$pit/tan(25);
        my $pan_length = int ( $len/($proj_length + $gap_length));
my $gap_length = $line[0]*sin$pit/tan(25);
        my $pan_length = int ( $len/($proj_length + $gap_length));
        $pan_length++ if ($pan_length*$gap_length + ($pan_length++)*$proj_length < $len);
        my $pan_width = int ( $wid/$line[1] );
        my $pan_total = $pan_width*$pan_length ;
        my $output = $pan_total*$line[2] ;
        my $cost = $output*$line[3] ;
        return $pan_total, $output, $cost, $pan_length, $pan_width;;
}

sub tan { sin($_[0]) / cos($_[0])  }

sub order {
        my $print_format = shift;
        my @results = sort { $a->[$print_format] <=> $b->[$print_format] } @_ ;
        return @results;
}
 
