#!/usr/bin/perl

use strict;
use warnings;

my $pquery = './src/package-query';
die "Unable to run $pquery\n" if (! -f $pquery || ! -x $pquery);

my $usage_pattern = 'Usage: package-query \[options\] \[targets \.\.\.\]';
my $perl_info_pattern = 'core\/perl (\d+\.?)+\-\d+ \(base\)';

# Test entry structure:
# SUB - test function, PATTERN - result to check against, INFO - info on test

my $test_help_s = {
    SUB =>      sub { return qx($pquery -h 2>&1 > /dev/null); },
    PATTERN =>  $usage_pattern,
    INFO =>     'Help info (-h)',
};
my $test_help_l = {
    SUB =>      sub { return qx($pquery --help 2>&1 > /dev/null); },
    PATTERN =>  $usage_pattern,
    INFO =>     'Help info (--help)',
};
my $test_version = {
    SUB =>      sub { return qx($pquery -v); },
    PATTERN =>  'package-query (\d+\.?)+',
    INFO =>     'Version info',
};
my $test_query = {
    SUB =>      sub { return qx($pquery -Q --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Empty query',
};
my $test_query_info = {
    SUB =>      sub { return qx($pquery -Qi perl --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query package info',
};
my $test_query_search = {
    SUB =>      sub { return qx($pquery -Qs perl --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query-search package',
};
my $test_query_native = {
    SUB =>      sub { return qx($pquery -Qn --nocolor); },
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Query native packages',
};
my $test_query_foreign  = {
    SUB =>      sub { return qx($pquery -Qm --nocolor); },
    PATTERN =>  'local\/package-query-git (\d+\.?)+',
    INFO =>     'Query foreign packages',
};
my $test_list_repo = {
    SUB =>      sub { return qx($pquery -L --nocolor); },
    PATTERN =>  'core',
    INFO =>     'Repositories list',
};
my $test_invalid = {
    SUB =>      sub { return qx($pquery -j 2>&1 > /dev/null); },
    PATTERN =>  "$pquery: invalid option \-\- \'j\'",
    INFO =>     'Invalid option (-j)',
};

my @tests;
push @tests, $test_help_s;
push @tests, $test_help_l;
push @tests, $test_version;
push @tests, $test_query;
push @tests, $test_query_info;
push @tests, $test_query_search;
push @tests, $test_query_native;
push @tests, $test_query_foreign;
push @tests, $test_list_repo;
push @tests, $test_invalid;

# number of tests to run
use Test::Simple tests => 10;

for (@tests) {
    ok( $_->{SUB}->() =~ /$_->{PATTERN}/, $_->{INFO} );
}
