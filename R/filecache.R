#' @title Get the absolute path of the package cache.
#'
#' @param pkg_info, named list. Package identifier, see get_pkg_info() on how to get one.
#'
#' @return string. The absolute path of the package cache. It is constructed by calling `rappdirs::user_data_dir` with the package, author, and version if available. If the author is null, the package name is also used as the author name.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     opt_data_dir = get_cache_dir(pkg_info)
#'
#'
#' @export
get_cache_dir <- function(pkg_info) {
  if(is.null(pkg_info$version)) {
    return(rappdirs::user_data_dir(appname=pkg_info$packagename, appauthor=pkg_info$author));
  } else {
    return(rappdirs::user_data_dir(appname=pkg_info$packagename, appauthor=pkg_info$author, version=version));
  }
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
#' @return vector of strings. The file names available, relative to the package cache.
#'
#' @examples
#'     pkg_info = get_pkg_info("mypackage")
#'     available_files_in_cache = list_available(pkg_info)
#'
#' @export
list_available <- function(pkg_info) {
  datadir = get_cache_dir(pkg_info);
  return(list.files(path = datadir, pattern = NULL, all.files = FALSE, full.names = FALSE, recursive = TRUE, ignore.case = FALSE, include.dirs = TRUE));
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
#' @param urls, vector of strings. For each file, a remote URL where to download the file. Will be passed to `downloader::download`, see that function for URL encoding details.
#'
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See `downloader::download` docs for details.
#'
#' @param md5sums, vector of strings or NULL. A list of MD5 checksums, one for each file in param 'relative_filenames', if not NULL. If given, the files will only be reported as existing if the MD5 sums match.
#'
#' @param on_errors, string. What to do if getting the files failed. One of c("warn", "stop", "ignore"). At the end, files are checked using `files_available`(including MD5 if given). Depending on the check results, the behaviours triggered are: "warn": Print a warning for each file that failed the check. "stop": Stop the script, i.e., the whole application. "ignore": Do nothing. You can still react using the return value.
#'
#' @param download, logical. Whether to try downloading missing files. Defaults to TRUE. Existing files (with correct MD5 if available) will never be downloaded.
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
ensure_files_available <- function(pkg_info, relative_filenames, urls, files_are_binary = NULL, md5sums = NULL, on_errors="warn", download=TRUE) {
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

  datadir = get_cache_dir(pkg_info);
  
  make_pgk_cache_subdir_for_all_relative_files(pkg_info, relative_filenames);

  local_files_absolute = get_abs_filenames(datadir, relative_filenames);
  local_files_md5_ok = files_exist_md5(local_files_absolute, md5sums);

  if(!(dir.exists(datadir))) {
    dir.create(datadir, showWarnings = TRUE, recursive = TRUE);
  }

  if(download) {
    download_files_with_md5_mismatch(local_files_absolute, local_files_md5_ok, urls, files_are_binary=files_are_binary);

    # Check again whether md5sums are OK now
    are_local_files_md5_ok_afterwards = files_exist_md5(local_files_absolute, md5sums);

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
  } else {
    are_local_files_md5_ok_afterwards = files_exist_md5(local_files_absolute, md5sums);
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
#' @param relative_filenames, vector of strings. A vector of filenames, relative to the package cache. Can be a list of vectors, which will be interpreted as files with subdirs.
#' 
#' @return vector of strings, the absolute file names.
#'
#' @keywords internal
get_abs_filenames <- function(datadir, relative_filenames) {
  num_files = length(relative_filenames);
  files_absolute = rep("", num_files);
  for (file_idx in 1:num_files) {
    relative_file = relative_filenames[file_idx];
    if(is.list(relative_filenames)) {  # The names include a sub directory
      relative_file_path = do.call('file.path', as.list(unlist(relative_file)));
      files_absolute[file_idx] = file.path(datadir, relative_file_path);
    } else {
      files_absolute[file_idx] = file.path(datadir, relative_file);
    }
  }
  return(files_absolute);
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
make_pgk_cache_subdir_for_all_relative_files <- function(pkg_info, relative_files) {
  if(is.list(relative_files)) {
    for(rfile in relative_files) {
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
#' @param urls, vector of strings. For each file, a remote URL where to download the file. Will be passed to `downloader::download`, see that function for URL encoding details.
#'
#' @param files_are_binary, logical vector. For each file, whether it is binary. Only required on Windows, when files need to be downloaded. See `downloader::download` docs for details.
#'
#' @keywords internal
download_files_with_md5_mismatch <- function(local_files_absolute, local_files_md5_ok, urls, files_are_binary=NULL) {
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
        url=urls[file_idx];
        destfile = local_files_absolute[file_idx];
        cat(sprintf("Download file to '%s' from '%s'\n", destfile, url));
        # Ignore all errors, which may be thrown depending on the download method and platform. We check later whether the files are available with correct MD5, which is much better anyways.
        ignored = tryCatch({
          downloader::download(url=url, destfile=destfile, quite=TRUE, mode=mode);
        }, 
        error=function(e){ if(file.exists(destfile)) {file.remove(destfile);}},      # If warnings happen, something went wrong and an empty file may exist at destfile. Remove it.
        warning=function(w){ if(file.exists(destfile)) {file.remove(destfile);}});
    }
  }
}
