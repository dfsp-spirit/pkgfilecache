fc.get_data_dir <- function(packagename, author=NULL) {
  if(is.null(author)) {
    author = packagename;
  }
  dd = rappdirs::user_data_dir(appname=packagename, appauthor=author);
  return(dd);
}


fc.remove_local_files <- function(packagename, local_relative_filenames, author=NULL) {
  datadir = fc.get_data_dir(packagename, author=author);
  local_files_absolute = fc.get_abs_files(datadir, local_relative_filenames);

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



fc.get_absolute_path_for_filecache_relative_files <- function(packagename, filenames, author=NULL) {
  datadir = fc.get_data_dir(packagename, author=author);
  return(fc.get_abs_files(datadir, filenames));
}


fc.check_files_in_data_dir <- function(packagename, local_relative_filenames, md5sums = NULL, author=NULL) {
  if(! is.null(md5sums)) {
    if(length(local_relative_filenames) != length(md5sums)) {
      stop(sprintf("Data mismatch: received %d local_relative_filenames but %d md5sums. Lengths must be identical if md5sums is not NULL.", length(local_relative_filenames), length(md5sums)));
    }
  }
  datadir = fc.get_data_dir(packagename, author=author);
  local_files_absolute = fc.get_abs_files(datadir, local_relative_filenames);
  local_files_md5_ok = fc.local_files_exist_md5(local_files_absolute, md5sums);
  return(local_files_md5_ok);
}


fc.ensure_files_in_data_dir <- function(packagename, local_relative_filenames, urls, files_are_binary = NULL, md5sums = NULL, author=NULL, on_errors="warn") {
  if(length(local_relative_filenames) != length(urls)) {
    stop(sprintf("Data mismatch: received %d local_relative_filenames but %d urls. Lengths must be identical.", length(local_relative_filenames), length(urls)));
  }

  if(! is.null(md5sums)) {
    if(length(local_relative_filenames) != length(md5sums)) {
      stop(sprintf("Data mismatch: received %d local_relative_filenames but %d md5sums. Lengths must be identical if md5sums is not NULL.", length(local_relative_filenames), length(md5sums)));
    }
  }

  if(!(on_errors %in% c("warn", "stop", "ignore"))) {
    stop(sprintf("Parameter 'on_errors' must be one of c('warn', 'stop', 'ignore') nut was '%s'.\n", on_errors));
  }

  datadir = fc.get_data_dir(packagename, author=author);

  local_files_absolute = fc.get_abs_files(datadir, local_relative_filenames);
  local_files_md5_ok = fc.local_files_exist_md5(local_files_absolute, md5sums);

  if(!(dir.exists(datadir))) {
    dir.create(datadir, showWarnings = TRUE, recursive = TRUE);
  }
  fc.download_files_with_md5_mismatch(local_files_absolute, local_files_md5_ok, urls, files_are_binary=files_are_binary);

  # Check again whether md5sums are OK now
  local_files_md5_ok_afterwards = fc.local_files_exist_md5(local_files_absolute, md5sums);

  if(on_errors %in% c("warn", "stop")) {
    num_errors = 0L;
    for (file_idx in 1:length(local_files_absolute)) {
      lfile = local_files_absolute[file_idx];
      if(!(local_files_md5_ok_afterwards[file_idx])) {
        num_errors = num_errors + 1L;
        if(is.null(md5sums)) {
          warn(sprintf("Failed to get file '%s' to path '%s'.\n", local_relative_filenames[file_idx], lfile));
        } else {
          warn(sprintf("Failed to get file '%s' with md5sum '%s' to path '%s'.\n", local_relative_filenames[file_idx], md5sums[file_idx], lfile));
        }
      }
    }
    if(num_errors > 0L && on_errors == "stop") {
      stop(sprintf("Getting files into local cache dir failed for %d of %d files (and stop on errors was requested).\n", num_errors, length(local_files_absolute)));
    }
  }

  return(local_files_md5_ok_afterwards);
}


fc.get_abs_files <- function(datadir, relative_filenames) {
  num_files = length(relative_filenames);
  files_absolute = rep("", num_files);
  for (file_idx in 1:num_files) {
    files_absolute[file_idx] = file.path(datadir, relative_filenames[file_idx]);
  }
  return(files_absolute);
}


fc.local_files_exist_md5 <- function(files, md5sums=NULL) {
  if(is.null(md5sums)) {
    files_md5_ok = file.exists(files);
  } else {
    files_md5_ok = (md5sums == tools::md5sum(files));
    files_md5_ok[is.na(files_md5_ok)] = FALSE;      # set result for non-existing files to FALSE (instead of to NA).
  }
  return(as.vector(files_md5_ok));
}


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
        downloader::download(url=urls[file_idx], destfile=local_files_absolute[file_idx], quite=TRUE, mode=mode);
    }
  }

}
