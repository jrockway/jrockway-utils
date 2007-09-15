#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use List::Util qw(max);
use File::pushd;

# how to run "make test"
my %MAKE_TEST = ( 'Build.PL' => sub { 
                      `./Build >/dev/null 2>&1`;
                      my @lines = `./Build test 2>/dev/null`;
                      return ($? >> 8, @lines);
                  },
                  'Makefile.PL' => sub {
                      `make >/dev/null 2>&1`;
                      my @lines = `make test 2>/dev/null`;
                      return ($? >> 8, @lines);
                  },
                );

my %CLEANUP = ( 'Build.PL' => sub { `./Build distclean 2>/dev/null` },
                'Makefile.PL' => sub { `make distclean 2>/dev/null` },
              );

# stats
my $passed_dists = 0;
my $passed_files = 0;
my $passed_tests = 0;
my @failed;

# dists to check
my @dists = grep { -d } glob('*');
my $length = max(map { length } @dists);

for my $dist (@dists){

    # what we're testing
    print "$dist";
    print "."x($length - (length $dist) + 5);
    
    # test a dist; return success line on pass, die on failure
    my ($pass) = eval {
        my $pushd = pushd($dist) or die "Failed to chdir to $dist: $!";
        my ($builder) = grep { -e } keys %MAKE_TEST;
        die "No build file for $dist" unless $builder;
        `perl $builder >/dev/null 2>&1`; # taint mode loves this
        my ($status, @lines) = $MAKE_TEST{$builder}->();
        die "Tests failed" if $status;
        my ($stats) = grep { /Files=\d+/ } @lines;
        $stats =~ /Files=(\d+), Tests=(\d+)/;
        $passed_files += $1;
        $passed_tests += $2;
        $passed_dists ++;
        $CLEANUP{$builder}->();
        grep { /All tests successful/ } @lines;
    };

    # results for a single dist
    if($pass) {
        print "ok\n";
    }
    else {
        push @failed, $dist;
        $@ =~ s/ at .+$//;
        chomp $@;
        print "FAILED ($@)\n";
    }
}

# summary
my $how_many = $passed_tests < 1 ? 'No' : @failed ? 'Some' : 'All';
print "\n$how_many tests successful.\n";
print "Passing dists=$passed_dists, Passing files=$passed_files, Passing tests=$passed_tests\n";

if(@failed){
    print "FAILED DISTS: ". join ', ', @failed;
    print "\n";
}
