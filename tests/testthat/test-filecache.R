test_that("We can download files to a local dir without MD5 check.", {
  
  skip_on_cran();
  skip_if_offline(host = "raw.githubusercontent.com");

  pkg_info = fc.get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1.txt", "local_file2.txt");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");

  deleted = fc.remove_local_files(pkg_info, local_relative_filenames);

  file_stats = fc.check_files_in_data_dir(pkg_info, local_relative_filenames);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = fc.remove_local_files(pkg_info, local_relative_filenames);
  expect_equal(deleted_again, c(FALSE, FALSE));

  # download the files
  res = fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls);
  expect_equal(res$file_status, c(TRUE, TRUE));
  expect_equal(length(res$available), 2L);
  expect_equal(length(res$missing), 0L);
  expect_equal(res$available[1], "local_file1.txt");
  expect_equal(res$available[2], "local_file2.txt");
})

test_that("We can erase the file cache and list all files in the cache", {
  
  skip_on_cran();
  skip_if_offline(host = "raw.githubusercontent.com");
  
  pkg_info = fc.get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1.txt", "local_file2.txt");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");
  
  fc.erase(pkg_info); # clear full cache
  deleted = fc.remove_local_files(pkg_info, local_relative_filenames);
  expect_equal(deleted, c(FALSE, FALSE));
  
  files_in_cache = fc.list(pkg_info);
  expect_equal(length(files_in_cache), 0);
  
  file_stats = fc.check_files_in_data_dir(pkg_info, local_relative_filenames);
  expect_equal(file_stats, c(FALSE, FALSE));
  
  # delete again, this time nothing should have been deleted:
  deleted_again = fc.remove_local_files(pkg_info, local_relative_filenames);
  expect_equal(deleted_again, c(FALSE, FALSE));
  files_in_cache = fc.list(pkg_info);
  expect_equal(length(files_in_cache), 0);
  
  # download the files
  res = fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls);
  expect_equal(res$file_status, c(TRUE, TRUE));
  files_in_cache = fc.list(pkg_info);
  expect_equal(length(files_in_cache), 2);
  expect_true("local_file1.txt" %in% files_in_cache);
  expect_true("local_file2.txt" %in% files_in_cache);
  expect_equal(length(res$available), 2L);
  expect_equal(length(res$missing), 0L);
  expect_equal(res$available[1], "local_file1.txt");
  expect_equal(res$available[2], "local_file2.txt");
  
  # delete full cache
  fc.erase(pkg_info); # clear full cache
  files_in_cache = fc.list(pkg_info);
  expect_equal(length(files_in_cache), 0);
})





test_that("We can download files to a local dir with MD5 check.", {
  
  skip_on_cran();
  skip_if_offline(host = "raw.githubusercontent.com");
  
  pkg_info = fc.get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1_whatever.txt", "another_file2.some.ext");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");

  deleted = fc.remove_local_files(pkg_info, local_relative_filenames);

  file_stats = fc.check_files_in_data_dir(pkg_info, local_relative_filenames, md5sums=md5sums);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = fc.remove_local_files(pkg_info, local_relative_filenames);
  expect_equal(deleted_again, c(FALSE, FALSE));

  # download the files
  res = fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls, md5sums=md5sums);
  expect_equal(res$file_status, c(TRUE, TRUE));
  expect_equal(length(res$available), 2L);
  expect_equal(length(res$missing), 0L);
  expect_equal(res$available[1], "local_file1_whatever.txt");
  expect_equal(res$available[2], "another_file2.some.ext");
})


test_that("Files that cannot be downloaded will be reported as failed.", {
  
  skip_on_cran();
  skip_if_offline(host = "raw.githubusercontent.com");
  
  pkg_info = fc.get_pkg_info("pkgfilecache");
  local_relative_filenames = c("local_file1.txt", "will_not_make_it.txt");
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt", "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/nosuchfile");
  md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");
  
  fc.erase(pkg_info);
  
  # download the files
  res = fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls, md5sums=md5sums, on_errors="ignore");
  expect_equal(res$file_status, c(TRUE, FALSE));
  expect_equal(length(res$available), 1L);
  expect_equal(length(res$missing), 1L);
  expect_equal(res$available[1], "local_file1.txt");
  expect_equal(res$missing[1], "will_not_make_it.txt");
  
  # Test warnings and errors
  expect_warning(fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls, md5sums=md5sums, on_errors="warn"));
  expect_warning(expect_error(fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls, md5sums=md5sums, on_errors="stop")));
})




test_that("Relative filenames can be translated to absolute ones.", {
  pkg_info = fc.get_pkg_info("pkgfilecache");
  files_rel = c("File1.txt", "file2.gz");

  files_abs = fc.get_absolute_path_for_filecache_relative_files(pkg_info, files_rel);

  dd = fc.get_data_dir(pkg_info);

  expect_equal(length(files_abs), length(files_rel));
  expect_equal(files_abs[0], file.path(dd, files_rel[0]));
  expect_equal(files_abs[1], file.path(dd, files_rel[1]));

})


test_that("Existence of local file can be checked without MD5", {
  tf1 = system.file("extdata", "file1.txt", package = "pkgfilecache", mustWork = TRUE);
  tf2 = system.file("extdata", "file2.txt", package = "pkgfilecache", mustWork = TRUE);
  testfiles = c(tf1, tf2);

  res = fc.local_files_exist_md5(testfiles);
  expect_equal(length(res), 2);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(TRUE, TRUE));

  res = fc.local_files_exist_md5(c("/no/such/file"));
  expect_equal(length(res), 1);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(FALSE));

})


test_that("Existence of local file can be checked with MD5", {
  tf1 = system.file("extdata", "file1.txt", package = "pkgfilecache", mustWork = TRUE);
  tf2 = system.file("extdata", "file2.txt", package = "pkgfilecache", mustWork = TRUE);
  testfiles = c(tf1, tf2);
  known_correct_md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");
  incorrect_md5sums = c("1234", "5678");

  res = fc.local_files_exist_md5(testfiles, md5sums=known_correct_md5sums);
  expect_equal(length(res), 2);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(TRUE, TRUE));

  res = fc.local_files_exist_md5(testfiles, md5sums=incorrect_md5sums);
  expect_equal(length(res), 2);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(FALSE, FALSE));

  res = fc.local_files_exist_md5(c("/no/such/file"), md5sums=c("1234"));
  expect_equal(length(res), 1);
  expect_equal(typeof(res), "logical");
  expect_equal(res, c(FALSE));
})

test_that("One can get a file from package cache that exists", {
  skip_on_cran();
  skip_if_offline(host = "raw.githubusercontent.com");
  
  pkg_info = fc.get_pkg_info("pkgfilecache");
  testfile_local="local_file1.txt"
  local_relative_filenames = c(testfile_local);
  urls = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt");
  md5sums = c("35261471bcd198583c3805ee2a543b1f");
  
  deleted = fc.remove_local_files(pkg_info, local_relative_filenames);
  res = fc.ensure_files_in_data_dir(pkg_info, local_relative_filenames, urls, md5sums=md5sums);
  expect_equal(res$file_status, c(TRUE));
  expect_equal(length(res$available), 1L);
  expect_equal(length(res$missing), 0L);
  
  # Now check for a file that is known to exist:
  known_path = fc.get_absolute_path_for_filecache_relative_files(pkg_info, c(testfile_local));
  filepath = fc.getfile(pkg_info, testfile_local, mustWork=TRUE);
  expect_equal(filepath, known_path);
  
  # Using mustWork=FALSE should not make a difference for this file, as it exists.
  filepath = fc.getfile(pkg_info, testfile_local, mustWork=FALSE);
  expect_equal(filepath, known_path);
  
  # Now check for a file that does NOT exist witg mustWork=FALSE:
  testfile_not_there = "sfsukasnfkasjfnask.txt"
  known_path = fc.get_absolute_path_for_filecache_relative_files(pkg_info, c(testfile_not_there));
  filepath = fc.getfile(pkg_info, testfile_not_there, mustWork=FALSE);
  expect_equal(filepath, "");
  
  # We expect an error in this case for mustWork=TRUE:
  expect_error(fc.getfile(pkg_info, testfile_not_there, mustWork=TRUE));
})
