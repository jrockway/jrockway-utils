#!/usr/bin/env perl

use strict;
use warnings;
use File::pushd;
use Term::ReadLine;
use File::Slurp;

# proj must never contain shell metachars kthx :)

my $proj = shift @ARGV;
`catalystx-starter $proj`;
$proj =~ s/::/-/g;
{ 
    my $dir = pushd $proj;
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
