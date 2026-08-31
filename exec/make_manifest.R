#!/usr/bin/env Rscript
#
# make_manifest.R: Generate a pkgfilecache manifest CSV from a directory of files.
#
# This script is a thin wrapper around pkgfilecache::manifest_cli() and contains
# no logic of its own, so it cannot get out of sync with the package. All
# command line arguments are passed through untouched.
#
# Usage:
#   Rscript make_manifest.R --dir <path> --out <path.csv> [--url-base <url>] [--help]
#
# Examples:
#   Rscript make_manifest.R --dir ~/mydata --out files.csv --url-base https://example.com/data/
#   Rscript make_manifest.R --help
#
# The same thing can be done without this script file, as a one-liner:
#   Rscript -e 'pkgfilecache::manifest_cli()' --args --dir ~/mydata --out files.csv --url-base https://example.com/data/
#
# On Unix-like systems this file is executable and can be run directly:
#   ./make_manifest.R --dir ~/mydata --out files.csv
# On Windows, always run it via Rscript (the shebang line is ignored there).

if (!requireNamespace("pkgfilecache", quietly = TRUE)) {
  msg = "The 'pkgfilecache' package is required to run this script, but it is not installed.\nInstall it with: install.packages('pkgfilecache')\n";
  cat(msg, file = stderr());
  quit(status = 1);
}

pkgfilecache::manifest_cli()
