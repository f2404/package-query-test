#!/usr/bin/perl

use strict;
use warnings;

my $pquery = './src/package-query';
if ($ARGV[0] && ($ARGV[0] eq "-h" || $ARGV[0] eq "--help")) {
    die "Usage: $0 [path to package-query]\n   or: prove $0 [path to package-query]\n";
} elsif ($ARGV[0]) {
    $pquery = $ARGV[0];
}
die "Unable to run $pquery\n" if (! -f $pquery || ! -x $pquery);

sub init_tests();
my @tests_list = init_tests();

# number of tests to run
use Test::Simple tests => 57;

my $locale = 'LC_ALL=C';
print "Running tests for $pquery ...\n";
for my $test (@tests_list) {
    my $out = qx($locale $pquery $test->{COMMAND});
    my $res = ($out =~ /$test->{PATTERN}/);
    $res &= ($out !~ /$test->{EXCLUDE}/) if (defined $test->{EXCLUDE});
    ok( $res, $test->{INFO} );
    print "#   command:  $pquery $test->{COMMAND}\n" if (!$res);
    print "#   got:      \"$out\"\n" if (!$res);
    print "#   expected: \"$test->{PATTERN}\"\n" if (!$res);
}

# This function intializes the tests list
# Test entry structure:
# COMMAND - args for package-query, PATTERN - result to check against, INFO - info on test
# EXCLUDE (optional) - pattern that the output should not include
## TODO Better test for -Qu (upgrades)?
sub init_tests() {
    my $perl_info_pattern = 'core/perl (\d+\.?)+\-\d+ \(base\)';
    my $alpm_failed_pattern = 'failed to initialize alpm library \(could not find or read directory\)';
    my $local_package_query_pattern = 'local/package-query(-git)? (\d+\.?)+';
    my $package_query_pattern = 'aur/package-query (\d+\.?)+\-\d+( \[installed\: \S+\])? \(\d+\)';
    my $package_query_git_pattern = 'aur/package-query-git (\d+\.?)+\-\d+( \[installed: \S+\])? \(\d+\)';
    my $linux_lts_pattern = 'core/linux-lts (\d+\.?)+\-\d+';
    my $dummy_path = '/dummy/path';
    my $empty = '^$';
    my @tests;

    push @tests, {
        COMMAND =>  '-h 2>&1 > /dev/null',
        PATTERN =>  'Usage: package-query \[options\] \[targets \.\.\.\]',
        INFO =>     'Help info -h',
    };
    push @tests, {
        COMMAND =>  '--help 2>&1 > /dev/null',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Help info --help',
    };
    push @tests, {
        COMMAND =>  '-v',
        PATTERN =>  'package-query (\d+\.?)+',
        INFO =>     'Version info -v',
    };
    push @tests, {
        COMMAND =>  '--version',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Version info --version',
    };
    push @tests, {
        COMMAND =>  '-Qn -b /var/lib/pacman',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Database path option -b (valid path)',
    };
    push @tests, {
        COMMAND =>  '-Qn --dbpath /var/lib/pacman',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Database path option --dbpath (valid path)',
    };
    push @tests, {
        COMMAND =>  "-Qn -b $dummy_path 2>&1 > /dev/null",
        PATTERN =>  $alpm_failed_pattern,
        INFO =>     'Database path option -b (invalid path)',
    };
    push @tests, {
        COMMAND =>  "-Qn -dbpath $dummy_path 2>&1 > /dev/null",
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Database path option --dbpath (invalid path)',
    };
    push @tests, {
        COMMAND =>  '-Qn -c /etc/pacman.conf',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Config file path option -c (valid path)',
    };
    push @tests, {
        COMMAND =>  '-Qn --config /etc/pacman.conf',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Config file path option --config (valid path)',
    };
    push @tests, {
        COMMAND =>  "-Qn -c $dummy_path 2>&1 > /dev/null",
        PATTERN =>  'Unable to open file: '.$dummy_path,
        INFO =>     'Config file path option -c (invalid path)',
    };
    push @tests, {
        COMMAND =>  "-Qn --config $dummy_path 2>&1 > /dev/null",
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Config file path option --config (invalid path)',
    };
    push @tests, {
        COMMAND =>  '-Qn -r /',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Root path option -r (valid path)',
    };
    push @tests, {
        COMMAND =>  '-Qn --root /',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Root path option --root (valid path)',
    };
    push @tests, {
        COMMAND =>  "-Qn -r $dummy_path 2>&1 > /dev/null",
        PATTERN =>  $alpm_failed_pattern,
        INFO =>     'Root path option -r (invalid path)',
    };
    push @tests, {
        COMMAND =>  "-Qn --root $dummy_path 2>&1 > /dev/null",
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Root path option --root (invalid path)',
    };
    push @tests, {
        COMMAND =>  '-L',
        PATTERN =>  'core',
        INFO =>     'Repositories list -L',
    };
    push @tests, {
        COMMAND =>  '--list-repo',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Repositories list --list-repo',
    };
    push @tests, {
        COMMAND =>  '-Q',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Empty query -Q',
    };
    push @tests, {
        COMMAND =>  '--query',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Empty query --query',
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
        COMMAND =>  '-1Qi perl',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Query - package info with -1 option',
    };
    push @tests, {
        COMMAND =>  '-Q --show-size perl',
        PATTERN =>  'core/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\)',
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
        COMMAND =>  '-Qe',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Query explicitly installed packages',
    };
    push @tests, {
        COMMAND =>  '-Qd',
        PATTERN =>  $local_package_query_pattern,
        INFO =>     'Query packages installed as dependencies',
    };
    push @tests, {
        COMMAND =>  '-Qt',
        PATTERN =>  'local/yaourt(-git)? (\d+\.?)+',
        INFO =>     'Query packages that are no more required',
    };
    push @tests, {
        COMMAND =>  '-Qu',
        PATTERN =>  $empty,
        INFO =>     'Query packages upgrades',
    };
    push @tests, {
        COMMAND =>  '-Qp /var/cache/pacman/pkg/perl-*',
        PATTERN =>  $perl_info_pattern,
        INFO =>     'Query package as file',
    };
    push @tests, {
        COMMAND =>  '-Q pacman --qdepends',
        PATTERN =>  $local_package_query_pattern,
        INFO =>     'Query packages depending on the target',
    };
    push @tests, {
        COMMAND =>  '-Q package-query --qprovides',
        PATTERN =>  $local_package_query_pattern,
        INFO =>     'Query packages providing the target',
    };
    push @tests, {
        COMMAND =>  '-Q perl --qrequires',
        PATTERN =>  'core/db (\d+\.?)+\-\d+',
        INFO =>     'Query packages requiring the target',
    };
    push @tests, {
        COMMAND =>  '-S kernel26-lts --qconflicts',
        PATTERN =>  $linux_lts_pattern,
        INFO =>     'Query packages conflicting with the target',
    };
    push @tests, {
        COMMAND =>  '-S kernel26-lts --qreplaces',
        PATTERN =>  $linux_lts_pattern,
        INFO =>     'Query packages replacing the target',
    };
    push @tests, {
        COMMAND =>  '-Ss perl',
        PATTERN =>  $perl_info_pattern.' \[installed\]',
        INFO =>     'Search in official repositories',
    };
    push @tests, {
        COMMAND =>  '-Ss perl --nameonly',
        PATTERN =>  $tests[-1]->{PATTERN},
        EXCLUDE =>  'core/pcre (\d+\.?)+\-\d+',
        INFO =>     'Search in official repositories - nameonly option',
    };
    push @tests, {
        COMMAND =>  '-Ss ^p\[e\]rl$',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Search in official repositories using regexp',
    };
    push @tests, {
        COMMAND =>  '-Si perl',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Search - package info',
    };
    push @tests, {
        COMMAND =>  '-S --show-size perl',
        PATTERN =>  'core/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\) \[installed\]',
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
        PATTERN =>  $empty,
        INFO =>     'Quiet -q (no output)',
    };
    push @tests, {
        COMMAND =>  '-Qn --quiet',
        PATTERN =>  $tests[-1]->{PATTERN},
        INFO =>     'Quiet --quiet (no output)',
    };
    push @tests, {
        COMMAND =>  '-j 2>&1 > /dev/null',
        PATTERN =>  $pquery.': invalid option -- \'j\'',
        INFO =>     'Invalid option (-j)',
    };

    return @tests;
}
