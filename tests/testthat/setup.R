# Run all tests against the R session's temporary directory instead of the
# user's home directory. The CRAN repository policy does not allow packages to
# write to the user's home directory during checks, and this option ensures that
# running the tests never writes outside of tempdir(), no matter where they run
# (CRAN, CI, or a developer machine).
options(pkgfilecache.use_tempdir = TRUE);
