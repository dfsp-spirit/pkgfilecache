# Starting in Jan 2021, CRAN starts nagging you about leaving files in the userdir,
# so we delete the data here after the tests have finished.

if(!identical(Sys.getenv("NOT_CRAN"), "true")) {
  pkg_info = pkgfilecache::get_pkg_info("pkgfilecache");
  pkgfilecache::erase_file_cache(pkg_info);
}
