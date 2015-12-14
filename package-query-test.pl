#!/usr/bin/perl

use strict;
use warnings;

my $pquery = './src/package-query';
die "Unable to run $pquery\n" if (! -f $pquery || ! -x $pquery);

my $usage_pattern = 'Usage: package-query \[options\] \[targets \.\.\.\]';
my $perl_info_pattern = 'core\/perl (\d+\.?)+\-\d+ \(base\)';
my $dummy_path = '/dummy/path';

my @tests;
# Test entry structure:
# SUB - test function, PATTERN - result to check against, INFO - info on test

push @tests, {
    SUB =>      sub { return qx($pquery -h 2>&1 > /dev/null); },
    PATTERN =>  $usage_pattern,
    INFO =>     'Help info (-h)',
};
push @tests, {
    SUB =>      sub { return qx($pquery --help 2>&1 > /dev/null); },
    PATTERN =>  $usage_pattern,
    INFO =>     'Help info (--help)',
};
push @tests, {
    SUB =>      sub { return qx($pquery -v); },
    PATTERN =>  'package-query (\d+\.?)+',
    INFO =>     'Version info',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Q --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Empty query',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qi perl --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query package info',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qs perl --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query-search package',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qn --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query native packages',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qm --nocolor); },
    PATTERN =>  'local\/package-query-git (\d+\.?)+',
    INFO =>     'Query foreign packages',
};
push @tests, {
    SUB =>      sub { return qx($pquery -L --nocolor); },
    PATTERN =>  'core',
    INFO =>     'Repositories list',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qn --nocolor -b /var/lib/pacman); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Database path option (valid path)',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qn --nocolor -b $dummy_path 2>&1 > /dev/null); },
    PATTERN =>  'failed to initialize alpm library \(could not find or read directory\)',
    INFO =>     'Database path option (invalid path)',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qn --nocolor -c /etc/pacman.conf); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Config file path option (valid path)',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qn --nocolor -c $dummy_path 2>&1 > /dev/null); },
    PATTERN =>  "Unable to open file: $dummy_path",
    INFO =>     'Config file path option (invalid path)',
};
push @tests, {
    SUB =>      sub { return qx($pquery -Qn -q); },
    PATTERN =>  '^$',
    INFO =>     'Quiet (no output)',
};
push @tests, {
    SUB =>      sub { return qx($pquery -j 2>&1 > /dev/null); },
    PATTERN =>  "$pquery: invalid option \-\- \'j\'",
    INFO =>     'Invalid option (-j)',
};

# number of tests to run
use Test::Simple tests => 15;

for (@tests) {
    ok( $_->{SUB}->() =~ /$_->{PATTERN}/, $_->{INFO} );
}
