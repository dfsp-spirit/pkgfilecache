# pkgfilecache: command line interface for generating a manifest.
#
# These functions let users generate a manifest CSV from a directory of files
# directly from the shell, without starting an interactive R session. The CLI
# is deliberately a thin wrapper around write_manifest_from_dir() and contains
# no logic of its own, so it cannot get out of sync with the package.
#
# There are two equivalent ways to use it:
#
#   1) As a package function, run from the command line with Rscript (no script
#      file needed):
#
#        Rscript -e 'pkgfilecache::manifest_cli()' --args --dir ~/mydata --out files.csv --url-base https://example.com/data/
#
#   2) As the standalone script that ships with the package (in the top-level
#      exec/ directory of the package, installed to the package's exec/ subdirectory),
#      which is a thin wrapper that just calls pkgfilecache::manifest_cli(). Get
#      its path with manifest_script().


#' @title Run the manifest generation command line interface (CLI).
#'
#' @description Generate a manifest CSV from a directory of files from the command line. This function is meant to be run with \code{Rscript}, not to be called interactively. It reads the command line arguments, parses them, and calls \code{\link{write_manifest_from_dir}}. It is the engine behind the standalone \code{make_manifest.R} script that ships with the package (see \code{\link{manifest_script}}).
#'
#' @param args character vector. The command line arguments. Defaults to the arguments actually passed to the R script (\code{commandArgs(trailingOnly = TRUE)}). You normally do not pass this; it exists to make the function testable.
#'
#' @details Supported arguments (each flag can be given as \code{--flag value} or as \code{--flag=value}):
#'   \itemize{
#'     \item \code{--dir <path>}: The directory containing the data files (required).
#'     \item \code{--out <path>}: The path of the CSV file to write the manifest to (required).
#'     \item \code{--url-base <url>}: Optional base URL used to derive the download URL of every file, as \code{paste0(url_base, path)}.
#'     \item \code{--help}: Print usage information and exit without generating anything.
#'   }
#'   A leading \code{--args} or \code{--} marker (used by \code{Rscript} to separate command line arguments from R options) is ignored, so both the one-liner form and the script form shown in the examples work.
#'
#' @return The generated manifest as a data.frame, invisibly, or \code{NULL} if \code{--help} was given.
#'
#' @examples
#'   \dontrun{
#'   # One-liner from the shell (no script file needed):
#'   Rscript -e 'pkgfilecache::manifest_cli()' --args --dir ~/mydata --out files.csv --url-base https://example.com/data/
#'
#'   # Same thing using the standalone script shipped with the package:
#'   Rscript "$(Rscript -e 'cat(pkgfilecache::manifest_script())')" --dir ~/mydata --out files.csv --url-base https://example.com/data/
#'   }
#'
#' @export
manifest_cli <- function(args = commandArgs(trailingOnly = TRUE)) {
  # Rscript -e and Rscript file.R pass the command line arguments differently:
  # with -e, a leading '--args' (or '--') marker is included in the args. We
  # simply ignore a single leading marker so that both forms work.
  if(length(args) > 0L && args[1L] %in% c("--args", "--")) {
    args = args[-1L];
  }

  if(any(args %in% c("--help", "-h"))) {
    cat(manifest_cli_usage(), sep = "\n");
    return(invisible(NULL));
  }

  dir_arg = NULL;
  out_arg = NULL;
  url_base_arg = NULL;

  i = 1L;
  n = length(args);
  while(i <= n) {
    arg = args[i];
    if(arg %in% c("--dir", "--out", "--url-base")) {
      if(i == n) {
        stop(sprintf("Argument '%s' requires a value.\n\n%s", arg, manifest_cli_usage()));
      }
      value = args[i + 1L];
      i = i + 1L;
      if(arg == "--dir") {
        dir_arg = value;
      } else if(arg == "--out") {
        out_arg = value;
      } else {
        url_base_arg = value;
      }
    } else if(startsWith(arg, "--dir=")) {
      dir_arg = substring(arg, 7L);
    } else if(startsWith(arg, "--out=")) {
      out_arg = substring(arg, 7L);
    } else if(startsWith(arg, "--url-base=")) {
      url_base_arg = substring(arg, 12L);
    } else {
      stop(sprintf("Unknown command line argument '%s'.\n\n%s", arg, manifest_cli_usage()));
    }
    i = i + 1L;
  }

  if(is.null(dir_arg)) {
    stop(sprintf("Missing required argument '--dir'.\n\n%s", manifest_cli_usage()));
  }
  if(is.null(out_arg)) {
    stop(sprintf("Missing required argument '--out'.\n\n%s", manifest_cli_usage()));
  }

  return(invisible(write_manifest_from_dir(dir = dir_arg, out = out_arg, url_base = url_base_arg)));
}


#' @title Get the usage message of the manifest generation CLI.
#'
#' @description Internal helper that returns the usage text printed by \code{\link{manifest_cli}} for \code{--help} and on errors.
#'
#' @return character vector with the usage text, one element per line.
#'
#' @keywords internal
manifest_cli_usage <- function() {
  return(c(
    "Usage: Rscript make_manifest.R --dir <path> --out <path.csv> [--url-base <url>] [--help]",
    "",
    "Generate a pkgfilecache manifest CSV from a directory of files.",
    "",
    "Arguments:",
    "  --dir <path>       Directory containing the data files (required).",
    "  --out <path>       Path of the CSV file to write (required).",
    "  --url-base <url>   Optional base URL used to derive download URLs.",
    "  --help             Print this usage information and exit.",
    "",
    "Example:",
    "  Rscript -e 'pkgfilecache::manifest_cli()' --args --dir ~/mydata --out files.csv --url-base https://example.com/data/"
  ));
}


#' @title Get the path of the standalone manifest generation script.
#'
#' @description Return the full path to the \code{make_manifest.R} script that ships with the package (installed into the package's \code{exec} subdirectory). This script is a thin wrapper around \code{\link{manifest_cli}} and can be run with \code{Rscript} to generate a manifest from the command line. On Unix-like systems you can also copy it to a directory on your \code{PATH} and make it executable with \code{chmod +x}, then run it like a normal command.
#'
#' @return character string. The full path to the script, or \code{""} if the script cannot be found (e.g., because the package is not installed correctly).
#'
#' @export
manifest_script <- function() {
  script_path = system.file("exec", "make_manifest.R", package = "pkgfilecache");
  return(script_path);
}
