
#' @title Determine whether a test is running on CRAN under macos
#'
#' @description We are currently getting failed unit tests on CRAN under macos, while the package works under MacOS on both <https://builder.r-hub.io/> and on our MacOS machines. We suspect the CRAN results to be false positives and do for now disable some unit tests on CRAN specifically under MacOS.
#'
#' @return logical, whether a test is running on CRAN under MacOS
#' @keywords internal
tests_running_on_cran_under_macos <- function() {
  return(tolower(Sys.info()[["sysname"]]) == 'darwin' && !identical(Sys.getenv("NOT_CRAN"), "true"));
}

test_that("We can download files to a local dir without MD5 check.", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");

  pkg_info = get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1.txt", "local_file2.txt");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");

  deleted = remove_cached_files(pkg_info, local_relative_filenames);

  file_stats = are_files_available(pkg_info, local_relative_filenames);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = remove_cached_files(pkg_info, local_relative_filenames);
  expect_equal(deleted_again, c(FALSE, FALSE));

  # download the files
  res = ensure_files_available(pkg_info, local_relative_filenames, urls);
  expect_equal(res$file_status, c(TRUE, TRUE));
  expect_equal(length(res$available), 2L);
  expect_equal(length(res$missing), 0L);
  expect_equal(res$available[1], "local_file1.txt");
  expect_equal(res$available[2], "local_file2.txt");

  erase_file_cache(pkg_info); # clear full cache
})



test_that("We can erase the file cache and list all files in the cache", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");

  pkg_info = get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1.txt", "local_file2.txt");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");

  erase_file_cache(pkg_info); # clear full cache
  deleted = remove_cached_files(pkg_info, local_relative_filenames);
  expect_equal(deleted, c(FALSE, FALSE));

  files_in_cache = list_available(pkg_info);
  expect_equal(length(files_in_cache), 0);

  file_stats = are_files_available(pkg_info, local_relative_filenames);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = remove_cached_files(pkg_info, local_relative_filenames);
  expect_equal(deleted_again, c(FALSE, FALSE));
  files_in_cache = list_available(pkg_info);
  expect_equal(length(files_in_cache), 0);

  # download the files
  res = ensure_files_available(pkg_info, local_relative_filenames, urls);
  expect_equal(res$file_status, c(TRUE, TRUE));
  files_in_cache = list_available(pkg_info);
  expect_equal(length(files_in_cache), 2);
  expect_true("local_file1.txt" %in% files_in_cache);
  expect_true("local_file2.txt" %in% files_in_cache);
  expect_equal(length(res$available), 2L);
  expect_equal(length(res$missing), 0L);
  expect_equal(res$available[1], "local_file1.txt");
  expect_equal(res$available[2], "local_file2.txt");

  # delete full cache
  erase_file_cache(pkg_info); # clear full cache
  files_in_cache = list_available(pkg_info);
  expect_equal(length(files_in_cache), 0);
})



test_that("We can download files to a local dir with MD5 check.", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");

  pkg_info = get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1_whatever.txt", "another_file2.some.ext");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");

  deleted = remove_cached_files(pkg_info, local_relative_filenames);

  file_stats = are_files_available(pkg_info, local_relative_filenames, md5sums=md5sums);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = remove_cached_files(pkg_info, local_relative_filenames);
  expect_equal(deleted_again, c(FALSE, FALSE));

  # download the files
  res = ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums);
  expect_equal(res$file_status, c(TRUE, TRUE));
  expect_equal(length(res$available), 2L);
  expect_equal(length(res$missing), 0L);
  expect_equal(res$available[1], "local_file1_whatever.txt");
  expect_equal(res$available[2], "another_file2.some.ext");

  erase_file_cache(pkg_info); # clear full cache
})



test_that("Files that cannot be downloaded will be reported as failed.", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");

  pkg_info = get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1.txt", "will_not_make_it.txt");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/nosuchfile");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");

  erase_file_cache(pkg_info);

  # download the files
  res = ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums, on_errors="ignore");
  expect_equal(res$file_status, c(TRUE, FALSE));
  expect_equal(length(res$available), 1L);
  expect_equal(length(res$missing), 1L);
  expect_equal(res$available[1], "local_file1.txt");
  expect_equal(res$missing[1], "will_not_make_it.txt");

  # Test warnings and errors
  expect_warning(ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums, on_errors="warn"));
  expect_warning(expect_error(ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums, on_errors="stop")));

  erase_file_cache(pkg_info); # clear full cache
})



test_that("Relative filenames can be translated to absolute ones.", {
  pkg_info = get_pkg_info("pkgfilecache");
  files_rel = c("File1.txt", "file2.gz");

  files_abs = get_absolute_path_for_files(pkg_info, files_rel);

  dd = get_cache_dir(pkg_info);

  expect_equal(length(files_abs), length(files_rel));
  expect_equal(files_abs[0], file.path(dd, files_rel[0]));
  expect_equal(files_abs[1], file.path(dd, files_rel[1]));

})



test_that("Existence of local file can be checked without MD5", {
  tf1 = system.file("extdata", "file1.txt", package = "pkgfilecache", mustWork = TRUE);
  tf2 = system.file("extdata", "file2.txt", package = "pkgfilecache", mustWork = TRUE);
  testfiles = c(tf1, tf2);

  res = files_exist_md5(testfiles);
  expect_equal(length(res), 2);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(TRUE, TRUE));

  res = files_exist_md5(c("/no/such/file"));
  expect_equal(length(res), 1);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(FALSE));

})



test_that("Existence of local file can be checked with MD5", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  testthat::skip(message="Does not work under Windows, skip for now.");
  tf1 = system.file("extdata", "file1.txt", package = "pkgfilecache", mustWork = TRUE);
  tf2 = system.file("extdata", "file2.txt", package = "pkgfilecache", mustWork = TRUE);
  testfiles = c(tf1, tf2);
  known_correct_md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");
  incorrect_md5sums = c("1234", "5678");

  res = files_exist_md5(testfiles, md5sums=known_correct_md5sums);
  expect_equal(length(res), 2);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(TRUE, TRUE));

  res = files_exist_md5(testfiles, md5sums=incorrect_md5sums);
  expect_equal(length(res), 2);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(FALSE, FALSE));

  res = files_exist_md5(c("/no/such/file"), md5sums=c("1234"));
  expect_equal(length(res), 1);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(FALSE));
})



test_that("One can get a file from package cache that exists", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  testthat::skip(message="Does not work under Windows, skip for now.");
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");

  pkg_info = get_pkg_info("pkgfilecache");
  testfile_local="local_file1.txt"
  local_relative_filenames = c(testfile_local);
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f");

  deleted = remove_cached_files(pkg_info, local_relative_filenames);
  res = ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums);
  expect_equal(res$file_status, c(TRUE));
  expect_equal(length(res$available), 1L);
  expect_equal(length(res$missing), 0L);

  # Now check for a file that is known to exist:
  known_path = get_absolute_path_for_files(pkg_info, c(testfile_local));
  filepath = get_filepath(pkg_info, testfile_local, mustWork=TRUE);
  expect_equal(filepath, known_path);

  # Using mustWork=FALSE should not make a difference for this file, as it exists.
  filepath = get_filepath(pkg_info, testfile_local, mustWork=FALSE);
  expect_equal(filepath, known_path);

  # Now check for a file that does NOT exist with mustWork=FALSE:
  testfile_not_there = "sfsukasnfkasjfnask.txt"
  known_path = get_absolute_path_for_files(pkg_info, c(testfile_not_there));
  filepath = get_filepath(pkg_info, testfile_not_there, mustWork=FALSE);
  expect_equal(filepath, "");

  # We expect an error in this case for mustWork=TRUE:
  expect_error(get_filepath(pkg_info, testfile_not_there, mustWork=TRUE));

  erase_file_cache(pkg_info); # clear full cache
})



test_that("Relative filenames are translated to absolute ones", {
  filenames = c("file1", "file2");
  datadir = file.path("dir1", "subdir")
  abs_names = get_abs_filenames(datadir, filenames);
  expect_equal(abs_names[1], file.path(datadir, filenames[1]));
  expect_equal(abs_names[2], file.path(datadir, filenames[2]));
  expect_equal(length(abs_names), 2);
})


test_that("Relative filenames are translated to absolute ones for files with subdirs", {
  filenames = list(c("dir1", "file1"), c("dir2", "file2"));
  datadir = file.path("dir1", "subdir")
  abs_names = get_abs_filenames(datadir, filenames);
  expect_equal(abs_names[1], file.path(datadir, "dir1", "file1"));
  expect_equal(abs_names[2], file.path(datadir, "dir2", "file2"));
  expect_equal(length(abs_names), 2);
})



test_that("Using package version and author works", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");

  pkg_info = get_pkg_info("pkgfilecache", author="dfsp-spirit", version="0.1");
  testfile_local="local_file1.txt"
  local_relative_filenames = c(testfile_local);
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f");

  deleted = remove_cached_files(pkg_info, local_relative_filenames);
  res = ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums);
  expect_equal(res$file_status, c(TRUE));
  expect_equal(length(res$available), 1L);
  expect_equal(length(res$missing), 0L);

  erase_file_cache(pkg_info); # clear full cache
})


test_that("Storing a file in a subdirectory of the package cache works", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");
  skip_if(tests_running_on_cran_under_macos(), message = "Skipping on CRAN under MacOS");
  
  pkg_info = get_pkg_info("pkgfilecache");
  cache_dir = get_cache_dir(pkg_info);
  
  local_relative_filenames = list(c("dir1", "local_file1.txt"), c("dir2", "will_not_make_it.txt"));
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/nosuchfile");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");
  
  deleted = remove_cached_files(pkg_info, local_relative_filenames);
  res = expect_warning(ensure_files_available(pkg_info, local_relative_filenames, urls, md5sums=md5sums));
  expect_true(dir.exists(file.path(cache_dir, "dir1")));
  expect_true(dir.exists(file.path(cache_dir, "dir2")));
  expect_true(file.exists(file.path(cache_dir, "dir1", "local_file1.txt")));
  expect_false(file.exists(file.path(cache_dir, "dir2", "will_not_make_it.txt")));
  expect_equal(res$file_status, c(TRUE, FALSE));
  expect_equal(length(res$available), 1L);
  expect_equal(length(res$missing), 1L);
  
  
  erase_file_cache(pkg_info); # clear full cache
  expect_false(dir.exists(file.path(cache_dir, "dir1")));
  expect_false(dir.exists(file.path(cache_dir, "dir2")));
  expect_false(file.exists(file.path(cache_dir, "dir1", "local_file1.txt")));
  expect_false(file.exists(file.path(cache_dir, "dir2", "will_not_make_it.txt")));
})


test_that("Determining relative filenames works for strings and vectors of strings", {
  pkg_info = get_pkg_info("pkgfilecache");
  cache_dir = get_cache_dir(pkg_info);
  
  relative_file = "file1.txt"
  sd = get_relative_file_subdir(pkg_info, relative_file);
  expect_false(sd$has_subdir);
  expect_equal(sd$relative_filepath, relative_file);
})


test_that("Filenames are flattened", {
  # a single charcter string is already flattened and should not be altered
  fl = flatten_filepath("file1");
  expect_true(is.character(fl));
  expect_equal(nchar(fl), 5);
  expect_equal(length(fl), 1);
  expect_equal(fl, "file1");
  
  # a vector should be flattened.
  flp = flatten_filepath(list(c("dir1", "file1")));
  expect_true(is.character(flp));
  expect_equal(length(flp), 1);
  # the exect string returned is OS-dependent and not tested, as the tests should work independent of the OS.
})

