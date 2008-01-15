#!/usr/bin/env perl

use strict;
use warnings;
use File::pushd;
use Term::ReadLine;
use File::Slurp;
use IO::All;

# proj must never contain shell metachars kthx :)

my $proj = shift @ARGV;
my @args = @ARGV;
my $no_cat = grep { /^(?:-n|--no-cat(?:alyst)?)$/ } @args;

`catalystx-starter $proj`;
$proj =~ s/::/-/g;
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
    rename 'gitignore', '.gitignore';
    `git add * .gitignore`;
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
