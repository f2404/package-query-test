#!/usr/bin/perl

use strict;
use warnings;

my $pquery = './src/package-query';
die "Unable to run $pquery\n" if (! -f $pquery || ! -x $pquery);

sub test_help()         { return qx($pquery -h 2>&1 > /dev/null); }
sub test_version()      { return qx($pquery -v); }
sub test_query()        { return qx($pquery -Q --nocolor); }
sub test_list_repo()    { return qx($pquery -L --nocolor); }

# number of tests to run
use Test::Simple tests => 4;

ok( test_help()         =~ /Usage: package-query \[options\] \[targets \.\.\.\]/,   "Help info" );
ok( test_version()      =~ /package-query (\d+\.?)+/,                               "Version info" );
ok( test_query()        =~ /core\/perl (\d+\.?)+\-\d+ \(base\)/,                    "Empty query info" );
ok( test_list_repo()    =~ /core/,                                                  "Repositories list" );
