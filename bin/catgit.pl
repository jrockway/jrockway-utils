#!/usr/bin/env perl

use strict;
use warnings;
use File::pushd;
use Term::ReadLine;
use File::Slurp;
use IO::All;
use List::Util qw(first);

# proj must never contain shell metachars kthx :)

if(grep { /-(h|-help)/ } @ARGV){
    print "Usage: $0 [--no-cat | --empty] Module::Name\n";
    print " short version: [ -n | -! ]\n";
    exit 255;
}

my $proj = first { /^[^-]/ } @ARGV;
my $no_cat = grep { /^(?:-n|--no-cat(?:alyst)?)$/ } @ARGV;
my $plain = grep { /^(?:-!|--empty)/ } @ARGV;

if($plain && $no_cat){
    die q{Only specify 0 or 1 "--no-cat" or "--empty"};
}

if($plain){
    `mkdir $proj`;
    $proj > io("$proj/README");
}
else{
    `catalystx-starter $proj`;
}

$proj =~ s/::/-/g unless $plain; # not necessarily a perl project

{ 
    my $dir = pushd $proj;
    if($no_cat){
        `rm -rf t/live-test.t`;
        `rm -rf t/lib`;
        my $mf < io 'Makefile.PL';
        $mf =~ s/^(build_)?requires.+Catalyst.*\n//mg;
        $mf > io 'Makefile.PL';
    }
    `git init`;

    if($plain){
        `git add README`;
    }
    else {
        rename 'gitignore', '.gitignore';
        `git add * .gitignore`;
    }

    `git ci -m 'initial import'`;
}
my $orig = $proj;
$proj .= '.git';
{
    mkdir $proj;
    my $dir = pushd $proj;
    `git --bare init`;
    `git --bare fetch ../$orig master:master`;
    my $desc = Term::ReadLine->new($0)->readline('description> ');
    File::Slurp::write_file('description', $desc);
    `touch git-daemon-export-ok`;
}
`scp -r $proj stonepath:/git`;
`rm -rf $orig $proj`; # bye
`git clone ssh://git.jrock.us/git/$proj`;

print "done\n";
exit 0;
