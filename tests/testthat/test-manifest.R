# Tests for the declarative manifest API (R/manifest.R).
#
# The pure logic (reading, validating, URL derivation, manifest generation,
# offline availability checks) is tested without a network. One end-to-end
# download test is included but skipped on CRAN, like the other download tests.

test_that("write_manifest_from_dir generates a valid manifest that can be read back.", {
  td = withr::local_tempdir();
  dir.create(file.path(td, "sub", "dir"), recursive = TRUE);
  writeLines("hello", file.path(td, "file1.txt"));
  writeLines("world", file.path(td, "sub", "dir", "file2.txt"));

  out = file.path(td, "manifest.csv");
  manifest = write_manifest_from_dir(td, out, url_base = "https://example.com/data/");

  # Two files, with correct relative paths (using '/'), even for subdirectories.
  expect_equal(nrow(manifest), 2L);
  expect_true(all(c("file1.txt", "sub/dir/file2.txt") %in% manifest$path));

  # The MD5 checksums must be computed correctly.
  expect_equal(manifest$md5[manifest$path == "file1.txt"],
               as.vector(tools::md5sum(file.path(td, "file1.txt"))));

  # URLs are derived from url_base + path.
  expect_true(all(startsWith(manifest$url, "https://example.com/data/")));
  expect_true("https://example.com/data/sub/dir/file2.txt" %in% manifest$url);

  # The generated CSV is a valid manifest.
  manifest2 = read_manifest(out);
  expect_equal(nrow(manifest2), 2L);
  expect_true(all(c("file1.txt", "sub/dir/file2.txt") %in% manifest2$path));
  expect_true(all(!is.na(manifest2$url)));   # URLs were written explicitly
  expect_true(all(!is.na(manifest2$md5)));   # MD5s were filled in by the generator
})


test_that("write_manifest_from_dir leaves the url column empty without url_base.", {
  td = withr::local_tempdir();
  writeLines("hello", file.path(td, "file1.txt"));
  out = file.path(td, "manifest.csv");
  write_manifest_from_dir(td, out, url_base = NULL);

  m = read_manifest(out, base_url = "https://example.com/");
  expect_equal(m$url, "https://example.com/file1.txt");   # derived at read time
})


test_that("read_manifest derives URLs from base_url when the url entry is omitted.", {
  td = withr::local_tempdir();
  manifest_file = file.path(td, "m.csv");
  writeLines(c("path,md5",
               "a/b.txt,",
               "c.txt,1234567890abcdef1234567890abcdef"), manifest_file);

  m = read_manifest(manifest_file, base_url = "https://x.org/data/");
  expect_equal(m$url, c("https://x.org/data/a/b.txt", "https://x.org/data/c.txt"));
  expect_equal(m$md5, c(NA_character_, "1234567890abcdef1234567890abcdef"));

  # Without base_url, the missing URL must be reported as an error.
  expect_error(read_manifest(manifest_file));
})


test_that("read_manifest accepts a data.frame directly.", {
  m = read_manifest(data.frame(path = "a.txt", stringsAsFactors = FALSE), base_url = "https://x.org/");
  expect_equal(m$url, "https://x.org/a.txt");
  expect_true(is.na(m$md5));
})


test_that("read_manifest reports invalid input.", {
  # Missing 'path' column.
  expect_error(read_manifest(data.frame(url = "https://x.org/a.txt")));
  # Nonexistent manifest file.
  expect_error(read_manifest("/no/such/manifest.csv"));
  # Neither url nor base_url.
  expect_error(read_manifest(data.frame(path = "a.txt", stringsAsFactors = FALSE)));
})


test_that("Manifest paths cannot escape the package cache.", {
  expect_error(read_manifest(data.frame(path = "../evil.txt", stringsAsFactors = FALSE)));
  expect_error(read_manifest(data.frame(path = "a/../../evil.txt", stringsAsFactors = FALSE)));
  expect_error(read_manifest(data.frame(path = "/abs/evil.txt", stringsAsFactors = FALSE)));
  expect_error(read_manifest(data.frame(path = "C:/evil.txt", stringsAsFactors = FALSE)));
})


test_that("Invalid MD5 checksums in a manifest are rejected.", {
  expect_error(read_manifest(data.frame(path = "a.txt", md5 = "1234", stringsAsFactors = FALSE)));
  m = read_manifest(data.frame(path = "a.txt", md5 = "1234567890abcdef1234567890abcdef", stringsAsFactors = FALSE), base_url = "https://x.org/");
  expect_equal(m$md5, "1234567890abcdef1234567890abcdef");
})


test_that("ensure_files_available_from_manifest works offline (download = FALSE).", {
  pkg_info = get_pkg_info("pkgfilecache");
  tf1 = system.file("extdata", "file1.txt", package = "pkgfilecache", mustWork = TRUE);
  md5_file1 = as.vector(tools::md5sum(tf1));

  erase_file_cache(pkg_info);

  # Place the file in the cache under a nested path, as if it had been downloaded.
  rel_path = "sub/dir/file1.txt";
  abs_path = file.path(get_cache_dir(pkg_info), "sub", "dir", "file1.txt");
  dir.create(dirname(abs_path), recursive = TRUE, showWarnings = FALSE);
  file.copy(tf1, abs_path);

  manifest = data.frame(path = c(rel_path, "other/missing.txt"),
                        md5 = c(md5_file1, "00000000000000000000000000000000"),
                        stringsAsFactors = FALSE);

  res = ensure_files_available_from_manifest(pkg_info, manifest,
                                             base_url = "https://example.com/",
                                             download = FALSE);
  expect_equal(res$file_status, c(TRUE, FALSE));
  # The returned paths must be the '/' separated strings from the manifest.
  expect_equal(res$available, "sub/dir/file1.txt");
  expect_equal(res$missing, "other/missing.txt");

  erase_file_cache(pkg_info);
})


test_that("ensure_files_available_from_manifest accepts a CSV manifest (offline).", {
  pkg_info = get_pkg_info("pkgfilecache");
  td = withr::local_tempdir();
  manifest_file = file.path(td, "m.csv");
  writeLines("path,url,md5\njust_an_offline_check.txt,https://example.com/x.txt,\n", manifest_file);

  res = ensure_files_available_from_manifest(pkg_info, manifest_file, download = FALSE);
  expect_equal(res$missing, "just_an_offline_check.txt");
})


test_that("Files can be downloaded through a manifest (online).", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "raw.githubusercontent.com");

  pkg_info = get_pkg_info("pkgfilecache");
  td = withr::local_tempdir();
  manifest_file = file.path(td, "manifest.csv");
  manifest = data.frame(
    path = c("via_manifest_file1.txt", "via_manifest_file2.txt"),
    url = c("https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file1.txt",
            "https://raw.githubusercontent.com/dfsp-spirit/pkgfilecache/master/inst/extdata/file2.txt"),
    md5 = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de"),
    stringsAsFactors = FALSE
  );
  write.csv(manifest, manifest_file, row.names = FALSE);

  erase_file_cache(pkg_info);
  res = ensure_files_available_from_manifest(pkg_info, manifest_file);
  expect_equal(res$file_status, c(TRUE, TRUE));
  expect_equal(res$available, c("via_manifest_file1.txt", "via_manifest_file2.txt"));
  expect_equal(length(res$missing), 0L);

  erase_file_cache(pkg_info); # clear full cache
})
