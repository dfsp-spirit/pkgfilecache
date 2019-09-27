# pkgfilecache
GNU R package that allows package authors to cache data files in user directories.

## About

This package allows you to download data required for your package to a directory in the user home. The data can be hosted anywhere, and you have to give an URL for it. Checking of MD5 sums is supported. This is useful for package authors who need to ship more than the 5 MB of data currently allowed by CRAN.

## Detailed Description

When package authors want to ship data for their package, they will quickly hit the package size limit on CRAN (which is 5 MB as of September 2019). The solution is to host the data elsewhere and download it on demand, but store it once it has been downloaded. This is what pkgfilecache allows you to do. You can put your files onto a web server of your choice, take the MD5 sums, and have pkgfilecache download them locally unless they already exist and have the correct MD5 hash. You can then access them in a convenient way, similar to files shipped in `inst/extdata`. One could download the files every time to a temporary directory, but that clearly does not make sense in many cases. This package permanently stores the files under a subdir of the directory returned by `rappdirs::user_data_dir`. For my Ubuntu Linux system, that is `/home/myuser/.local/share`, but that should not bother you and you should not care about it.

## Documentation

Full documentation is built-in, and can be accessed from within R in the usual ways. A vignette is also included:

```r
library("pkgfilecache")
browseVignettes("pkgfilecache")
```
 

## Build status

[![Build Status](https://travis-ci.org/dfsp-spirit/pkgfilecache.svg?branch=master)](https://travis-ci.org/dfsp-spirit/pkgfilecache)
