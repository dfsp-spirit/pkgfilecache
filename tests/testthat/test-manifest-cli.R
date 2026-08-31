# Tests for the command line interface (R/cli.R): manifest_cli() and manifest_script().
#
# manifest_cli() is a thin wrapper around write_manifest_from_dir() (which is
# already tested in test-manifest.R), so these tests focus on the argument
# parsing, the --help output, and the error handling. The CLI is exercised by
# passing 'args' vectors directly; the actual capture of the command line via
# commandArgs() is not tested here, to keep the tests hermetic.


test_that("manifest_cli parses args and generates a manifest.", {
  td = withr::local_tempdir();
  dir.create(file.path(td, "data"));
  writeLines("hello", file.path(td, "data", "file1.txt"));
  out = file.path(td, "manifest.csv");

  m = manifest_cli(args = c("--dir", file.path(td, "data"), "--out", out, "--url-base", "https://example.com/data/"));

  expect_true(file.exists(out));
  expect_equal(nrow(m), 1L);
  expect_equal(m$path, "file1.txt");
  expect_equal(m$url, "https://example.com/data/file1.txt");
})


test_that("manifest_cli supports --flag=value and ignores a leading --args marker.", {
  td = withr::local_tempdir();
  writeLines("hello", file.path(td, "file1.txt"));
  out = file.path(td, "manifest.csv");

  m = manifest_cli(args = c("--args", paste0("--dir=", td), paste0("--out=", out), paste0("--url-base=", "https://example.com/")));

  expect_true(file.exists(out));
  expect_equal(nrow(m), 1L);
  expect_equal(m$url, "https://example.com/file1.txt");
})


test_that("manifest_cli prints usage and returns NULL for --help.", {
  expect_output(manifest_cli(args = c("--help")), "Usage: Rscript");
  expect_null(manifest_cli(args = c("--help")));
})


test_that("manifest_cli errors on unknown arguments and on missing required args.", {
  td = withr::local_tempdir();
  expect_error(manifest_cli(args = c("--bogus", "x")), "Unknown command line argument");
  expect_error(manifest_cli(args = c("--dir", td)), "Missing required argument '--out'");
  expect_error(manifest_cli(args = c("--out", "x.csv")), "Missing required argument '--dir'");
  expect_error(manifest_cli(args = c("--dir", td, "--out")), "requires a value");
})


test_that("manifest_script returns the path of the shipped script.", {
  p = manifest_script();
  expect_true(file.exists(p));
  expect_true(endsWith(p, "make_manifest.R"));
})
