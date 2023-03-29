# Find redundant null-checks in java file

## Usage

```shell
ruby <source>/check_file.rb file_to_check.java
```

Checker will print the file name and the line number of the redundant check.  
E.g. `Null check is always true: tests/Example2.java:7`

## Run tests
```shell
ruby <source>/tests/run_tests.rb --glob "<source>/tests/*.java"
```
