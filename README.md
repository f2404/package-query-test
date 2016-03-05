# package-query-test
This project's purpose is to create a set of functional tests for archlinuxfr [package-query](https://github.com/archlinuxfr/package-query) utility.

The tests are running `package-query` with all options/keys supported and checking its output - whether it complies with the pre-defined pattern (regex is used to check the output).

## Usage
```
$ ./package-query-test.pl -h
Usage: ./package-query-test.pl [path to package-query]
   or: prove ./package-query-test.pl [path to package-query]
```
The script can be run directly - then it will provide the test results one-by-one:
```
ok 1 - Help info
ok 2 - Version info
ok 3 - Database path option (valid path)
ok 4 - Database path option (invalid path)
...
```
Or, the `prove` utility (it comes with `perl`) can be used - it will provide the fancy-formatted result ("All tests successful" in green):
```
$ prove ../package-query-test/package-query-test.pl 
../package-query-test/package-query-test.pl .. ok     
All tests successful.
Files=1, Tests=56, 23 wallclock secs ( 0.08 usr  0.01 sys + 15.58 cusr  1.11 csys = 16.78 CPU)
Result: PASS
```
