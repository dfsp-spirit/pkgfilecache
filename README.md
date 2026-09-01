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

pkgfilecache lets package authors offer optional data that users download over HTTP(S) and store locally in a permanent *package file cache*. Files are checked against MD5 sums and re-downloaded only if missing or mismatching.

## Installation

The [pkgfilecache package is on CRAN](https://CRAN.R-project.org/package=pkgfilecache):

```r
install.packages("pkgfilecache")
```


## How it works

You host the data files on a web server, tell pkgfilecache where they are, and your users download them with a single command and access them by local filename. For each file you provide:

* the full URL to the file
* the MD5 checksum (optional, but highly recommended)
* the local filename under which it will be stored in the package cache

There are two ways to specify the files, both shown below: directly in R code, or in a declarative manifest CSV generated from a directory of files.

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

You can also generate the manifest from your shell, without opening an interactive R session:

```bash
  Rscript -e 'pkgfilecache::manifest_cli()' --args --dir ~/yourpackage_data --out files.csv --url-base https://your.server/yourpackage/
```

The arguments mirror those of `write_manifest_from_dir()`: `--dir` (required), `--out` (required), `--url-base` (optional), and `--help`. Alternatively, run the shipped wrapper script `make_manifest.R` (get its path with `pkgfilecache::manifest_script()`), or download it from the [releases page](https://github.com/dfsp-spirit/pkgfilecache/releases) for a release tagged `<tag>`.

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

Yes — missing files are downloaded in parallel by default (via the `curl` multi interface, 2 simultaneous connections). Control it per call with `num_connections` (use `1` for strictly sequential downloads), or globally with `options(pkgfilecache.num_connections = N)`; an explicit argument always takes precedence. Failed downloads are retried up to `num_retries` times (default 2); set `num_retries = 0` to disable retrying.


#### Where are the files stored on disk?

Use `get_cache_dir(pkg_info)` to find out. The cache is a permanent directory, by default `tools::R_user_dir(packagename, "data")` (e.g., `~/.local/share/R/mypackage` on Linux). You can control the location with:

* `options(pkgfilecache.cachedir = "/some/dir")`: use `/some/dir` as the cache root (the package name is appended). Useful for ramdisks or network drives.
* `options(pkgfilecache.use_tempdir = TRUE)`: use a subdirectory of the R session's temporary directory, cleaned up automatically. Handy for unit tests and CI.

#### Can I submit a package that uses pkgfilecache to CRAN?

Yes — see the [vignette](https://dfsp-spirit.github.io/pkgfilecache/articles/pkgfilecache.html) for CRAN submission notes (intellectual property of downloaded files, not downloading without user-consent in package code, and unit test rules).


## Author and License

Written by [Tim Schäfer](https://ts.rcmd.org). Licensed under the [MIT license](./LICENSE).

## Alternatives

* [drat](https://journal.r-project.org/archive/2017/RJ-2017-026/index.html): host data in a CRAN-like repository.
* [BiocFileCache](https://www.bioconductor.org/packages/release/bioc/html/BiocFileCache.html) (BioConductor): similar idea, but not usable for CRAN packages.

