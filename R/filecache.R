#' @title Get the absolute path of the package cache.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @description Get the absolute path of the package cache directory for the given package.
#'
#'   By default, the cache is stored in the directory returned by `tools::R_user_dir(packagename, "data")` (for R version 4.0 or later), which is the location recommended by the CRAN repository policy for user-specific data and cache files. If a cache already exists at the legacy location used by older versions of this package (the directory returned by `rappdirs::user_data_dir`), that legacy directory is reused instead, so that existing downloads are not lost and do not have to be re-downloaded. On R versions before 4.0, the legacy `rappdirs::user_data_dir` location is used.
#'
#'   The location can be overridden with R options:
#'   \itemize{
#'     \item `pkgfilecache.cachedir`: If set to a directory path, that directory is used as the root of the package cache, and the package name (and version, if any) are appended to it. Useful to place the cache elsewhere, e.g., on a ramdisk or network drive.
#'     \item `pkgfilecache.use_tempdir`: If set to `TRUE`, the cache is placed in a subdirectory of the R session's temporary directory (`tempdir()`). This is handy for unit tests and continuous integration, and in particular for tests that must not write to the user's home directory (e.g., on CRAN). The value of `pkgfilecache.cachedir` takes precedence if both options are set.
#'   }
#'
#' @return string. The absolute path of the package cache directory. A subdirectory of the directory returned by `tools::R_user_dir` (for R version 4.0 or later) or `rappdirs::user_data_dir` (for older R versions), unless one of the options `pkgfilecache.cachedir` or `pkgfilecache.use_tempdir` is set.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     opt_data_dir = get_cache_dir(pkg_info)
#'
#'
#' @export
get_cache_dir <- function(pkg_info) {

  # Optional override of the cache root directory via global options.
  cachedir_root = getOption("pkgfilecache.cachedir");
  if(is.null(cachedir_root) && isTRUE(getOption("pkgfilecache.use_tempdir"))) {
    cachedir_root = file.path(tempdir(), "pkgfilecache");
  }
  if(!is.null(cachedir_root)) {
    return(pkg_cache_dir_with_version(file.path(cachedir_root, pkg_info$packagename), pkg_info));
  }

  if(getRversion() >= "4.0") {
    # Default: the location recommended by the CRAN repository policy for
    # user-specific data and cache files.
    new_default_dir = pkg_cache_dir_with_version(tools::R_user_dir(pkg_info$packagename, "data"), pkg_info);
    # If a cache from an older version of this package already exists at the
    # legacy location, reuse it so that the user does not have to re-download
    # all their files.
    legacy_dir = rappdirs::user_data_dir(appname=pkg_info$packagename, appauthor=pkg_info$author, version=pkg_info$version);
    return(pick_cache_dir(new_default_dir, legacy_dir));
  }

  # R versions before 4.0 do not have tools::R_user_dir().
  return(rappdirs::user_data_dir(appname=pkg_info$packagename, appauthor=pkg_info$author, version=pkg_info$version));
}


#' @title Append the optional package version to a cache directory path.
#'
#' @param dir, string. The cache directory path (already including the package name).
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @return string. The directory path, with the version appended if the package info contains one.
#'
#' @keywords internal
pkg_cache_dir_with_version <- function(dir, pkg_info) {
  if(is.null(pkg_info$version)) {
    return(dir);
  } else {
    return(file.path(dir, pkg_info$version));
  }
}


#' @title Decide between the new and the legacy package cache directory.
#'
#' @description After migrating the default cache location to `tools::R_user_dir`, this function decides whether to use the new default directory or the legacy `rappdirs` directory: the legacy directory is used if it exists and the new one does not, so that users with an existing cache do not have to re-download their files.
#'
#' @param new_dir, string. The path of the new default cache directory (e.g., a subdirectory of `tools::R_user_dir`).
#'
#' @param legacy_dir, string. The path of the legacy cache directory (e.g., as returned by `rappdirs::user_data_dir`).
#'
#' @return string. Either `new_dir` or `legacy_dir`, depending on which directories exist.
#'
#' @keywords internal
pick_cache_dir <- function(new_dir, legacy_dir) {
  if(!dir.exists(new_dir) && dir.exists(legacy_dir)) {
    return(legacy_dir);
  }
  return(new_dir);
}


#' @title Delete all the given files from the package cache.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache.
#'
#' @return logical vector. For each file, whether it was deleted. Note that files which did not exist were not deleted! You should check the results using `files_available`.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     deleted = remove_cached_files(pkg_info, "some_file.txt")
#'
#' @export
remove_cached_files <- function(pkg_info, relative_filenames) {
  datadir = get_cache_dir(pkg_info);
  local_files_absolute = get_abs_filenames(datadir, relative_filenames);

  num_files = length(local_files_absolute);
  deleted = rep(FALSE, num_files);
  for (file_idx in 1:num_files) {
    lfile = local_files_absolute[file_idx];
    if(file.exists(lfile)) {
      deleted[file_idx] = file.remove(lfile);
    }
  }
  return(deleted);
}


#' @title Construct absolute path for package cache files.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache.
#'
#' @return vector of strings. The absolute paths.
#'
#' @examples
#'     rel_files = c("file1.txt", "file2.txt")
#'     pkg_info = get_pkg_info("mypackage")
#'     abs_paths = get_absolute_path_for_files(pkg_info, rel_files)
#'
#' @export
get_absolute_path_for_files <- function(pkg_info, relative_filenames) {
  datadir = get_cache_dir(pkg_info);
  return(get_abs_filenames(datadir, relative_filenames));
}


#' @title Delete the full package cache directory for the given package.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @return integer. The return value of the unlink() call: 0 for success, 1 for failure. See the unlink() documentation for details.
#'
#'
#' @export
erase_file_cache <- function(pkg_info) {
  datadir = get_cache_dir(pkg_info);
  return(unlink(datadir, recursive=TRUE));
}


#' @title List files that are available locally in the package cache.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @return vector of strings. The file names available, relative to the package cache. The returned names may include a subdirectory part. The subdirectories are not listed separately.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     available_files_in_cache = list_available(pkg_info)
#'
#' @export
list_available <- function(pkg_info) {
  datadir = get_cache_dir(pkg_info);
  return(list.files(path = datadir, pattern = NULL, all.files = FALSE, full.names = FALSE, recursive = TRUE, ignore.case = FALSE, include.dirs = FALSE));
}


#' @title Construct a pkg_info object to be used with all other functions.
#'
#' @description This functions constructs an object that uniquely identifies your package, i.e., the package that want to use the package cache. This is not a secret.
#'
#' @param packagename, string. The name of the package using the package cache. Must be a valid directory name. Should not contain spaces. Passed as 'appname' to `rappdirs::user_data_dir`.
#'
#' @param author, string. The author of the package using the package cache, or NULL. Must be a valid directory name if given, no need for the real author name. Should not contain spaces. Defaults to NULL. Passed as 'appauthor' to `rappdirs::user_data_dir`. Leave at NULL if in doubt.
#'
#' @param version, string or NULL. An optional version path element to append to the path. You might want to use this if you want multiple versions of your pacakge to be able to have independent data. If used, this would typically be "<major>.<minor>". Must be a valid directory name. Should not contain spaces or special characters.
#'
#' @return named list. This can be passed to all function which require a `pkg_info` argument. You should not care for the inner structure and treat it as some identifier.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     pkg_info = get_pkg_info("mypackage", author="me")
#'     pkg_info = get_pkg_info("mypackage", author="me", version="0.3")
#'
#' @export
get_pkg_info <- function(packagename, author=NULL, version=NULL) {
  if(is.null(author)) {
    author = packagename;
  }

  pkg_info = list("packagename"=packagename, "author"=author, "version"=version);
  return(pkg_info);
}


#' @title Check whether the given files exist in the package cache.
#'
#' @description Check whether the given files exist in the package cache. You can pass MD5 sums, which will be verified and only files with correct MD5 hash will count as existing.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param md5sums, vector of strings or NULL. A list of MD5 checksums, one for each file in param 'relative_filenames', if not NULL. If given, the files will only be reported as existing if the MD5 sums match.
#'
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache.
#'
#' @return logical vector. For each file, whether it passed the check.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     is_available = are_files_available(pkg_info, c("file1.txt", "file2.txt"))
#'
#' @export
are_files_available <- function(pkg_info, relative_filenames, md5sums = NULL) {
  if(! is.null(md5sums)) {
    if(length(relative_filenames) != length(md5sums)) {
      stop(sprintf("Data mismatch: received %d relative_filenames but %d md5sums. Lengths must be identical if md5sums is not NULL.", length(relative_filenames), length(md5sums)));
    }
  }
  datadir = get_cache_dir(pkg_info);
  local_files_absolute = get_abs_filenames(datadir, relative_filenames);
  local_files_md5_ok = files_exist_md5(local_files_absolute, md5sums);
  return(local_files_md5_ok);
}


#' @title Ensure all given files exist in the file cache, download them if they are not.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_filenames, vector of strings. A vector of filenames, realtive to the package cache.
#'
#' @param urls, vector of strings. For each file, a remote URL where to download the file. Will be passed to `curl::curl_download`, see that function for URL encoding details.
#'
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See `curl::curl_download` docs for details.
#'
#' @param md5sums, vector of strings or NULL. A list of MD5 checksums, one for each file in param 'relative_filenames', if not NULL. If given, the files will only be reported as existing if the MD5 sums match. A file that is present in the cache but whose MD5 sum does not match the expected sum is considered invalid and is deleted from the cache, so that it is never mistaken for a valid file.
#'
#' @param on_errors, string. What to do if getting the files failed. One of c("warn", "stop", "ignore"). At the end, files are checked using `files_available`(including MD5 if given). Depending on the check results, the behaviours triggered are: "warn": Print a warning for each file that failed the check. "stop": Stop the script, i.e., the whole application. "ignore": Do nothing. You can still react using the return value. This applies whether or not downloading was attempted, so missing files are never silently ignored, e.g., when 'download' is FALSE.
#'
#' @param download, logical. Whether to try downloading missing files. Defaults to TRUE. Existing files (with correct MD5 if available) will never be downloaded. When set to FALSE, no files are downloaded, but missing files are still reported according to 'on_errors'.
#'
#' @param num_connections, integer. The number of parallel connections to use when downloading files. Defaults to 2. With more connections, several files are downloaded at the same time, which can speed up downloading many small files considerably. Use 1 for strictly sequential downloads. A high number of connections may overload the server or trigger rate limits. The default can be changed globally for all calls that do not specify this argument by setting the R option \code{pkgfilecache.num_connections}.
#'
#' @param num_retries, integer. How many times to retry downloading files that failed, in addition to the first attempt. Defaults to 2. Each attempt uses fresh connections, which makes downloads robust against transient connection failures (e.g., a server that closes or throttles connections). Set to 0 to disable retrying.
#'
#' @return Named list. The list has entries: "available": vector of strings. The names of the files that are available in the local file cache. You can access them using get_filepath(). "missing": vector of strings. The names of the files that this function was unable to retrieve. "file_status": Logical array indicating whether the files are available. Order is identical to the one in argument 'relative_filenames'.
#'
#' @examples
#'    pkg_info = get_pkg_info("mypackage");
#'    local_relative_filenames = c("local_file1.txt", "local_file2.txt");
#'    bu = "https://raw.githubusercontent.com/dfsp-spirit/";
#'    url1 = paste(bu, "pkgfilecache/master/inst/extdata/file1.txt", sep="");
#'    url2 = paste(bu, "pkgfilecache/master/inst/extdata/file2.txt", sep="");
#'    urls = c(url1, url2);
#'    md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");
#'    res = ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums);
#'    erase_file_cache(pkg_info); # clear full cache
#'
#' @export
ensure_files_available <- function(pkg_info, relative_filenames, urls, files_are_binary = NULL, md5sums = NULL, on_errors="warn", download=TRUE, num_connections = getOption("pkgfilecache.num_connections", 2), num_retries = 2) {
  if(length(relative_filenames) != length(urls)) {
    stop(sprintf("Data mismatch: received %d relative_filenames but %d urls. Lengths must be identical.", length(relative_filenames), length(urls)));
  }

  if(! is.null(md5sums)) {
    if(length(relative_filenames) != length(md5sums)) {
      stop(sprintf("Data mismatch: received %d relative_filenames but %d md5sums. Lengths must be identical if md5sums is not NULL.", length(relative_filenames), length(md5sums)));
    }
  }

  if(!(on_errors %in% c("warn", "stop", "ignore"))) {
    stop(sprintf("Parameter 'on_errors' must be one of c('warn', 'stop', 'ignore') nut was '%s'.\n", on_errors));
  }

  if(! is.numeric(num_connections) || length(num_connections) != 1 || num_connections < 1) {
    stop(sprintf("Parameter 'num_connections' must be a single positive number, but was '%s'.\n", num_connections));
  }

  if(! is.numeric(num_retries) || length(num_retries) != 1 || num_retries < 0) {
    stop(sprintf("Parameter 'num_retries' must be a single non-negative number, but was '%s'.\n", num_retries));
  }

  datadir = get_cache_dir(pkg_info);

  make_pgk_cache_subdir_for_all_relative_files(pkg_info, relative_filenames);

  local_files_absolute = get_abs_filenames(datadir, relative_filenames);
  local_files_md5_ok = files_exist_md5(local_files_absolute, md5sums);

  if(!(dir.exists(datadir))) {
    dir.create(datadir, showWarnings = TRUE, recursive = TRUE);
  }

  last_download_errors = rep(NA_character_, length(local_files_absolute));
  names(last_download_errors) = local_files_absolute;

  if(download) {
    # Download all missing/mismatched files, and retry any that fail up to
    # 'num_retries' additional times. Each attempt uses fresh connections,
    # which makes downloads robust against transient connection failures
    # (e.g., a server that closes or throttles connections during downloads).
    local_files_md5_ok_now = local_files_md5_ok;
    for (retry_count in 0:num_retries) {
      attempt_errors = download_files_with_md5_mismatch(local_files_absolute, local_files_md5_ok_now, urls, files_are_binary=files_are_binary, num_connections=num_connections);
      # Keep the error message of the last attempt for each file, for use in the
      # final warnings below. Messages of earlier attempts are overwritten: only
      # the last attempt matters for the final report.
      last_download_errors[names(attempt_errors)] = attempt_errors;

      # Check again whether md5sums are OK now
      local_files_md5_ok_now = files_exist_md5(local_files_absolute, md5sums);

      if(all(local_files_md5_ok_now)) {
        break;
      }
      if(retry_count < num_retries) {
        cat(sprintf("Failed to download %d of %d file(s); retrying (attempt %d of %d).\n", sum(!local_files_md5_ok_now), length(local_files_absolute), retry_count + 1, num_retries));
      }
    }
    are_local_files_md5_ok_afterwards = local_files_md5_ok_now;
  } else {
    are_local_files_md5_ok_afterwards = files_exist_md5(local_files_absolute, md5sums);
  }

  # Handle missing files according to 'on_errors'. This runs both when
  # downloading was enabled (a download may have failed, or a downloaded file
  # may have failed its MD5 check) and when it was disabled (files are simply
  # missing from the cache), so that missing files are never silently ignored.
  if(on_errors %in% c("warn", "stop")) {
    num_errors = 0L;
    for (file_idx in 1:length(local_files_absolute)) {
      lfile = local_files_absolute[file_idx];
      if(!(are_local_files_md5_ok_afterwards[file_idx])) {
        num_errors = num_errors + 1L;
        relative_filename_flattened = flatten_filepath(relative_filenames[file_idx]);
        error_details = last_download_errors[lfile];
        if(!is.na(error_details)) {
          # The download attempt itself failed (HTTP status, connection error,
          # or a local write problem): report the cause.
          if(is.null(md5sums)) {
            warning(sprintf("Failed to get file '%s' to path '%s'. Last download error: %s\n", relative_filename_flattened, lfile, error_details));
          } else {
            warning(sprintf("Failed to get file '%s' with md5sum '%s' to path '%s'. Last download error: %s\n", relative_filename_flattened, md5sums[file_idx], lfile, error_details));
          }
        } else if(!is.null(md5sums) && file.exists(lfile)) {
          # The file exists, but its MD5 checksum does not match the expected
          # checksum. Since the user requested an integrity check by providing
          # MD5 sums, a mismatching file must not be left in the cache where it
          # could later be mistaken for a valid file (e.g., by get_filepath,
          # which checks existence only): delete it and say so.
          actual_md5 = unname(tools::md5sum(lfile));
          tryCatch(file.remove(lfile), error = function(e) {});
          warning(sprintf("File '%s' at path '%s' does not match the expected MD5 checksum (expected '%s', got '%s'). It may be corrupt or truncated, or the expected checksum may be out of date. The mismatching file was deleted.\n", relative_filename_flattened, lfile, md5sums[file_idx], actual_md5));
        } else {
          # No download error was recorded, but the file is not available. This
          # is the typical case when downloading was disabled (download=FALSE)
          # and the file is missing from the cache. It can also happen in rare
          # cases where a download failed without producing an error message.
          if(is.null(md5sums)) {
            warning(sprintf("Failed to get file '%s' to path '%s'.\n", relative_filename_flattened, lfile));
          } else {
            warning(sprintf("Failed to get file '%s' with md5sum '%s' to path '%s'.\n", relative_filename_flattened, md5sums[file_idx], lfile));
          }
        }
      }
    }
    if(num_errors > 0L && on_errors == "stop") {
      stop(sprintf("Getting files into local cache dir failed for %d of %d files (and stop on errors was requested).\n", num_errors, length(local_files_absolute)));
    }
  }

  ret_list = list();
  ret_list$available = relative_filenames[are_local_files_md5_ok_afterwards==TRUE];
  ret_list$missing = relative_filenames[are_local_files_md5_ok_afterwards==FALSE];
  ret_list$file_status = are_local_files_md5_ok_afterwards;
  return(ret_list);
}


#' @title Retrieve the path to a single file from the package cache.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_filename, string. A filename, relative to the package cache.
#'
#' @param mustWork, logical. Whether an error should be created if the file does not exist.
#'
#' @return string. The path to the file. If mustWork=TRUE, the file is guaranteed to exist if the function returns (an error will occur if it does not). If mustWork=FALSE and the file does not exist, the empty string is returned.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     full_path_of_file = get_filepath(pkg_info, "file1.txt", mustWork=FALSE)
#'
#' @export
get_filepath <- function(pkg_info, relative_filename, mustWork=TRUE) {
  files_exist_in_pkgcache = are_files_available(pkg_info, c(relative_filename));
  file_exists_in_pkgcache = files_exist_in_pkgcache[1];

  abs_names = get_absolute_path_for_files(pkg_info, c(relative_filename));
  abs_file_name = abs_names[1];

  relative_filename_flattened = flatten_filepath(relative_filename);

  if(file_exists_in_pkgcache) {
    return(abs_file_name);
  } else {
    if(mustWork) {
      stop(sprintf("File '%s' (from '%s') does not exist in local package cache at '%s', and mustWork is TRUE.\n", relative_filename_flattened, relative_filename, abs_file_name));
    } else {
      return("");
    }
  }
}


#' @title Join all relative filenames to a datadir.
#'
#' @description  For each file, create a full path by joining the datadir with the filename.
#'
#' @param datadir string, the path to the package cache directory.
#'
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache. Can be a list of vectors, which will be interpreted as files with subdirs.
#'
#' @return vector of strings, the absolute file names.
#'
#' @keywords internal
get_abs_filenames <- function(datadir, relative_filenames) {
  num_files = length(relative_filenames);
  files_absolute = rep("", num_files);
  for (file_idx in seq_len(length(relative_filenames))) {
    relative_file = flatten_filepath(relative_filenames[file_idx]);
    files_absolute[file_idx] = file.path(datadir, relative_file);
  }
  return(files_absolute);
}


#' @title Turn a filepath into a flat string.
#'
#' @param filepath string or list of strings
#'
#' @return string, the flattened filepath
#' @keywords internal
flatten_filepath <- function(filepath) {
  if(is.list(filepath)) {
    return(do.call('file.path', as.list(unlist(filepath))));
  } else {
    return(filepath);
  }
}


#' @title Given a relative file, create the subdir in the package cache if needed.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_file, string or vector of strings. If a string, this function does nothing. If a vector of strings, a path is created from the elements using file.path, and the directory of it (determined by dirname()) is created.
#'
#' @keywords internal
make_pgk_cache_subdir_for_relative_file <- function(pkg_info, relative_file) {
  sd = get_relative_file_subdir(pkg_info, relative_file);
  if(sd$has_subdir) {
    if(!dir.exists(sd$absolute_subdir)) {
      dir.create(sd$absolute_subdir, recursive = TRUE);
    }
  }
}

#' @title Given a relative file, create the subdir in the package cache if needed.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache. Can be a list of vectors, which will be interpreted as files with subdirs.
#'
#' @keywords internal
make_pgk_cache_subdir_for_all_relative_files <- function(pkg_info, relative_filenames) {
  if(is.list(relative_filenames)) {
    for(rfile in relative_filenames) {
      make_pgk_cache_subdir_for_relative_file(pkg_info, rfile);
    }
  }
}


#' @title Given a relative file, determine its subdir in the package cache.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @param relative_file, string or vector of strings. If a string, this function does nothing. If a vector of strings, a path is created from the elements using file.path, and the directory of it (determined by dirname()) is created.
#'
#' @return named list. The entries are: "has_subdir": logical, whether the file has a subdir. "relative_filepath": string. The input relative_file, flattened to a string. For files without subdir, this is identical to string in the parameter 'relative_file'. For others, it is the result of applying file.path() to the elements of the vector 'relative_file'. If "has_subdir" is TRUE, the following 2 fields also exist: "relative_subdir": string, subdir path relative to package cache dir. "absolute_subdir": string, absolute subdir path.
#'
#' @keywords internal
get_relative_file_subdir <- function(pkg_info, relative_file) {
  ret_list = list();
  datadir = get_cache_dir(pkg_info);
  if(length(relative_file) > 1) {    # This is a vector of strings
    relative_filepath = do.call('file.path', as.list(relative_file));
    relative_subdir = dirname(relative_filepath);
    absolute_subdir = file.path(datadir, relative_subdir)
    ret_list$has_subdir = TRUE;
    ret_list$relative_subdir = relative_subdir;
    ret_list$absolute_subdir = absolute_subdir;
    ret_list$relative_filepath = relative_filepath;
  } else {          # This is a single string. (Note that is.vector() is TRUE for strings in R, that's why this test is so ugly.)
    ret_list$has_subdir = FALSE;
    ret_list$relative_filepath = relative_file;
  }
  return(ret_list);
}



#' @title Check whether files exist, optionally with MD5 check.
#'
#' @description Check whether files exist. If MD5 hashes are given, they will be verified.
#'
#' @param files_absolute, vector of strings. A vector of filenames. Files are check as given, so they must already include the package cache part of the path.
#'
#' @param md5sums, vector of strings or NULL. A list of MD5 checksums, one for each file in param 'files', if not NULL. If given, the files will only be reported as existing if the MD5 sums match.
#'
#' @return logical vector. Whether the files exist. If the md5sums were given, whether the files exist and the MD5 sum matches.
#'
#' @keywords internal
files_exist_md5 <- function(files_absolute, md5sums=NULL) {
  if(is.null(md5sums)) {
    files_md5_ok = file.exists(files_absolute);
  } else {
    files_md5_ok = (md5sums == tools::md5sum(files_absolute));
    files_md5_ok[is.na(files_md5_ok)] = FALSE;      # set result for non-existing files to FALSE (instead of to NA).
  }
  return(as.vector(files_md5_ok));
}


#' @title Download files marked as mismatch to package cache.
#'
#' @description Download files marked as mismatched to package cache. You should check afterwards whether this was successful, e.g., via `files_exist_md5`.
#'
#' @param local_files_absolute, vector of strings. A vector of filenames, must already include the package cache part.
#'
#' @param local_files_md5_ok, logical vector. For each file, whether the local copy is OK. Only files for which this lists FALSE will be downloaded.
#'
#' @param urls, vector of strings. For each file, a remote URL where to download the file. Will be passed to `curl::curl_download`, see that function for URL encoding details.
#'
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See `curl::curl_download` docs for details.
#'
#' @param num_connections, integer. The number of parallel connections to use when downloading files. Defaults to 2, or to the value of the R option \code{pkgfilecache.num_connections} if it is set. Use 1 for strictly sequential downloads.
#'
#' @return Named character vector with one entry per file in \code{local_files_absolute} (the names are the absolute file paths). The entry is \code{NA} for files that were not downloaded in this call and for files that downloaded successfully; for files that were downloaded but failed it contains the error message of the download attempt. This message can distinguish remote problems (e.g., an HTTP status code like 404, or a connection failure) from local problems (e.g., the local file could not be written). The authoritative success check is done separately via \code{files_exist_md5} afterwards.
#'
#' @keywords internal
download_files_with_md5_mismatch <- function(local_files_absolute, local_files_md5_ok, urls, files_are_binary=NULL, num_connections = getOption("pkgfilecache.num_connections", 2)) {
  num_files = length(local_files_absolute);

  if(length(local_files_absolute) != length(local_files_md5_ok)) {
    stop(sprintf("Data mismatch: parameters 'local_files_absolute' and 'local_files_md5_ok' must have same length, but have %d and %d.\n", length(local_files_absolute), length(local_files_md5_ok)));
  }

  if(length(local_files_absolute) != length(urls)) {
    stop(sprintf("Data mismatch: parameters 'local_files_absolute' and 'urls' must have same length, but have %d and %d.\n", length(local_files_absolute), length(urls)));
  }

  if(is.null(files_are_binary)) {
    files_are_binary = rep(TRUE, num_files); # assume binary unless specified otherwise. Only relevant on windows, see '?download.file'
  } else {
    if(length(files_are_binary) != num_files) {
      if(length(files_are_binary) == 1) {
        files_are_binary = rep(files_are_binary, num_files);
      } else {
        stop(sprintf("Parameter 'files_are_binary' must be NULL or a logical vector with length 1, or with the same length as the number of files (but there are %d files and the vector has length %d).\n", num_files, length(files_are_binary)));
      }
    }
  }

  if(! is.numeric(num_connections) || length(num_connections) != 1 || num_connections < 1) {
    stop(sprintf("Parameter 'num_connections' must be a single positive number, but was '%s'.\n", num_connections));
  }

  files_to_download = which(!local_files_md5_ok);
  attempt_errors = rep(NA_character_, num_files);
  names(attempt_errors) = local_files_absolute;

  if(length(files_to_download) > 0) {
    if(num_connections <= 1) {
      # Sequential downloads: one file at a time, like always.
      for (file_idx in files_to_download) {
        mode = "wb";
        if(!(files_are_binary[file_idx])) {
          mode = "w";
        }
        url=urls[file_idx];
        destfile = local_files_absolute[file_idx];
        cat(sprintf("Download file to '%s' from '%s'\n", destfile, url));
        # Download the file, but do not stop on errors: we check afterwards
        # whether the files are available with correct MD5, which is the
        # authoritative check. A failed download may leave an empty or partial
        # file at destfile, so it is removed. The error message is captured and
        # returned so that callers can report a meaningful cause to the user;
        # it can distinguish remote problems (HTTP status like 404, connection
        # failure) from local problems (e.g., the local file could not be
        # written).
        err_details = tryCatch({
          curl::curl_download(url=url, destfile=destfile, quiet=TRUE, mode=mode);
          NA_character_;
        },
        error=function(e){ if(file.exists(destfile)) {file.remove(destfile);} ; conditionMessage(e);},
        warning=function(w){ if(file.exists(destfile)) {file.remove(destfile);} ; conditionMessage(w);});
        if(!is.na(err_details)) {
          attempt_errors[file_idx] = err_details;
        }
      }
    } else {
      # Parallel downloads via the curl multi interface. All transfers run
      # concurrently inside the single R process, up to 'num_connections'
      # connections at the same time. No extra R processes or threads are
      # spawned, and no new dependencies are needed (curl is already one).
      pool = curl::new_pool(total_con = num_connections, host_con = num_connections);
      errors_by_file = new.env(hash = TRUE, parent = emptyenv());
      for (file_idx in files_to_download) {
        url = urls[file_idx];
        destfile = local_files_absolute[file_idx];
        cat(sprintf("Download file to '%s' from '%s'\n", destfile, url));
        # Collect the error message per destination file. The callback refers to
        # 'destfile', which is a per-call argument of
        # add_file_download_to_curl_pool, so each parallel download records its
        # own error (the loop variable itself must not be used inside the
        # callback: R closures capture the variable, not its per-iteration
        # value).
        add_file_download_to_curl_pool(url, destfile, pool, error_collector=function(msg) {
          errors_by_file[[destfile]] = msg;
        });
      }
      curl::multi_run(pool = pool);
      # Transfer the collected errors into the named result vector.
      for (file_idx in files_to_download) {
        destfile = local_files_absolute[file_idx];
        if(!is.null(errors_by_file[[destfile]])) {
          attempt_errors[file_idx] = errors_by_file[[destfile]];
        }
      }
    }
  }
  return(attempt_errors);
}


#' @title Add a single file download to a curl multi pool.
#'
#' @description Add a single file download to a curl multi pool for parallel downloading. The file is streamed to disk as soon as data arrives, using curl's internal file writer (which opens the file lazily and closes it when the transfer completes). On any failure (connection error or HTTP status >= 300), the destination file is removed, so that a partially downloaded file is never mistaken for a successfully downloaded one. The failure is also reported to the \code{error_collector} callback, if given, so that callers can surface a meaningful cause (the HTTP status code or the connection error message) to the user. This function is only used internally by \code{download_files_with_md5_mismatch}.
#'
#' @param url, string. The URL to download.
#'
#' @param destfile, string. The absolute path of the local file to write to.
#'
#' @param pool, curl pool. The pool to add the download to, see \code{curl::new_pool}.
#'
#' @param error_collector, function or NULL. An optional callback that is called with a single string argument (the error message) if the download failed, i.e., if the HTTP response had a status code >= 300 or if a connection-level error occurred. Defaults to NULL, in which case failures are only handled by removing the destination file.
#'
#' @return NULL, invisibly.
#'
#' @keywords internal
add_file_download_to_curl_pool <- function(url, destfile, pool, error_collector = NULL) {
  h = curl::new_handle(url = url);
  curl::multi_add(h, pool = pool, data = destfile, done = function(res, ...) {
    # The transfer completed and an HTTP response was received (this is also
    # the case for error status codes like 404). If the response indicated an
    # error, remove the file, which may contain the server's error page, and
    # report the status code.
    if(!is.null(res$status_code) && res$status_code >= 300) {
      if(file.exists(destfile)) {
        tryCatch(file.remove(destfile), error = function(e) {});
      }
      if(!is.null(error_collector)) {
        error_collector(sprintf("HTTP status code %d (the server returned an error response).", res$status_code));
      }
    }
  }, fail = function(err, ...) {
    # Connection-level failure (e.g., DNS or connection refused): remove any
    # partially downloaded file and report the cause.
    if(file.exists(destfile)) {
      tryCatch(file.remove(destfile), error = function(e) {});
    }
    if(!is.null(error_collector)) {
      err_msg = if(inherits(err, "condition")) conditionMessage(err) else paste(as.character(err), collapse = " ");
      error_collector(err_msg);
    }
  });
  return(invisible(NULL));
}
