# pkgfilecache
*Download and cache optional data files for your R package — the R equivalent of Python's `pooch`.*

R package that allows package users to download and cache optional data files in a local directory.


<!-- badges: start -->
  [![R-CMD-check](https://github.com/dfsp-spirit/pkgfilecache/workflows/R-CMD-check/badge.svg)](https://github.com/dfsp-spirit/pkgfilecache/actions)
  [![pkgdown](https://img.shields.io/badge/pkgdown-website-green.svg)](https://dfsp-spirit.github.io/pkgfilecache/)
<!-- badges: end -->


## Features

- Automatically downloads optional data files on demand and caches them locally.
- Only re-downloads when a file is missing or its MD5 checksum does not match — no stale or duplicate downloads.
- Lets you ship large optional data outside the CRAN package size limit (5 MB).
- Declarative manifest (CSV) for managing many files, also usable from the command line.

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




## How it works

You specify a list of optional data files, and package users can download them with a single command from within R. For each file, you provide:

* a full URL to the file, hosted on some public web server
* the MD5 checksum of the file (optional, but highly recommended)
* a local filename, under which the file can be retrieved from the package cache

Users can then access the file by the local filename.

There are two ways to specify the file information: one directly in R code, and one in a manifest CSV file that can be auto-generated on the command line from a directory tree of files.

## Usage

There are two ways to specify which files pkgfilecache should manage, and both are shown below. The recommended approach — especially when your package has many optional data files — is to describe the files in a single declarative *manifest*. The classic, programmatic approach is to list the files directly in R code, which is quick and concise when you only have a handful of files.

### Recommended: Managing many files with a declarative manifest

Specifying files as three parallel vectors (local filenames, URLs, MD5 sums) is fine for a handful of files, but it gets tedious when your package has many optional data files. In that case, you can describe the files in a single declarative *manifest*, one row per file, either as a data.frame or as a CSV file shipped with your package.

A manifest has a `path` column (the file path relative to the package cache, using `/` as separator) and two optional columns: `url` (the download URL) and `md5` (the checksum). If the remote directory layout mirrors the local one, you can omit the `url` column and derive the URLs from a `base_url`:

```r
  # A small manifest as a data.frame: two files, URLs derived from base_url.
  manifest = data.frame(
    path = c("dir1/file1.txt", "dir2/file2.txt"),
    md5 = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de")
  );
  cfiles = pkgfilecache::ensure_files_available_from_manifest(pkg_info, manifest, base_url = "https://your.server/yourpackage/");
```

You can also ship the manifest as a CSV file in your package (e.g., in `inst/extdata`) and pass its path instead of a data.frame; comment lines starting with `#` are ignored. Use `read_manifest()` to inspect or validate a manifest.

To avoid computing MD5 sums by hand, generate the manifest from a local directory of files:

```r
  # Put your optional data files into a directory (subdirectories are preserved), then:
  pkgfilecache::write_manifest_from_dir(
    dir = "~/yourpackage_data",
    out = "inst/extdata/files.csv",
    url_base = "https://your.server/yourpackage/"
  );
  # The MD5 checksums are computed for you. Add the CSV to your package.
```

#### Generating the manifest from the command line

If you prefer working in a terminal, you can generate the manifest CSV directly from your shell, without opening an interactive R session. The package provides a small command line interface for this. The recommended way is to call `manifest_cli()` from `Rscript` in a one-liner; it reads the command line arguments for you:

```bash
  # One-liner, no script file needed:
  Rscript -e 'pkgfilecache::manifest_cli()' --args --dir ~/yourpackage_data --out files.csv --url-base https://your.server/yourpackage/
```

The arguments mirror those of `write_manifest_from_dir()`:

* `--dir <path>`: the directory containing your data files (required)
* `--out <path>`: the CSV file to write (required)
* `--url-base <url>`: optional base URL used to derive the download URLs
* `--help`: print usage information and exit

If you prefer a standalone script file, the package also ships a thin wrapper script called `make_manifest.R` (in the `exec` directory of the installed package) that does exactly the same thing. Get its path with `pkgfilecache::manifest_script()` and run it with `Rscript`:

```bash
  Rscript "$(Rscript -e 'cat(pkgfilecache::manifest_script())')" --dir ~/yourpackage_data --out files.csv --url-base https://your.server/yourpackage/
```

On Unix-like systems the script is executable, so you can copy it to a directory on your `PATH` (e.g. `~/bin`) and run it like a normal command. If you have not installed the package yet, you can also download the script directly from the GitHub releases page of this package (for a release tagged `<tag>`, use `https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/<tag>/exec/make_manifest.R`). Note that the package must be installed for the script to work, as the script itself only contains a thin wrapper around the package functions.

### The classic, programmatic way: Specifying files directly in R code

If you only have a handful of optional data files, you can skip the manifest and specify the files directly in R code: three parallel vectors with the local filenames (under which the files will be stored in the package cache), the download URLs, and — optional but highly recommended — the MD5 checksums. Pass them to `ensure_files_available()`, and the package downloads anything that is missing or whose MD5 sum does not match.

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

### Exposing the downloads to your users

Everything above describes how you, as a package author, tell pkgfilecache which files to manage. Those functions are low-level building blocks, though: your end users should not have to interact with pkgfilecache directly. The recommended pattern is to expose the downloads through a small, user-facing wrapper function in your own package, with a name and arguments that fit your package's domain. This also gives you a natural place to ask users to accept a license before anything is downloaded.

```r
  # In your package: a small user-facing wrapper around pkgfilecache.
  # This is the function your users will actually call.
  download_optional_data = function(accept_some_license = FALSE) {
    if (!isTRUE(accept_some_license)) {
      stop("Please accept the license first by calling download_optional_data(accept_some_license = TRUE).");
    }
    pkg_info = pkgfilecache::get_pkg_info("yourpackage");
    manifest_file = system.file("extdata", "files.csv", package = "yourpackage");  # generated with write_manifest_from_dir()
    cfiles = pkgfilecache::ensure_files_available_from_manifest(pkg_info, manifest_file);
    return(invisible(cfiles));  # the full paths of the downloaded files
  }
```

Your users can then simply call `yourpackage::download_optional_data(accept_some_license = TRUE)`. The manifest CSV generated by `write_manifest_from_dir()` already contains the `url` column (if you passed `url_base`), so no `base_url` is needed here.

See the vignette for more detailed examples!

## Documentation



Full documentation is built-in, and can be accessed from within R in the usual ways with the `help()` and `example()` functions. A vignette is also included:

```r
library("pkgfilecache")
browseVignettes("pkgfilecache")
```

You can also [read the pkgfilecache vignette online](https://dfsp-spirit.github.io/pkgfilecache/articles/pkgfilecache.html) and [read the full API docs online](https://dfsp-spirit.github.io/pkgfilecache/reference/index.html).


### FAQ

#### Can I download several files in parallel?

Short answer: Yes, and on recent versions that's actually the default. But you are in full control of parallelism if needed.

By default, `ensure_files_available()` downloads the files that are missing (or that have an incorrect MD5 sum) in parallel: several files are downloaded at the same time using the `curl` multi interface, which can speed up downloading many small files considerably. The number of simultaneous connections defaults to 2, which is a safe choice for most servers and for CRAN checks.

You can control the number of connections in two ways:

* Per call, via the `num_connections` argument of `ensure_files_available()`. Use `num_connections=1` for strictly sequential downloads (e.g., when a server is slow or rate-limited), or a higher number to speed up downloading many files.
* Globally, via the R option `options(pkgfilecache.num_connections = N)`. This changes the default for all calls that do not specify the `num_connections` argument themselves, for example the calls made by packages that use pkgfilecache to manage their optional data. Note that an explicit `num_connections` argument always takes precedence over the option.

Downloads that fail (e.g., because a server closes or throttles a connection) are retried automatically up to `num_retries` times (default 2) using fresh connections, so temporary network hiccups do not cause files to be reported as missing. Set `num_retries = 0` to disable retrying.


#### Where the files are stored on disk?

Short answer: Use `get_cache_dir(pkg_info)` to find out where the cache is located in your current session.

The package cache is a permanent directory on your system. By default it is located in the directory returned by `tools::R_user_dir(packagename, "data")` (for R version 4.0 or later), which is the location recommended by the CRAN repository policy for user-specific data and cache files (e.g., `~/.local/share/R/mypackage` on Linux). On R versions before 4.0, the directory returned by `rappdirs::user_data_dir` is used. If a cache from an older version of this package already exists at the legacy location, it is reused, so you do not have to download your files again.

You can control the location with R options:

* `options(pkgfilecache.cachedir = "/some/dir")`: Use `/some/dir` as the root of the package cache (the package name and optional version are appended). Useful for ramdisks or network drives.
* `options(pkgfilecache.use_tempdir = TRUE)`: Use a subdirectory of the R session's temporary directory (`tempdir()`). Everything is cleaned up automatically when the R session ends. This is handy for unit tests and CI systems that must not write to the user's home directory.

#### Is there anything I should be aware of if I want to submit my package to CRAN?

Short answer: most definitely, but in the end, it boils down to: know and adhere to the CRAN policy.

If you intend to submit a package using pkgfilecache to CRAN, read on:

Read the short and very informative [CRAN package policy](https://cran.r-project.org/web/packages/policies.html) first, it is mandatory in any case for CRAN submission. I will cite to very important sections here:

- *"The ownership of copyright and intellectual property rights of all components of the package must be clear and unambiguous [...]. All components’ includes any downloaded at installation or during use."*
- *"The code and examples provided in a package should never do anything which might be regarded as malicious or anti-social. The following are illustrative examples from past experience: [...] - Packages should not write in the user’s home filespace (including clipboards), nor anywhere else on the file system apart from the R session’s temporary directory (or during installation in the location pointed to by TMPDIR: and such usage should be cleaned up). Installing into the system’s R installation (e.g., scripts to its bin directory) is not allowed. Limited exceptions may be allowed in interactive sessions if the package obtains confirmation from the user. [...]*

Therefore:

* Make sure to document intellectual property info for files people can download. There are standard ways in R to do this, which you need to use. Putting something in the README of your package on GitHub is not enough.
* The intended way of using pkgfilecache is to **not** call the download function in your package code, but have it as part of your API that the user can decide to call *if* they want to download the optional data.
* If you are writing temp data, like during tests, explicitely set the output directory of pkgfilecache to the tempdir. The option is built-in ((set `options(pkgfilecache.use_tempdir = TRUE)`)).
* Some packages will want the extra data for unit tests only. You are of course free to call the download function in your *unit test code*, which will only be run by developers or continuous integration systems. But even in test code, that policy still holds to my understanding, so:
    - Write to a temp dir during tests (set `options(pkgfilecache.use_tempdir = TRUE)`)
    - Be aware of additional rules in special environments, like on the CRAN servers that will build and run the tests of your package as part of automated checks: Basically you must **not** run tests on CRAN servers that download data. Use the built-in mechanisms of your unit test framework to ensure that (e.g., `testthat::skip_on_cran()` to skip tests there that need external data).

That being said, there are various packages on CRAN that use pkgfilecache. In the end, all you need to do it to keep the CRAN policy in mind when submitting to CRAN, with or without pkgfilecache.


## Important note regarding data downloads on CRAN servers (e.g., during unit tests)

It is not allowed to store data in the user directory on CRAN servers, not even temporarily. So please do not use this package to download data into the user directory in unit tests on CRAN. In your test setup, set `options(pkgfilecache.use_tempdir = TRUE)` to redirect all downloads to the R session's temporary directory, which is allowed, or use `testthat::skip_on_cran()` at the top of test functions that require/download external data from running on CRAN. You should test on your CI provider instead, and limit CRAN unit tests to those with data that can be generated in the test code.

## Author and License

The pkgfilecache package was written by [Tim Schäfer](https://ts.rcmd.org).

It is licensed under the very permissable [MIT license](./LICENSE).

## Alternatives

* I haven't tried it myself, but according to [this article in the R journal](https://journal.r-project.org/archive/2017/RJ-2017-026/index.html), drat hosting of data could be an option.
* For BioConductor, there is [BiocFileCache](https://www.bioconductor.org/packages/release/bioc/html/BiocFileCache.html), but it's not gonna help you for CRAN.

