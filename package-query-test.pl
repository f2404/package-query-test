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
my $alpm_failed_pattern = 'failed to initialize alpm library \(could not find or read directory\)';
my $local_package_query_pattern = 'local\/package-query(-git)? (\d+\.?)+';
my $package_query_pattern = 'aur/package-query (\d+\.?)+\-\d+( \[installed\: \S+\])? \(\d+\)';
my $package_query_git_pattern = 'aur/package-query-git (\d+\.?)+\-\d+( \[installed: \S+\])? \(\d+\)';
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
    PATTERN =>  $local_package_query_pattern,
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
    PATTERN =>  $alpm_failed_pattern,
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
    COMMAND =>  '-Qn -r /',
    PATTERN =>  $perl_info_pattern,
    INFO =>     'Root path option (valid path)',
};
push @tests, {
    COMMAND =>  "-Qn -r $dummy_path 2>&1 > /dev/null",
    PATTERN =>  $alpm_failed_pattern,
    INFO =>     'Root path option (invalid path)',
};
push @tests, {
    COMMAND =>  '-Q pacman --qdepends',
    PATTERN =>  $local_package_query_pattern,
    INFO =>     'Query packages depending on target',
};
push @tests, {
    COMMAND =>  '-Q package-query --qprovides',
    PATTERN =>  $local_package_query_pattern,
    INFO =>     'Query packages providing target',
};
push @tests, {
    COMMAND =>  '-Ss perl',
    PATTERN =>  $perl_info_pattern.' \[installed\]',
    INFO =>     'Search in official repositories',
};
push @tests, {
    COMMAND =>  '-Ss ^p\[e\]rl$',
    PATTERN =>  $perl_info_pattern.' \[installed\]',
    INFO =>     'Search in official repositories using regexp',
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
    COMMAND =>  '-As package-query',
    PATTERN =>  $package_query_pattern,
    INFO =>     'Search in AUR',
};
push @tests, {
    COMMAND =>  '-As package-query --insecure',
    PATTERN =>  $package_query_pattern,
    INFO =>     'Search in AUR (insecure connection)',
};
push @tests, {
    COMMAND =>  '-As package-query --sort name',
    PATTERN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - sort by name',
};
push @tests, {
    COMMAND =>  '-As package-query --rsort name',
    PATTERN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - reverse sort by name',
};
push @tests, {
    COMMAND =>  '-As package-query --sort date',
    PATTERN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - sort by date',
};
push @tests, {
    COMMAND =>  '-As package-query --rsort date',
    PATTERN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - reverse sort by date',
};
push @tests, {
    COMMAND =>  '-As package-query --sort size',
    PATTERN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - sort by size',
};
push @tests, {
    COMMAND =>  '-As package-query --rsort size',
    PATTERN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - reverse sort by size',
};
push @tests, {
    COMMAND =>  '-As package-query --sort vote',
    PATTERN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - sort by vote',
};
push @tests, {
    COMMAND =>  '-As package-query --rsort vote',
    PATTERN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
    INFO =>     'Search in AUR - reverse sort by vote',
};
push @tests, {
    COMMAND =>  '-As package-query --aur-url https://aur.archlinux.org',
    PATTERN =>  $package_query_pattern,
    INFO =>     'AUR URL option (valid)',
};
push @tests, {
    COMMAND =>  '-As package-query --aur-url https://dummy 2>&1 > /dev/null',
    PATTERN =>  'curl error: Couldn\'t resolve host name',
    INFO =>     'AUR URL option (invalid)',
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
use Test::Simple tests => 38;

print "Running tests for $pquery ...\n";
for (@tests) {
    my $res = ok( qx($pquery $_->{COMMAND}) =~ /$_->{PATTERN}/, $_->{INFO} );
    print "#   command: $pquery $_->{COMMAND}\n" if (!$res);
}
