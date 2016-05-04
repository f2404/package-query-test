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
use Test::Simple tests => 59;

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
sub init_tests() {
    my $perl_info_pattern = 'core/perl (\d+\.?)+\-\d+ \(base\)';
    my $alpm_failed_pattern = 'failed to initialize alpm library \(could not find or read directory\)';
    my $local_package_query_pattern = 'local/package-query(-git)? (\d+\.?)+';
    my $package_query_pattern = 'aur/package-query (\d+\.?)+\-\d+( \[installed\: \S+\])?( \(Out of Date\))? \(\d+\) \(\d+\.\d+\)';
    my $package_query_git_pattern = 'aur/package-query-git (\d+\.?)+\.r\d+\.[a-z0-9]{8}\-\d+( \[installed: \S+\])? \(\d+\) \(\d+\.\d+\)';
    my $dummy_path = '/dummy/path';
    my $pkgbase_target = 'linux-libre-lts';
    my $any_package = '\w+/\S+ (\d+\.?)+';
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
        ARGS =>  '-Q -i perl',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query - package info',
        OPTS =>  {'short'=>'-i', 'long'=>'--info'},
    };
    push @tests, {
        ARGS =>  '-Qi perl -1',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query - package info -1',
        OPTS =>  {'short'=>'-1', 'long'=>'--just-one'},
    };
    push @tests, {
        ARGS =>  '-Q --show-size perl',
        PTRN =>  'core/perl (\d+\.?)+\-\d+ \[\d+\.\d+ M\] \(base\)',
        INFO =>  'Query - show package size',
    };
    push @tests, {
        ARGS =>  '-Q -n',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query native packages',
        OPTS =>  {'short'=>'-n', 'long'=>'--native'},
    };
    push @tests, {
        ARGS =>  '-Q -m',
        PTRN =>  $local_package_query_pattern,
        INFO =>  'Query foreign packages',
        OPTS =>  {'short'=>'-m', 'long'=>'--foreign'},
    };
    push @tests, {
        ARGS =>  '-Q -e',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query explicitly installed packages',
        OPTS =>  {'short'=>'-e', 'long'=>'--explicit'},
    };
    push @tests, {
        ARGS =>  '-Q -d',
        PTRN =>  $local_package_query_pattern,
        INFO =>  'Query packages installed as dependencies',
        OPTS =>  {'short'=>'-d', 'long'=>'--deps'},
    };
    push @tests, {
        ARGS =>  '-Q -t',
        PTRN =>  'local/yaourt(-git)? (\d+\.?)+',
        INFO =>  'Query packages that are no more required',
        OPTS =>  {'short'=>'-t', 'long'=>'--unrequired'},
    };
    push @tests, {
        ARGS =>  '-Q -u',
        PTRN =>  "$empty|$any_package",
        INFO =>  'Query packages upgrades',
        OPTS =>  {'short'=>'-u', 'long'=>'--upgrades'},
    };
    push @tests, {
        ARGS =>  '-Qp /var/cache/pacman/pkg/perl-*',
        PTRN =>  $perl_info_pattern,
        INFO =>  'Query package as file',
        OPTS =>  {'short'=>'-p', 'long'=>'--file'},
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
        ARGS =>  '-S udev --qconflicts',
        PTRN =>  'core/systemd (\d+\.?)+\-\d+',
        INFO =>  'Query packages conflicting with the target',
    };
    push @tests, {
        ARGS =>  '-S udev --qreplaces',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Query packages replacing the target',
    };
    push @tests, {
        ARGS =>  '-s perl -S',
        PTRN =>  $perl_info_pattern.' \[installed\]',
        INFO =>  'Search in sync repositories (S/sync)',
        OPTS =>  {'short'=>'-S', 'long'=>'--sync'},
    };
    push @tests, {
        ARGS =>  '-S perl -s',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in sync repositories (s/search)',
        OPTS =>  {'short'=>'-s', 'long'=>'--search'},
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
        ARGS =>  '-s package-query -A',
        PTRN =>  $package_query_pattern,
        INFO =>  'Search in AUR',
        OPTS =>  {'short'=>'-A', 'long'=>'--aur'},
    };
    push @tests, {
        ARGS =>  '-As archlinuxfr --maintainer',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in AUR by maintainer',
    };
    push @tests, {
        ARGS =>  '-As package-query --insecure',
        PTRN =>  $tests[-1]->{PTRN},
        INFO =>  'Search in AUR (insecure connection)',
    };
    push @tests, {
        ARGS =>  '-As yaourt --nameonly',
        PTRN =>  'aur/yaourt (\d+\.?)+',
        EXCL =>  'aur/aurtab (\d+\.?)+',
        INFO =>  'Search in AUR - nameonly option',
    };
    push @tests, {
        ARGS =>  '-As package-query --sort n',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by name',
        OPTS =>  {'short'=>' n', 'long'=>' name'},
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort n',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by name',
        OPTS =>  {'short'=>' n', 'long'=>' name'},
    };
    push @tests, {
        ARGS =>  '-As package-query --sort 1',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by date',
        OPTS =>  {'short'=>' 1', 'long'=>' date'},
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort 1',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by date',
        OPTS =>  {'short'=>' 1', 'long'=>' date'},
    };
    push @tests, {
        ARGS =>  '-As package-query --sort 2',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by size',
        OPTS =>  {'short'=>' 2', 'long'=>' size'},
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort 2',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by size',
        OPTS =>  {'short'=>' 2', 'long'=>' size'},
    };
    push @tests, {
        ARGS =>  '-As package-query --sort w',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by vote',
        OPTS =>  {'short'=>' w', 'long'=>' vote'},
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort w',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by vote',
        OPTS =>  {'short'=>' w', 'long'=>' vote'},
    };
    push @tests, {
        ARGS =>  '-As package-query --sort p',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by popularity',
        OPTS =>  {'short'=>' p$', 'long'=>' pop'},
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort p',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by popularity',
        OPTS =>  {'short'=>' p$', 'long'=>' pop'},
    };
    push @tests, {
        ARGS =>  '-As package-query --sort r',
        PTRN =>  $package_query_pattern.'\n    Query ALPM and AUR\n'.$package_query_git_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - sort by relevance',
        OPTS =>  {'short'=>' r$', 'long'=>' rel'},
    };
    push @tests, {
        ARGS =>  '-As package-query --rsort r',
        PTRN =>  $package_query_git_pattern.'\n    Query ALPM and AUR\n'.$package_query_pattern.'\n    Query ALPM and AUR',
        INFO =>  'Search in AUR - reverse sort by relevance',
        OPTS =>  {'short'=>' r$', 'long'=>' rel'},
    };
    push @tests, {
        ARGS =>  '-As package-query git 2>&1',
        PTRN =>  $package_query_git_pattern,
        INFO =>  'Search in AUR - targets order',
        OPTS =>  {'short'=>'package-query git', 'long'=>'git package-query'},
    };
    push @tests, {
        ARGS =>  '-As git 2>&1',
        PTRN =>  '^AUR error : Too many package results.$',
        INFO =>  'Search in AUR - too many results',
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
        ARGS =>  '-Ai '.$pkgbase_target.' --pkgbase',
        PTRN =>  'aur/'.$pkgbase_target.' (\d+\.?)+',
        INFO =>  'AUR package info - pkgbase option (valid)',
    };
    push @tests, {
        ARGS =>  '-Ai '.$pkgbase_target.'-docs --pkgbase',
        PTRN =>  $empty,
        INFO =>  'AUR package info - pkgbase option (invalid)',
    };
    push @tests, {
        ARGS =>  '-Ai package-query -f "%i|%w|%o|%m|%L|%p|%u|%K|%e|%v|%d|%U"',
        PTRN =>  '\d+\|\d+\|[01]\|\w+?\|\d+\|\d+\.\d+\|.+?package-query[\.|\w]+?\|[\-|\w+]\|\w+\|\d+(\.\d+)?\-\d+\|Query ALPM and AUR\|https://github\.com/archlinuxfr/package-query/',
        INFO =>  'AUR package info - formatted',
        OPTS =>  {'short'=>'-f', 'long'=>'--format'},
    };
    push @tests, {
        ARGS =>  '-Ai package-query -f ""',
        PTRN =>  $empty,
        INFO =>  'AUR package info - formatted (empty output)',
        OPTS =>  {'short'=>'-f', 'long'=>'--format'},
    };
    push @tests, {
        ARGS =>  '-Qn -q',
        PTRN =>  $empty,
        INFO =>  'Quiet (no output)',
        OPTS =>  {'short'=>'-q', 'long'=>'--quiet'},
    };
    push @tests, {
        ARGS =>  '-j 2>&1 > /dev/null',
        PTRN =>  $pquery.': invalid option -- \'j\'',
        INFO =>  'Invalid option (-j)',
    };

    return @tests;
}
