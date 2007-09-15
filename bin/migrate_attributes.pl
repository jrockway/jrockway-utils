#!/usr/bin/perl
# migrate_attributes.pl 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use File::Attributes qw(unset_attributes get_attributes set_attributes);

my $filename = shift @ARGV;
die "Specify filename" if !$filename;
die "No file $filename" if !-e $filename;

foreach $filename ($filename, @ARGV){   
    my %attributes = get_attributes($filename);
    unset_attributes($filename, keys %attributes);
    set_attributes($filename, %attributes);
}
    exit(0);
