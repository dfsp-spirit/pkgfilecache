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
