#!/usr/bin/perl

use strict;
use warnings;

my $pquery = './src/package-query';
if ($ARGV[0] && ($ARGV[0] eq "-h" || $ARGV[0] eq "--help")) {
    die "Usage: $0 [path to package-query]\n";
} elsif ($ARGV[0]) {
    $pquery = $ARGV[0];
}
die "Unable to run $pquery\n" if (! -f $pquery || ! -x $pquery);

my $usage_pattern = 'Usage: package-query \[options\] \[targets \.\.\.\]';
my $perl_info_pattern = 'core\/perl (\d+\.?)+\-\d+ \(base\)';
my $dummy_path = '/dummy/path';

my @tests;
# Test entry structure:
# COMMAND - args for package-query, PATTERN - result to check against, INFO - info on test

push @tests, {
    COMMAND =>  '-h 2>&1 > /dev/null',
    PATTERN =>  $usage_pattern,
    INFO =>     'Help info (-h)',
};
push @tests, {
    COMMAND =>  '--help 2>&1 > /dev/null',
    PATTERN =>  $usage_pattern,
    INFO =>     'Help info (--help)',
};
push @tests, {
    COMMAND =>  '-v',
    PATTERN =>  'package-query (\d+\.?)+',
    INFO =>     'Version info',
};
push @tests, {
    COMMAND =>  '-L',
    PATTERN =>  'core',
    INFO =>     'Repositories list',
};
push @tests, {
    COMMAND =>  '-Q',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Empty query',
};
push @tests, {
    COMMAND =>  '-Ql',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'List local repositories contents (same as empty query)',
};
push @tests, {
    COMMAND =>  '-Qs perl',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query-search package',
};
push @tests, {
    COMMAND =>  '-Qi perl',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query - package info',
};
push @tests, {
    COMMAND =>  '-Q --show-size perl',
    PATTERN =>  'core\/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\)',
    INFO =>     'Query - show package size',
};
push @tests, {
    COMMAND =>  '-Qn',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query native packages',
};
push @tests, {
    COMMAND =>  '-Qm',
    PATTERN =>  'local\/package-query-git (\d+\.?)+',
    INFO =>     'Query foreign packages',
};
push @tests, {
    COMMAND =>  '-Qp /var/cache/pacman/pkg/perl-*',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query package as file',
};
push @tests, {
    COMMAND =>  '-Qn -b /var/lib/pacman',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Database path option (valid path)',
};
push @tests, {
    COMMAND =>  "-Qn -b $dummy_path 2>&1 > /dev/null",
    PATTERN =>  'failed to initialize alpm library \(could not find or read directory\)',
    INFO =>     'Database path option (invalid path)',
};
push @tests, {
    COMMAND =>  '-Qn -c /etc/pacman.conf',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Config file path option (valid path)',
};
push @tests, {
    COMMAND =>  "-Qn -c $dummy_path 2>&1 > /dev/null",
    PATTERN =>  "Unable to open file: $dummy_path",
    INFO =>     'Config file path option (invalid path)',
};
push @tests, {
    COMMAND =>  '-Ss perl',
    PATTERN =>  $perl_info_pattern.' \[installed\]',
    INFO =>     'Search in official repositories',
};
push @tests, {
    COMMAND =>  '-Si perl',
    PATTERN =>  $perl_info_pattern.' \[installed\]',
    INFO =>     'Search - package info',
};
push @tests, {
    COMMAND =>  '-S --show-size perl',
    PATTERN =>  'core\/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\) \[installed\]',
    INFO =>     'Search - show package size',
};
push @tests, {
    COMMAND =>  '-SAs package-query',
    PATTERN =>  'aur/package-query (\d+\.?)+\-\d+ \(\d+\)',
    INFO =>     'Search in AUR',
};
push @tests, {
    COMMAND =>  '-Qn -q',
    PATTERN =>  '^$',
    INFO =>     'Quiet (no output)',
};
push @tests, {
    COMMAND =>  '-j 2>&1 > /dev/null',
    PATTERN =>  "$pquery: invalid option \-\- \'j\'",
    INFO =>     'Invalid option (-j)',
};

# number of tests to run
use Test::Simple tests => 22;

print "Running tests for $pquery ...\n";
for (@tests) {
    my $res = ok( qx($pquery $_->{COMMAND}) =~ /$_->{PATTERN}/, $_->{INFO} );
    print "#   command: $pquery $_->{COMMAND}\n" if (!$res);
}
