#!/usr/bin/perl

use strict;
use warnings;

my $pquery = './src/package-query';
die "Unable to run $pquery\n" if (! -f $pquery || ! -x $pquery);

sub test_help_s()           { return qx($pquery -h 2>&1 > /dev/null); }
sub test_help_l()           { return qx($pquery --help 2>&1 > /dev/null); }
sub test_version()          { return qx($pquery -v); }
sub test_query()            { return qx($pquery -Q --nocolor); }
sub test_query_info()       { return qx($pquery -Qi perl --nocolor); }
sub test_query_search()     { return qx($pquery -Qs perl --nocolor); }
sub test_query_native()     { return qx($pquery -Qn --nocolor); }
sub test_query_foreign()    { return qx($pquery -Qm --nocolor); }
sub test_list_repo()        { return qx($pquery -L --nocolor); }
sub test_invalid()          { return qx($pquery -j 2>&1 > /dev/null); }

my $usage_pattern = 'Usage: package-query \[options\] \[targets \.\.\.\]';
my $perl_info_pattern = 'core\/perl (\d+\.?)+\-\d+ \(base\)';

# number of tests to run
use Test::Simple tests => 10;

ok( test_help_s()           =~ /$usage_pattern/,                        "Help info (-h)" );
ok( test_help_l()           =~ /$usage_pattern/,                        "Help info (--help)" );
ok( test_version()          =~ /package-query (\d+\.?)+/,               "Version info" );
ok( test_query()            =~ /$perl_info_pattern/,                    "Empty query" );
ok( test_query_info()       =~ /$perl_info_pattern/,                    "Query package info" );
ok( test_query_search()     =~ /$perl_info_pattern/,                    "Query-search package" );
ok( test_query_native()     =~ /$perl_info_pattern/,                    "Query native packages" );
ok( test_query_foreign()    =~ /local\/package-query-git (\d+\.?)+/,    "Query foreign packages" );
ok( test_list_repo()        =~ /core/,                                  "Repositories list" );
ok( test_invalid()          =~ /$pquery: invalid option \-\- \'j\'/,    "Invalid option (-j)" );
