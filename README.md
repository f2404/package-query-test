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
ok 1 - Help info (-h)
ok 2 - Help info (--help)
ok 3 - Version info
...
```
Or, the ```prove``` utility can be used (comes with ```perl```) - it will provide the fancy-formatted result ("All tests successful" in green):
```
$ prove ../package-query-test/package-query-test.pl 
../package-query-test/package-query-test.pl .. ok     
All tests successful.
Files=1, Tests=17,  2 wallclock secs ( 0.03 usr  0.00 sys +  1.99 cusr  0.11 csys =  2.13 CPU)
Result: PASS
```
