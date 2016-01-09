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

sub print_fail($$$$);
sub init_tests();
my @tests_list = init_tests();

# number of tests to run
use Test::Simple tests => 58;

my $locale = 'LC_ALL=C';
print "Running tests for $pquery ...\n";
for my $test (@tests_list) {
    my $out = qx($locale $pquery $test->{ARGS});
    my $res = ($out =~ /$test->{PTRN}/);
    $res &= ($out !~ /$test->{EXCL}/) if (defined $test->{EXCL});

    my ($argl, $outl, $resl) = ("", "", 1);
    if (defined $test->{OPTS}) {
        ($argl = $test->{ARGS}) =~ s/$test->{OPTS}{'short'}/$test->{OPTS}{'long'}/;
        $outl = qx($locale $pquery $argl);
        $resl = ($outl =~ /$test->{PTRN}/);
        $resl &= ($outl !~ /$test->{EXCL}/) if (defined $test->{EXCL});
    }

    ok($res, $test->{INFO});
    print_fail($pquery, $test->{ARGS}, $out, $test->{PTRN}) if !$res;
    print "#\n" if !$resl;
    print_fail($pquery, $argl, $outl, $test->{PTRN}) if !$resl;
}

# This function prints failed test info
sub print_fail($$$$) {
    my ($pquery, $args, $out, $pattern) = @_;
    print "#   command:  $pquery $args\n";
    print "#   got:      \"$out\"\n";
    print "#   expected: \"\/$pattern\/\"\n";
}

# This function intializes the tests list
# Test entry structure:
# ARGS - args for package-query, PTRN - result to check against, INFO - info on test
# EXCL (optional) - pattern that the output should not include
# OPTS (optional) - hash containing short and long forms of the same option
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
        ARGS =>  '-h 2>&1 > /dev/null',
        PTRN =>  'Usage: package-query \[options\] \[targets \.\.\.\]',
        INFO =>  'Help info',
        OPTS =>  {'short'=>'-h', 'long'=>'--help'},
    };
    push @tests, {
        ARGS =>  '-v',
        PTRN =>  'package-query (\d+\.?)+',
        INFO =>  'Version info',
        OPTS =>  {'short'=>'-v', 'long'=>'--version'},
    };
    push @tests, {
        ARGS =>  '-Qn -b /var/lib/pacman',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Database path option (valid path)',
        OPTS =>  {'short'=>'-b', 'long'=>'--dbpath'},
    };
    push @tests, {
        ARGS =>  "-Qn -b $dummy_path 2>&1 > /dev/null",
        PTRN =>  $alpm_failed_pattern,
        INFO =>  'Database path option (invalid path)',
        OPTS =>  {'short'=>'-b', 'long'=>'--dbpath'},
    };
    push @tests, {
        ARGS =>  '-Qn -c /etc/pacman.conf',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Config file path option (valid path)',
        OPTS =>  {'short'=>'-c', 'long'=>'--config'},
    };
    push @tests, {
        ARGS =>  "-Qn -c $dummy_path 2>&1 > /dev/null",
        PTRN =>  'Unable to open file: '.$dummy_path,
        INFO =>  'Config file path option (invalid path)',
        OPTS =>  {'short'=>'-c', 'long'=>'--config'},
    };
    push @tests, {
        ARGS =>  '-Qn -r /',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Root path option (valid path)',
        OPTS =>  {'short'=>'-r', 'long'=>'--root'},
    };
    push @tests, {
        ARGS =>  "-Qn -r $dummy_path 2>&1 > /dev/null",
        PTRN =>  $alpm_failed_pattern,
        INFO =>  'Root path option (invalid path)',
        OPTS =>  {'short'=>'-r', 'long'=>'--root'},
    };
    push @tests, {
        ARGS =>  '-L',
        PTRN =>  'core',
        INFO =>  'Repositories list',
        OPTS =>  {'short'=>'-L', 'long'=>'--list-repo'},
    };
    push @tests, {
        ARGS =>  '-Q',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Empty query',
        OPTS =>  {'short'=>'-Q', 'long'=>'--query'},
    };
    push @tests, {
        ARGS =>  '-Q -l',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'List local repositories contents (same as empty query)',
        OPTS =>  {'short'=>'-l', 'long'=>'--list'},
    };
    push @tests, {
        ARGS =>  '-Qs perl',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query-search package',
    };
    push @tests, {
        ARGS =>  '-Qi perl',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query - package info -i',
    };
    push @tests, {
        ARGS =>  '-Q perl --info',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query - package info --info',
    };
    push @tests, {
        ARGS =>  '-1Qi perl',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query - package info -i -1',
    };
    push @tests, {
        ARGS =>  '-Qi perl --just-one',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query - package info -i --just-one',
    };
    push @tests, {
        ARGS =>  '-Q --show-size perl',
        PTRN =>  'core/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\)',
        INFO =>  'Query - show package size',
    };
    push @tests, {
        ARGS =>  '-Qn',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query native packages -n',
    };
    push @tests, {
        ARGS =>  '-Q --native',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query native packages --native',
    };
    push @tests, {
        ARGS =>  '-Qm',
        PTRN =>  $local_package_query_pattern,
        INFO =>  'Query foreign packages -m',
    };
    push @tests, {
        ARGS =>  '-Q --foreign',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query foreign packages --foreign',
    };
    push @tests, {
        ARGS =>  '-Qe',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query explicitly installed packages -e',
    };
    push @tests, {
        ARGS =>  '-Q --explicit',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query explicitly installed packages --explicit',
    };
    push @tests, {
        ARGS =>  '-Qd',
        PTRN =>  $local_package_query_pattern,
        INFO =>  'Query packages installed as dependencies -d',
    };
    push @tests, {
        ARGS =>  '-Q --deps',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query packages installed as dependencies --deps',
    };
    push @tests, {
        ARGS =>  '-Qt',
        PTRN =>  'local/yaourt(-git)? (\d+\.?)+',
        INFO =>  'Query packages that are no more required -t',
    };
    push @tests, {
        ARGS =>  '-Q --unrequired',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query packages that are no more required --unrequired',
    };
    push @tests, {
        ARGS =>  '-Qu',
        PTRN =>  $empty,
        INFO =>  'Query packages upgrades -u',
    };
    push @tests, {
        ARGS =>  '-Q --upgrades',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query packages upgrades --upgrades',
    };
    push @tests, {
        ARGS =>  '-Qp /var/cache/pacman/pkg/perl-*',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query package as file',
    };
    push @tests, {
        ARGS =>  '-Q pacman --qdepends',
        PTRN =>  $local_package_query_pattern,
        INFO =>  'Query packages depending on the target',
    };
    push @tests, {
        ARGS =>  '-Q package-query --qprovides',
        PTRN =>  $local_package_query_pattern,
        INFO =>  'Query packages providing the target',
    };
    push @tests, {
        ARGS =>  '-Q perl --qrequires',
        PTRN =>  'core/db (\d+\.?)+\-\d+',
        INFO =>  'Query packages requiring the target',
    };
    push @tests, {
        ARGS =>  '-S kernel26-lts --qconflicts',
        PTRN =>  $linux_lts_pattern,
        INFO =>  'Query packages conflicting with the target',
    };
    push @tests, {
        ARGS =>  '-S kernel26-lts --qreplaces',
        PTRN =>  $linux_lts_pattern,
        INFO =>  'Query packages replacing the target',
    };
    push @tests, {
        ARGS =>  '-Ss perl',
        PTRN =>  $perl_info_pattern.' \[installed\]',
        INFO =>  'Search in official repositories -S',
    };
    push @tests, {
        ARGS =>  '-s perl --sync',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in official repositories --sync',
    };
    push @tests, {
        ARGS =>  '-S perl --search',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in official repositories --search',
    };
    push @tests, {
        ARGS =>  '-Ss perl --nameonly',
        PTRN =>  $tests[-1]->{PTRN},
        EXCL =>  'core/pcre (\d+\.?)+\-\d+',
        INFO =>  'Search in official repositories - nameonly option',
    };
    push @tests, {
        ARGS =>  '-Ss ^p\[e\]rl$',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in official repositories using regexp',
    };
    push @tests, {
        ARGS =>  '-Si perl',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search - package info',
    };
    push @tests, {
        ARGS =>  '-S --show-size perl',
        PTRN =>  'core/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\) \[installed\]',
        INFO =>  'Search - show package size',
    };
    push @tests, {
        ARGS =>  '-As package-query',
        PTRN =>  $package_query_pattern,
        INFO =>  'Search in AUR -A',
    };
    push @tests, {
        ARGS =>  '-s package-query --aur',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in AUR --aur',
    };
    push @tests, {
        ARGS =>  '-As package-query --insecure',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in AUR (insecure connection)',
    };
    push @tests, {
        ARGS =>  '-As package-query --sort name',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by name',
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort name',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by name',
    };
    push @tests, {
        ARGS =>  '-As package-query --sort date',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by date',
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort date',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by date',
    };
    push @tests, {
        ARGS =>  '-As package-query --sort size',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by size',
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort size',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by size',
    };
    push @tests, {
        ARGS =>  '-As package-query --sort vote',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by vote',
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort vote',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by vote',
    };
    push @tests, {
        ARGS =>  '-As package-query --aur-url https://aur.archlinux.org',
        PTRN =>  $package_query_pattern,
        INFO =>  'AUR URL option (valid)',
    };
    push @tests, {
        ARGS =>  '-As package-query --aur-url https://dummy 2>&1 > /dev/null',
        PTRN =>  'curl error: Couldn\'t resolve host name',
        INFO =>  'AUR URL option (invalid)',
    };
    push @tests, {
        ARGS =>  '-Qn -q',
        PTRN =>  $empty,
        INFO =>  'Quiet -q (no output)',
    };
    push @tests, {
        ARGS =>  '-Qn --quiet',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Quiet --quiet (no output)',
    };
    push @tests, {
        ARGS =>  '-j 2>&1 > /dev/null',
        PTRN =>  $pquery.': invalid option -- \'j\'',
        INFO =>  'Invalid option (-j)',
    };

    return @tests;
}
