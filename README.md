# package-query-test
This project's purpose is to create a set of functional tests for archlinuxfr's [package-query](https://github.com/archlinuxfr/package-query) utility.

The tests are running ```package-query``` with all options/keys supported and checking its output - whether it complies with the pre-defined patterns (usually, regexps are used).

## Usage
```
$ ./package-query-test.pl -h
Usage: ./package-query-test.pl [path to package-query]
```
The script can be run directly - then it will provide the test results one-by-one:
```
ok 1 - Help info
ok 2 - Version info
ok 3 - Database path option (valid path)
ok 4 - Database path option (invalid path)
...
```
Or, the ```prove``` utility (it comes with ```perl```) can be used - it will provide the fancy-formatted result ("All tests successful" in green):
```
$ prove ../package-query-test/package-query-test.pl 
../package-query-test/package-query-test.pl .. ok     
All tests successful.
Files=1, Tests=51, 19 wallclock secs ( 0.05 usr  0.00 sys + 13.62 cusr  1.11 csys = 14.78 CPU)
Result: PASS
```
