# pkgfilecache: declarative file manifests.
#
# These functions let package authors describe the optional data files they
# want to manage with a single declarative manifest (one row per file) instead
# of maintaining three parallel vectors (relative filenames, URLs, and MD5
# checksums) in their package code. A manifest is either a CSV file shipped
# with the package (e.g., in inst/extdata), or a data.frame. This is purely
# additive: all existing functions keep working unchanged.


#' @title Read a file manifest for optional data files.
#'
#' @description Read a manifest that describes a set of optional data files, one file per row. A manifest is either a CSV file or a data.frame with the columns described below. Manifests can be written by hand or generated with \code{\link{write_manifest_from_dir}}.
#'
#' @param manifest string or data.frame. The manifest to read: either the path to a CSV file, or a data.frame that is used directly. Comment lines in a CSV manifest that start with \code{#} are ignored.
#'
#' @param base_url string or NULL. A base URL used to derive the download URL for all files that do not have an explicit URL. For such files, the URL is set to \code{paste0(base_url, path)}. This is convenient when the remote directory layout mirrors the layout inside the package cache. Files with an explicit \code{url} entry are never modified.
#'
#' @details The manifest must contain a column named \code{path}, giving the file path relative to the package cache directory, using \code{/} as separator. Two further columns are optional:
#'   \itemize{
#'     \item \code{url}: The remote URL to download the file from. If empty (or missing), it is derived from \code{base_url} (see above).
#'     \item \code{md5}: The MD5 checksum of the file, used to verify file integrity. If empty (or missing), no integrity check is performed for that file (only its existence is checked).
#'   }
#'   Additional columns are allowed and ignored.
#'
#' @return data.frame with the columns \code{path}, \code{url} and \code{md5}. The \code{url} column never contains missing values after this function ran: either it was present in the input, or it was derived from \code{base_url} and \code{path}. The \code{md5} column may contain \code{NA} for files without a checksum.
#'
#' @export
read_manifest <- function(manifest, base_url = NULL) {
  if(is.data.frame(manifest)) {
    m = manifest;
  } else if(is.character(manifest) && length(manifest) == 1L) {
    if(!file.exists(manifest)) {
      stop(sprintf("Manifest file '%s' does not exist.\n", manifest));
    }
    m = utils::read.csv(manifest, comment.char = "#", check.names = FALSE, stringsAsFactors = FALSE, strip.white = TRUE, encoding = "UTF-8");
  } else {
    stop("Parameter 'manifest' must be a data.frame or the path to a CSV file.");
  }

  m = validate_manifest(m);
  m = derive_manifest_urls(m, base_url);
  return(m);
}


#' @title Validate a file manifest.
#'
#' @description Check a manifest data.frame for well-formedness, normalize the path and optional columns, and reject paths that would leave the package cache. Used internally by \code{\link{read_manifest}}.
#'
#' @param manifest data.frame. The manifest to validate.
#'
#' @return data.frame. The validated and normalized manifest.
#'
#' @keywords internal
validate_manifest <- function(manifest) {
  if(!is.data.frame(manifest)) {
    stop("Manifest must be a data.frame.");
  }

  if(!("path" %in% names(manifest))) {
    stop("Manifest must contain a column named 'path' with the file path relative to the package cache. The columns 'url' and 'md5' are optional.");
  }

  # Normalize path strings: use '/' as separator, drop leading separators and
  # repeated separators. This keeps paths portable across platforms. Note that
  # the backslash replacement must use a regular expression (a fixed="TRUE"
  # match with '\\\\' would only find double backslashes and silently do
  # nothing on Windows, where paths use single backslashes).
  manifest$path = as.character(manifest$path);
  manifest$path = gsub("\\\\", "/", manifest$path);
  manifest$path = sub("^/+", "", manifest$path);
  manifest$path = gsub("/+", "/", manifest$path);

  if(any(is.na(manifest$path)) || any(manifest$path == "")) {
    stop("Manifest contains at least one file with an empty 'path' entry.");
  }

  # Reject path traversal and absolute paths: manifest paths must always stay
  # inside the package cache.
  has_escape = grepl("(^|/)\\.\\.(/|$)", manifest$path);
  has_abs = grepl(":", manifest$path);   # catches windows drive letters like 'C:' and URL schemes
  if(any(has_escape) || any(has_abs)) {
    stop("Manifest 'path' entries must be relative paths inside the package cache. Found an absolute path or a path containing '..'.");
  }

  # Normalize the optional columns: treat empty strings as missing.
  for(col in c("url", "md5")) {
    if(col %in% names(manifest)) {
      vals = as.character(manifest[[col]]);
      vals[is.na(vals) | vals == ""] = NA_character_;
      manifest[[col]] = vals;
    } else {
      manifest[[col]] = rep(NA_character_, nrow(manifest));
    }
  }

  # Validate MD5 checksums if given.
  md5_given = !is.na(manifest$md5);
  if(any(md5_given)) {
    bad = !grepl("^[0-9a-fA-F]{32}$", manifest$md5[md5_given]);
    if(any(bad)) {
      stop(sprintf("Manifest contains %d invalid MD5 checksum(s). Each checksum must consist of exactly 32 hexadecimal characters.\n", sum(bad)));
    }
  }

  return(manifest);
}


#' @title Derive missing URLs in a manifest from a base URL.
#'
#' @description For every file in a manifest without an explicit URL, set the URL to \code{paste0(base_url, path)}. Used internally by \code{\link{read_manifest}}.
#'
#' @param manifest data.frame. The validated manifest.
#'
#' @param base_url string or NULL. The base URL to derive missing URLs from.
#'
#' @return data.frame. The manifest with the \code{url} column filled in.
#'
#' @keywords internal
derive_manifest_urls <- function(manifest, base_url = NULL) {
  url_missing = is.na(manifest$url);
  if(any(url_missing)) {
    if(is.null(base_url) || base_url == "") {
      stop(sprintf("Manifest has %d file(s) without a URL, but no 'base_url' was given. Add a 'url' entry for every file, or pass 'base_url' to derive the URLs from the paths.\n", sum(url_missing)));
    }
    manifest$url[url_missing] = paste0(base_url, manifest$path[url_missing]);
  }
  return(manifest);
}


#' @title Ensure the files described in a manifest are available in the file cache.
#'
#' @description Like \code{\link{ensure_files_available}}, but the files are described in a single declarative manifest (one row per file) instead of three parallel vectors. A manifest can be a CSV file (e.g., shipped with the package in \code{inst/extdata}) or a data.frame, see \code{\link{read_manifest}} for the expected format.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param manifest string or data.frame. The manifest to use, see \code{\link{read_manifest}}. Either the path to a CSV file, or a data.frame with the manifest columns.
#'
#' @param base_url string or NULL. Base URL to derive the download URL for files that have no explicit URL, see \code{\link{read_manifest}}. Ignored for files with an explicit \code{url} entry.
#'
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See \code{curl::curl_download} docs for details. Ignored when \code{download} is \code{FALSE}.
#'
#' @param on_errors, string. What to do if getting the files failed. One of c("warn", "stop", "ignore"). See \code{\link{ensure_files_available}} for details.
#'
#' @param download, logical. Whether to try downloading missing files. Defaults to TRUE. Existing files (with correct MD5 if available) will never be downloaded. Set to FALSE to only check which files are available without downloading anything.
#'
#' @param num_connections, integer. The number of parallel connections to use when downloading files, see \code{\link{ensure_files_available}}. Defaults to 2, or to the value of the R option \code{pkgfilecache.num_connections} if it is set.
#'
#' @param num_retries, integer. How many times to retry downloading files that failed, in addition to the first attempt, see \code{\link{ensure_files_available}}. Defaults to 2.
#'
#' @return Named list, like for \code{\link{ensure_files_available}}: the entries "available" and "missing" contain the manifest paths (as '/'-separated strings) that are available in, or missing from, the local file cache. The entry "file_status" is a logical vector in manifest row order indicating for each file whether it is available.
#'
#' @examples
#'    pkg_info = get_pkg_info("mypackage")
#'    # A manifest as a data.frame: two files, URLs derived from base_url.
#'    manifest = data.frame(path = c("sub/file1.txt", "file2.txt"),
#'                          stringsAsFactors = FALSE)
#'    # Only check availability, do not download anything (download = FALSE).
#'    # The files are missing, so a warning is expected (see 'on_errors').
#'    res = suppressWarnings(ensure_files_available_from_manifest(pkg_info, manifest,
#'                                                                base_url = "https://example.com/data/",
#'                                                                download = FALSE))
#'
#' @export
ensure_files_available_from_manifest <- function(pkg_info, manifest, base_url = NULL, files_are_binary = NULL, on_errors = "warn", download = TRUE, num_connections = getOption("pkgfilecache.num_connections", 2), num_retries = 2) {
  manifest_df = read_manifest(manifest, base_url = base_url);

  # Convert the '/'-separated manifest paths into the list-of-components form
  # used by ensure_files_available(), so that subdirectories inside the package
  # cache are created correctly on all platforms.
  relative_filenames = lapply(manifest_df$path, function(p) { strsplit(p, "/", fixed = TRUE)[[1L]]; });

  md5sums = manifest_df$md5;
  if(all(is.na(md5sums))) {
    md5sums = NULL;
  }

  res = ensure_files_available(pkg_info, relative_filenames, manifest_df$url, files_are_binary = files_are_binary, md5sums = md5sums, on_errors = on_errors, download = download, num_connections = num_connections, num_retries = num_retries);

  # Report the files using the '/'-separated strings from the manifest, in
  # manifest row order (the logical 'file_status' vector is aligned with the
  # manifest rows).
  res$available = manifest_df$path[res$file_status];
  res$missing = manifest_df$path[!res$file_status];

  return(res);
}


#' @title Generate a file manifest from a directory of local files.
#'
#' @description Create a manifest (CSV file) that describes all files in the given directory. This is meant to remove the tedious manual work of adding many files to a package: put the files into a directory (subdirectories are preserved), run this function once, and a ready-to-use manifest is written. The MD5 checksum of every file is computed automatically.
#'
#' @param dir, string. The directory containing the local files to describe. Files in subdirectories are included, and their relative paths (using '/' as separator) become the \code{path} entries in the manifest. Hidden files (starting with a dot) are not included.
#'
#' @param out, string. The path of the CSV file to write the manifest to. Typically something like \code{inst/extdata/files.csv} in your package. The file is overwritten if it exists. Comment lines describing the manifest are written to the top of the file.
#'
#' @param url_base, string or NULL. If given, the \code{url} column is filled with \code{paste0(url_base, path)} for every file, i.e., the remote URLs are derived from the paths. If \code{NULL} (the default), the \code{url} column is left empty, and the URLs have to be derived at read time by passing \code{base_url} to \code{\link{read_manifest}} or \code{\link{ensure_files_available_from_manifest}} (or by editing the file).
#'
#' @return The generated manifest as a data.frame, invisibly.
#'
#' @examples
#'    \dontrun{
#'    manifest = write_manifest_from_dir("~/mydata", "inst/extdata/files.csv",
#'                                       url_base = "https://example.com/data/")
#'    }
#'
#' @export
write_manifest_from_dir <- function(dir, out, url_base = NULL) {
  if(!dir.exists(dir)) {
    stop(sprintf("Directory '%s' does not exist.\n", dir));
  }

  files_abs = list.files(dir, recursive = TRUE, full.names = TRUE, all.files = FALSE, include.dirs = FALSE);
  files_abs = files_abs[!dir.exists(files_abs)];

  if(length(files_abs) == 0L) {
    stop(sprintf("No files found in directory '%s'.\n", dir));
  }

  dir_norm = normalizePath(dir, mustWork = TRUE);
  # Normalize both sides to forward slashes and strip any trailing separators
  # from the directory prefix before removing it from the file paths. This
  # makes the prefix stripping independent of the platform's file separator
  # and of whether normalizePath() appends a trailing separator (which it can
  # do on Windows), so the 'path' entries stay relative and portable.
  dir_norm = gsub("\\\\", "/", dir_norm);
  dir_norm = sub("/+$", "", dir_norm);

  files_abs = normalizePath(files_abs, mustWork = TRUE);
  files_abs = gsub("\\\\", "/", files_abs);

  dir_prefix = paste0(dir_norm, "/");
  nprefix = nchar(dir_prefix);
  prefix_matches = startsWith(files_abs, dir_prefix);
  rel_paths = files_abs;   # fallback: keep the path as-is if the prefix is not found
  rel_paths[prefix_matches] = substring(files_abs[prefix_matches], nprefix + 1L);

  # Windows file systems are case-insensitive, and normalizePath() may return
  # differently-cased paths for the directory and the files (e.g. for the
  # drive letter). Retry with a case-insensitive comparison for any path the
  # exact match did not strip.
  if(!all(prefix_matches)) {
    ci_matches = startsWith(tolower(files_abs), tolower(dir_prefix));
    rel_paths[ci_matches] = substring(files_abs[ci_matches], nprefix + 1L);
  }

  rel_paths = sub("^/+$", "", rel_paths);
  rel_paths = sub("^/+", "", rel_paths);

  md5sums = as.vector(tools::md5sum(files_abs));

  if(is.null(url_base)) {
    urls = rep("", length(files_abs));
  } else {
    urls = paste0(url_base, rel_paths);
  }

  manifest = data.frame(path = rel_paths, url = urls, md5 = md5sums, stringsAsFactors = FALSE);

  header = c(
    "# pkgfilecache manifest: one row per file.",
    "# This file was auto-generated by write_manifest_from_dir().",
    sprintf("# url_base: %s", if(is.null(url_base)) "" else url_base),
    "# path: relative to the package cache; url: download URL (empty = derive from url_base + path); md5: checksum (optional)."
  );
  writeLines(header, con = out);
  # Append the table. Base R warns when column names are written to an already
  # existing file, which is expected here, so the warning is suppressed.
  suppressWarnings(utils::write.table(manifest, file = out, append = TRUE, sep = ",", row.names = FALSE, col.names = TRUE, na = "", quote = TRUE));

  return(invisible(manifest));
}
