test_that("We can download files to a local dir without MD5 check.", {

  packagename = "pkgfilecache";
  author = "dfsp-spirit";
  local_relative_filenames = c("brain.mgz", "T1.mgz");
  urls = c("http://rcmd.org/tmp/brain.mgz", "http://rcmd.org/tmp/T1.mgz");
  md5sums = c("2c4874576eb935bf9445dda0529774e0", "24bb590cad3e091c13741b5edce2ea7d");

  deleted = fc.remove_local_files(packagename, local_relative_filenames, author=author);

  file_stats = fc.check_files_in_data_dir(packagename, local_relative_filenames, md5sums=NULL, author=author);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = fc.remove_local_files(packagename, local_relative_filenames, author=author);
  expect_equal(deleted_again, c(FALSE, FALSE));

  # download the files
  files_exist_now = fc.ensure_files_in_data_dir(packagename, local_relative_filenames, urls);
  expect_equal(files_exist_now, c(TRUE, TRUE));
})


test_that("We can download files to a local dir with MD5 check.", {

  packagename = "pkgfilecache";
  author = "dfsp-spirit";
  local_relative_filenames = c("brain.mgz", "T1.mgz");
  urls = c("http://rcmd.org/tmp/brain.mgz", "http://rcmd.org/tmp/T1.mgz");
  md5sums = c("2c4874576eb935bf9445dda0529774e0", "24bb590cad3e091c13741b5edce2ea7d");

  deleted = fc.remove_local_files(packagename, local_relative_filenames, author=author);

  file_stats = fc.check_files_in_data_dir(packagename, local_relative_filenames, md5sums=md5sums, author=author);
  expect_equal(file_stats, c(FALSE, FALSE));

  # delete again, this time nothing should have been deleted:
  deleted_again = fc.remove_local_files(packagename, local_relative_filenames, author=author);
  expect_equal(deleted_again, c(FALSE, FALSE));

  # download the files
  files_exist_now = fc.ensure_files_in_data_dir(packagename, local_relative_filenames, urls, md5sums=md5sums);
  expect_equal(files_exist_now, c(TRUE, TRUE));
})



test_that("Relative filenames can be translated to absolute ones.", {
  packagename = "pkgfilecache";
  author = "dfsp-spirit";

  files_rel = c("File1.txt", "file2.gz");

  files_abs = fc.get_absolute_path_for_filecache_relative_files(packagename, files_rel, author=author);

  dd = fc.get_data_dir(packagename, author=author);

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
