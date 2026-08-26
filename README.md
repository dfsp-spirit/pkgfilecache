# pkgfilecache
R package that allows package users to download and cache optional data files in a local directory.


<!-- badges: start -->
  [![R-CMD-check](https://github.com/dfsp-spirit/pkgfilecache/workflows/R-CMD-check/badge.svg)](https://github.com/dfsp-spirit/pkgfilecache/actions)
  [![pkgdown](https://img.shields.io/badge/pkgdown-website-orange.svg)](https://dfsp-spirit.github.io/pkgfilecache/)
<!-- badges: end -->


## About

*Allow Users of Your Package to Download and Manage Optional Package Data*

This package allows you to give users of your package an easy way to download and manage optional data for your package. The data can be hosted on your webserver or any location accessible via HTTP(S) over the internet, and will be stored locally in a permanent directory called a *package file cache*. Checking of MD5 sums is supported, and re-downloading only ever occurs if MD5 sums mismatch if they are available.

## Installation

The [pkgfilecache package is on CRAN](https://CRAN.R-project.org/package=pkgfilecache), so you can simply:

```r
install.packages("pkgfilecache")
```


## Detailed Description

When package authors want to ship data for their package, they will quickly hit the package size limit on CRAN (which is 5 MB as of September 2019). The solution is to host the data elsewhere and download it on demand when the user requests it, then store it for future use. This is what pkgfilecache allows you to do. You can put your files onto a web server of your choice, take the MD5 sums, and have pkgfilecache download them locally. Files are automatically compared with the local package cache direcory, and only missing files or files with incorrect MD5 checksums will be downloaded. Users can then access the data in a convenient way, similar to accessing files shipped in `inst/extdata` via `system.file`. They can also erase the data if it is no longer needed.

The intended way of using pkgfilecache is to **not** call the download function in your package code, but have it as part of your API that the user can decide to call *if* they want to download the optional data. However, you are of course free to call the download function in your *unit test code*, which will only be run by developers or continuous integration systems.


## How it works

You specify a list of optional data files, and package users can download them with a single command from within R. For each file, you provide:

* a full URL to the file, hosted on some public web server
* the MD5 checksum of the file (optional, but highly recommended)
* a local filename, under which the file can be retrieved from the package cache

Users can then access the file by the local filename. See the documentation for details.


## Downloading files in parallel

By default, `ensure_files_available()` downloads the files that are missing (or that have an incorrect MD5 sum) in parallel: several files are downloaded at the same time using the `curl` multi interface, which can speed up downloading many small files considerably. The number of simultaneous connections defaults to 2, which is a safe choice for most servers and for CRAN checks.

You can control the number of connections in two ways:

* Per call, via the `num_connections` argument of `ensure_files_available()`. Use `num_connections=1` for strictly sequential downloads (e.g., when a server is slow or rate-limited), or a higher number to speed up downloading many files.
* Globally, via the R option `options(pkgfilecache.num_connections = N)`. This changes the default for all calls that do not specify the `num_connections` argument themselves, for example the calls made by packages that use pkgfilecache to manage their optional data. Note that an explicit `num_connections` argument always takes precedence over the option.

Downloads that fail (e.g., because a server closes or throttles a connection) are retried automatically up to `num_retries` times (default 2) using fresh connections, so temporary network hiccups do not cause files to be reported as missing. Set `num_retries = 0` to disable retrying.


## Where the files are stored

The package cache is a permanent directory on your system. By default it is located in the directory returned by `tools::R_user_dir(packagename, "data")` (for R version 4.0 or later), which is the location recommended by the CRAN repository policy for user-specific data and cache files (e.g., `~/.local/share/R/mypackage` on Linux). On R versions before 4.0, the directory returned by `rappdirs::user_data_dir` is used. If a cache from an older version of this package already exists at the legacy location, it is reused, so you do not have to download your files again.

You can control the location with R options:

* `options(pkgfilecache.cachedir = "/some/dir")`: Use `/some/dir` as the root of the package cache (the package name and optional version are appended). Useful for ramdisks or network drives.
* `options(pkgfilecache.use_tempdir = TRUE)`: Use a subdirectory of the R session's temporary directory (`tempdir()`). Everything is cleaned up automatically when the R session ends. This is handy for unit tests and CI systems that must not write to the user's home directory.

Use `get_cache_dir(pkg_info)` to find out where the cache is located in your current session.


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

You can also [read the pkgfilecache vignette online](https://dfsp-spirit.github.io/pkgfilecache/articles/pkgfilecache.html).



## Important note regarding data downloads on CRAN servers (e.g., during unit tests)

It is not allowed to store data in the user directory on CRAN servers, not even temporarily. So please do not use this package to download data into the user directory in unit tests on CRAN. In your test setup, set `options(pkgfilecache.use_tempdir = TRUE)` to redirect all downloads to the R session's temporary directory, which is allowed, or use `testthat::skip_on_cran()` at the top of test functions that require/download external data from running on CRAN. You should test on your CI provider instead, and limit CRAN unit tests to those with data that can be generated in the test code.

## License

MIT

## Alternatives

* I haven't tried it myself, but according to [this article in the R journal](https://journal.r-project.org/archive/2017/RJ-2017-026/index.html), drat hosting of data could be an option.
* For BioConductor, there is [BiocFileCache](https://www.bioconductor.org/packages/release/bioc/html/BiocFileCache.html), but it's not gonna help you for CRAN.

