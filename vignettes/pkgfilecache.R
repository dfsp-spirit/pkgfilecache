## ---- eval = FALSE-------------------------------------------------------
#      library("pkgfilecache")
#  
#      pkg_info = fc.get_pkg_info("yourpackage");   # Something to identify the package that uses the package file cache.
#  
#      local_filenames = c("file1.txt", "file2.txt");    # How the files should be called in the local package file cache
#      urls = c("https://your.server/yourpackage/large_file1.txt", "https://your.server/yourpackage/large_file2.txt"); # Remote URLs where to download files from
#      md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");    # MD5 checksums. Optional but recommended.

## ---- eval = FALSE-------------------------------------------------------
#      res = fc.ensure_files_in_data_dir(pkg_info, local_filenames, urls, md5sums=md5sums);

## ---- eval = FALSE-------------------------------------------------------
#      wanted_local_file = "file1.txt";
#      file_path = fc.getfile(pkg_info, wanted_local_file, mustWork=TRUE);

## ---- eval = FALSE-------------------------------------------------------
#  local_relative_filenames = c("local_file1.txt", "local_file2.txt");
#  deleted = fc.remove_local_files(pkg_info, local_relative_filenames);

## ---- eval = FALSE-------------------------------------------------------
#  files_exist = fc.check_files_in_data_dir(pkg_info, relative_filenames);  # no MD5 check
#  files_exist_and_have_correct_md5 = fc.check_files_in_data_dir(pkg_info, relative_filenames, md5sums=md5sums);  # with MD5 check

## ---- eval = FALSE-------------------------------------------------------
#  #' @title Download optional data for this package if required.
#  #'
#  #' @description Ensure that the optioanl data is available locally in the package cache. Will try to download the data only if it is not available.
#  #'
#  #' @return Named list. The list has entries: "available": vector of strings. The names of the files that are available in the local file cache. You can access them using get_optional_data_file(). "missing": vector of strings. The names of the files that this function was unable to retrieve.
#  #'
#  #' @export
#  download_optional_data <- function() {
#    pkg_info = pkgfilecache::fc.get_pkg_info("yourpackage");        # to identify the package using the cache
#  
#    # Replace these with your optional data files.
#    local_filenames = c("file1.txt", "file2.txt");    # How the files should be called in the local package file cache
#    urls = c("https://your.server/yourpackage/large_file1.txt", "https://your.server/yourpackage/large_file2.txt"); # Remote URLs where to download files from
#    md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");    # MD5 checksums. Optional but recommended.
#  
#    res = pkgfilecache::fc.ensure_files_in_data_dir(pkg_info, local_filenames, urls, md5sums=md5sums);
#    res$file_status = NULL;
#    return(res);
#  }
#  
#  #' @title Get file names available in package cache.
#  #'
#  #' @description Get file names of optional data files which are available in the local package cache. You can access these files with get_optional_data_file().
#  #'
#  #' @return vector of strings. The file names available, relative to the package cache.
#  #'
#  #' @export
#  list_optional_data <- function() {
#    pkg_info = pkgfilecache::fc.get_pkg_info("yourpackage");
#    return(pkgfilecache::fc.list(pkg_info));
#  }
#  
#  
#  #' @title Access a single file from the package cache by its file name.
#  #'
#  #' @return string. The full path to the file in the package cache. Use this in your application code to open the file.
#  #'
#  #' @export
#  get_optional_data_file <- function(filename, mustWork=TRUE) {
#    pkg_info = pkgfilecache::fc.get_pkg_info("yourpackage");
#    return(pkgfilecache::fc.getfile(pkg_info, filename, mustWork=mustWork));
#  }
#  
#  
#  #' @title Delete all data in the package cache.
#  #'
#  #' @return integer. The return value of the unlink() call: 0 for success, 1 for failure. See the unlink() documentation for details.
#  #'
#  #' @export
#  delete_all_optional_data <- function() {
#    pkg_info = pkgfilecache::fc.get_pkg_info("yourpackage");
#    return(pkgfilecache::fc.erase(pkg_info));
#  }

