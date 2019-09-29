#' @title Get the absolute path of the package cache.
#' 
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @return string. The absolute path of the package cache. It is constructed by calling `rappdirs::user_data_dir` with the package and author names. If the author is null, the package name is also used as the author name.
#' 
#' 
#' @export
fc.get_data_dir <- function(pkg_info) {
  return(rappdirs::user_data_dir(appname=pkg_info$packagename, appauthor=pkg_info$author));
}


#' @title Delete all the given files from the package cache.
#' 
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache. 
#'  
#' @return logical vector. For each file, whether it was deleted. Note that files which did not exist were not deleted! You should check the results using `fc.check_files_in_data_dir`.
#' 
#' 
#' @export
fc.remove_local_files <- function(pkg_info, relative_filenames) {
  datadir = fc.get_data_dir(pkg_info);
  local_files_absolute = fc.get_abs_files(datadir, relative_filenames);

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
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#'  
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache.
#' 
#' @return vector of strings. The absolute paths.
#' 
#' 
#' @export
fc.get_absolute_path_for_filecache_relative_files <- function(pkg_info, relative_filenames) {
  datadir = fc.get_data_dir(pkg_info);
  return(fc.get_abs_files(datadir, relative_filenames));
}


#' @title Delete the full package cache directory for the given package.
#' 
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @return integer. The return value of the unlink() call: 0 for success, 1 for failure. See the unlink() documentation for details.
#' 
#' 
#' @export
fc.erase <- function(pkg_info) {
  datadir = fc.get_data_dir(pkg_info);
  return(unlink(datadir, recursive=TRUE));
}


#' @title List files that are available locally in the package cache.
#' 
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @return vector of strings. The file names available, relative to the package cache.
#' 
#' 
#' @export
fc.list <- function(pkg_info) {
  datadir = fc.get_data_dir(pkg_info);
  return(list.files(path = datadir, pattern = NULL, all.files = FALSE, full.names = FALSE, recursive = FALSE, ignore.case = FALSE, include.dirs = FALSE));
}


#' @title Construct a pkg_info object to be used with all other functions.
#' 
#' @description This functions constructs an object that uniquely identifies your package, i.e., the package that want to use the package cache. This is not a secret.
#' 
#' @param packagename, string. The name of the package using the package cache. Must be a valid directory name. Should not contain spaces. Passed as 'appname' to `rappdirs::user_data_dir`.
#' 
#' @param author, string. The author of the package using the package cache, or NULL. Must be a valid directory name if given, no need for the real author name. Should not contain spaces. Defaults to NULL. Passed as 'appauthor' to `rappdirs::user_data_dir`. Leave at NULL if in doubt.
#' 
#' @return named list. This can be passed to all function which require a `pkg_info` argument. You should not care for the inner structure and treat it as some identifier.
#' 
#' 
#' @export
fc.get_pkg_info <- function(packagename, author=NULL) {
  if(is.null(author)) {
    author = packagename;
  }
  
  pkg_info = list("packagename"=packagename, "author"=author);
  return(pkg_info);
}


#' @title Check whether the given files exist in the package cache.
#' 
#' @description Check whether the given files exist in the package cache. You can pass MD5 sums, which will be verified and only files with correct MD5 hash will count as existing.
#' 
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @param md5sums, vector of strings or NULL. A list of MD5 checksums, one for each file in param 'relative_filenames', if not NULL. If given, the files will only be reported as existing if the MD5 sums match.
#'  
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache.
#' 
#' @return logical vector. For each file, whether it passed the check.
#' 
#' 
#' @export
fc.check_files_in_data_dir <- function(pkg_info, relative_filenames, md5sums = NULL) {
  if(! is.null(md5sums)) {
    if(length(relative_filenames) != length(md5sums)) {
      stop(sprintf("Data mismatch: received %d relative_filenames but %d md5sums. Lengths must be identical if md5sums is not NULL.", length(relative_filenames), length(md5sums)));
    }
  }
  datadir = fc.get_data_dir(pkg_info);
  local_files_absolute = fc.get_abs_files(datadir, relative_filenames);
  local_files_md5_ok = fc.local_files_exist_md5(local_files_absolute, md5sums);
  return(local_files_md5_ok);
}


#' @title Ensure all given files exist in the file cache, download them if they are not.
#' 
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @param relative_filenames, vector of strings. A vector of filenames, realtive to the package cache.
#' 
#' @param urls, vector of strings. For each file, a remote URL where to download the file. Will be passed to `downloader::download`, see that function for URL encoding details.
#' 
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See `downloader::download` docs for details.
#' 
#' @param md5sums, vector of strings or NULL. A list of MD5 checksums, one for each file in param 'relative_filenames', if not NULL. If given, the files will only be reported as existing if the MD5 sums match.
#' 
#' @param on_errors, string. What to do if getting the files failed. One of c("warn", "stop", "ignore"). At the end, files are checked using `fc.check_files_in_data_dir`(including MD5 if given). Depending on the check results, the behaviours triggered are: "warn": Print a warning for each file that failed the check. "stop": Stop the script, i.e., the whole application. "ignore": Do nothing. You can still react using the return value.
#' 
#' @param download_missing, logical. Whether to try downloading missing files. Defaults to TRUE.
#' 
#' @return Named list. The list has entries: "available": vector of strings. The names of the files that are available in the local file cache. You can access them using fc.getfile(). "missing": vector of strings. The names of the files that this function was unable to retrieve. "file_status": Logical array indicating whether the files are available. Order is identical to the one in argument 'relative_filenames'.
#' 
#' 
#' @export
fc.ensure_files_in_data_dir <- function(pkg_info, relative_filenames, urls, files_are_binary = NULL, md5sums = NULL, on_errors="warn", download_missing=TRUE) {
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

  datadir = fc.get_data_dir(pkg_info);

  local_files_absolute = fc.get_abs_files(datadir, relative_filenames);
  local_files_md5_ok = fc.local_files_exist_md5(local_files_absolute, md5sums);

  if(!(dir.exists(datadir))) {
    dir.create(datadir, showWarnings = TRUE, recursive = TRUE);
  }
  
  if(download_missing) {
    fc.download_files_with_md5_mismatch(local_files_absolute, local_files_md5_ok, urls, files_are_binary=files_are_binary);
  }

  # Check again whether md5sums are OK now
  are_local_files_md5_ok_afterwards = fc.local_files_exist_md5(local_files_absolute, md5sums);

  if(on_errors %in% c("warn", "stop")) {
    num_errors = 0L;
    for (file_idx in 1:length(local_files_absolute)) {
      lfile = local_files_absolute[file_idx];
      if(!(are_local_files_md5_ok_afterwards[file_idx])) {
        num_errors = num_errors + 1L;
        if(is.null(md5sums)) {
          warning(sprintf("Failed to get file '%s' to path '%s'.\n", relative_filenames[file_idx], lfile));
        } else {
          warning(sprintf("Failed to get file '%s' with md5sum '%s' to path '%s'.\n", relative_filenames[file_idx], md5sums[file_idx], lfile));
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
#' @param pkg_info, named list. Package identifier, see fc.get_pkg_info() on how to get one.
#' 
#' @param relative_filename, string. A filename, relative to the package cache.
#' 
#' @param mustWork, logical. Whether an error should be created if the file does not exist.
#'  
#' @return string. The path to the file. If mustWork=TRUE, the file is guaranteed to exist if the function returns (an error will occur if it does not). If mustWork=FALSE and the file does not exist, the empty string is returned.
#' 
#' 
#' @export
fc.getfile <- function(pkg_info, relative_filename, mustWork=TRUE) {
  files_exist_in_pkgcache = fc.check_files_in_data_dir(pkg_info, c(relative_filename));
  file_exists_in_pkgcache = files_exist_in_pkgcache[1];
  
  abs_names = fc.get_absolute_path_for_filecache_relative_files(pkg_info, c(relative_filename));
  abs_file_name = abs_names[1];
  
  if(file_exists_in_pkgcache) {
    return(abs_file_name);
  } else {
    if(mustWork) {
      stop(sprintf("File '%s' does not exist in local package cache at '%s', and mustWork is TRUE.\n", relative_filename, abs_file_name));
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
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache.
#' 
#' @keywords internal
fc.get_abs_files <- function(datadir, relative_filenames) {
  num_files = length(relative_filenames);
  files_absolute = rep("", num_files);
  for (file_idx in 1:num_files) {
    files_absolute[file_idx] = file.path(datadir, relative_filenames[file_idx]);
  }
  return(files_absolute);
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
fc.local_files_exist_md5 <- function(files_absolute, md5sums=NULL) {
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
#' @description Download files marked as mismatched to package cache. You should check afterwards whether this was successful, e.g., via `fc.local_files_exist_md5`.
#' 
#' @param local_files_absolute, vector of strings. A vector of filenames, must already include the package cache part.
#' 
#' @param local_files_md5_ok, logical vector. For each file, whether the local copy is OK. Only files for which this lists FALSE will be downloaded.
#' 
#' @param urls, vector of strings. For each file, a remote URL where to download the file. Will be passed to `downloader::download`, see that function for URL encoding details.
#' 
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See `downloader::download` docs for details.
#' 
#' @keywords intern
fc.download_files_with_md5_mismatch <- function(local_files_absolute, local_files_md5_ok, urls, files_are_binary=NULL) {
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

  for (file_idx in 1:num_files) {
    if(!(local_files_md5_ok[file_idx])) {
        mode = "wb";
        if(!(files_are_binary[file_idx])) {
          mode = "w";
        }
        # Ignore all errors, which may be thrown depending on the download method and platform. We check later whether the files are available with correct MD5, which is much better anyways.
        ignored = tryCatch({
          downloader::download(url=urls[file_idx], destfile=local_files_absolute[file_idx], quite=TRUE, mode=mode);
        }, error=function(e){}, warning=function(w){});
        
    }
  }
}
