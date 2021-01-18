# pkgfilecache
GNU R package that allows package users to download and cache optional data files in a local directory.

## About

*Allow Users of Your Package to Download and Manage Optional Package Data*

This package allows you to give users of your package an easy way to download and manage optional data for your package. The data can be hosted anywhere, and will be stored locally in a permanent directory called a *package file cache*. Checking of MD5 sums is supported.

## Installation

The [pkgfilecache package is on CRAN](https://CRAN.R-project.org/package=pkgfilecache), so you can simply:

```r
install.packages("pkgfilecache")
```


## Detailed Description

When package authors want to ship data for their package, they will quickly hit the package size limit on CRAN (which is 5 MB as of September 2019). The solution is to host the data elsewhere and download it on demand when the user requests it, then store it for future use. This is what pkgfilecache allows you to do. You can put your files onto a web server of your choice, take the MD5 sums, and have pkgfilecache download them locally. Files are automatically compared with the local package cache direcory, and only missing files or files with incorrect MD5 checksums will be downloaded. Users can then access the data in a convenient way, similar to accessing files shipped in `inst/extdata` via `system.file`. They can also erase the data if it is no longer needed.

## How it works

You specify a list of optional data files, and package users can download them with a single command from within GNU R. For each file, you provide:

* a full URL to the file, hosted on some public web server
* the MD5 checksum of the file (optional, but highly recommended)
* a local filename, under which the file can be retrieved from the package cache

Users can then access the file by the local filename. See the documentation for details.


## Example

See the vignette for more detailed examples!

```r
  pkg_info = pkgfilecache::get_pkg_info("yourpackage");        # to identify the cache dir

  ### Specify your optional data:
  # 1) How the files should be called in the local package file cache
  local_filenames = c("file1.txt", "file2.txt");
  # 2) Where they can be downloaded
  urls = c("https://your.server/yourpackage/large_file1.txt", "https://your.server/yourpackage/large_file2.txt");
  # 3) Optional, but highly recommended: MD5 checksums for the files.
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");    

  # Now use the package cache to get the files. Will only download if needed (file missing or MD5 mismatch):
  cfiles = pkgfilecache::ensure_files_available(pkg_info, local_filenames, urls, md5sums=md5sums);
  
  # Great, now let's access a file:
  local_file_full_path = pkgfilecache::get_filepath(pkg_info, "file1.txt", mustWork=TRUE);
```



## Documentation

Full documentation is built-in, and can be accessed from within R in the usual ways. A vignette is also included:

```r
library("pkgfilecache")
browseVignettes("pkgfilecache")
```

You can also [read the pkgfilecache vignette online at CRAN](https://cran.r-project.org/web/packages/pkgfilecache/vignettes/pkgfilecache.html).
 

## Build status

Unit tests can be run locally using `devtools::check()`, and CI is running on Travis for Linux and AppVeyor for Windows:

[![Build Status](https://travis-ci.org/dfsp-spirit/pkgfilecache.svg?branch=master)](https://travis-ci.org/dfsp-spirit/pkgfilecache)

[![AppVeyor build status](https://ci.appveyor.com/api/projects/status/github/dfsp-spirit/pkgfilecache?branch=master&svg=true)](https://ci.appveyor.com/project/dfsp-spirit/pkgfilecache)


## A note regarding CRAN checks and pkgfilecache

This is only relevant if you are using *pkgfilecache* in the unit tests or examples of your package **and** want to publish your package to CRAN.

On the CRAN test servers, it is not allowed to write data into the user home of the user that runs the unit tests -- but doing exactly that is the purpose of the *pkgfilecache* package!

Currently, only the CRAN build hosts running MacOS seem to enforce this. So for MacOS, you will get a build error on the CRAN status page for your package. The solution is to disable the respective unit tests for MacOS on CRAN. You can check whether a test is currently being run under these conditions, and skip it only then. The test will still run on your local machine and on your continuous integration server. Here is a function that checks the condition:

```r
tests_running_on_cran_under_macos <- function() {
  return(tolower(Sys.info()[["sysname"]]) == 'darwin' && !identical(Sys.getenv("NOT_CRAN"), "true"));
}
```

You can use this function to skip the test when appropriate. How to do that depends on your test suite, here is an example for the popular `testthat` suite. You would use the function from above in your test file, e.g., in `your_package/tests/testthat/test-whatever.R`, like this:

```r
test_that("We can do stuff that requires optional data to be tested", {

  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS, required test data cannot be downloaded.");
  
  # Download your test data here.
  # Perform your testing here.
}
```

## An Update regarding CRAN (Jan 2021)

CRAN seems to enforce now that (January 2021) that the installation, unit tests and checks on their machines do not leave behind any files in the user directory. This is no problem, but it means that *if* you use this package to download test data onto CRAN servers (typically for the unit tests you run during package submission process), you will have to make sure you delete those data afterwards.

If you use testthat, this can be done in a teardown file in tests/testthat/. See the testthat documentation, or have a look at [how I do it for my freesurferformats package here](https://github.com/dfsp-spirit/freesurferformats/blob/master/tests/testthat/teardown-cran.R). Make sure you only delete the data on the CRAN servers though: if your users have downloaded it, they most likely do not want it deleted just because they ran the unit tests!

## License

MIT
