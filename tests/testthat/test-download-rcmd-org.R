# Regression test: download and MD5-verify the same set of (binary, HTTP) data
# files that the 'brainloc' package (https://github.com/dfsp-spirit/brainloc)
# downloads during its vignette build, from http://rcmd.org/projects/nitestdata/.
#
# This mirrors the failure seen on macOS (Apple Silicon) GitHub Actions runners:
# the R process died silently right after downloading these files during
# `R CMD build` of brainloc, when downloads went through the archived 'downloader'
# package. pkgfilecache now downloads via the modern 'curl' package (CHANGES 0.1.6),
# and this test ensures that path keeps working on all CI platforms (incl. macOS).

test_that("We can download and MD5-verify the brainloc fsaverage data files from rcmd.org", {
  testthat::skip_on_cran(); # Cannot download test data on CRAN.
  skip_if_offline(host = "rcmd.org");

  pkg_info = get_pkg_info("pkgfilecache");

  base_path_fsaverage  = c('subjects_dir', 'fsaverage');
  base_path_fsaverage3 = c('subjects_dir', 'fsaverage3');
  base_path_subject1   = c('subjects_dir', 'subject1');

  local_filenames = list(
    # fsaverage (17 files)
    c(base_path_fsaverage,  'label', 'lh.aparc.a2009s.annot'),
    c(base_path_fsaverage,  'label', 'rh.aparc.a2009s.annot'),
    c(base_path_fsaverage,  'label', 'lh.aparc.annot'),
    c(base_path_fsaverage,  'label', 'rh.aparc.annot'),
    c(base_path_fsaverage,  'label', 'lh.cortex.label'),
    c(base_path_fsaverage,  'label', 'rh.cortex.label'),
    c(base_path_fsaverage,  'mri',   'brain.mgz'),
    c(base_path_fsaverage,  'surf',  'lh.white'),
    c(base_path_fsaverage,  'surf',  'rh.white'),
    c(base_path_fsaverage,  'surf',  'lh.pial'),
    c(base_path_fsaverage,  'surf',  'rh.pial'),
    c(base_path_fsaverage,  'surf',  'lh.inflated'),
    c(base_path_fsaverage,  'surf',  'rh.inflated'),
    c(base_path_fsaverage,  'surf',  'lh.curv'),
    c(base_path_fsaverage,  'surf',  'rh.curv'),
    c(base_path_fsaverage,  'ext',   'FreeSurferColorLUT.txt'),
    c(base_path_fsaverage,  'LICENSE'),
    # fsaverage3 (5 files)
    c(base_path_fsaverage3, 'label', 'lh.cortex.label'),
    c(base_path_fsaverage3, 'label', 'rh.cortex.label'),
    c(base_path_fsaverage3, 'surf',  'lh.white'),
    c(base_path_fsaverage3, 'surf',  'rh.white'),
    c(base_path_fsaverage3, 'LICENSE'),
    # subject1 (2 files)
    c(base_path_subject1,   'surf',  'lh.thickness.fwhm0.fsaverage3.mgz'),
    c(base_path_subject1,   'surf',  'rh.thickness.fwhm0.fsaverage3.mgz')
  );

  md5sums = c(
    'b4310b1e4435defaf27fc7ee98199e6a', # fsaverage lh.aparc.a2009s.annot
    '6077dc6cb42dd8c48bb382672d65743c', # fsaverage rh.aparc.a2009s.annot
    'bf0b488994657435cdddac5f107d21e8', # fsaverage lh.aparc.annot
    '8f504caddedfde367a40501da6222809', # fsaverage rh.aparc.annot
    '578f81e9946a76eb1c42d897d07da4a7', # fsaverage lh.cortex.label
    'c8f59de23e9f90f18e96e9d037e42799', # fsaverage rh.cortex.label
    'b8bc4b5854f2d5e66d5c4f95d4f9cf63', # fsaverage brain.mgz
    'cbffce8198e0e10c17f79f6ae0454af5', # fsaverage lh.white
    '1159a9ee160b1b0c76e0bb9ae789b9be', # fsaverage rh.white
    'c53c1f70ae8971e1c04bd19e3277fa14', # fsaverage lh.pial
    '71f11c33db672360d7589c7dbd0e4a3f', # fsaverage rh.pial
    '95df985980d7eefa009ac104589ee3c5', # fsaverage lh.inflated
    'bb4d58289aefcdf8d017e45e531c4807', # fsaverage rh.inflated
    '3e81598a5ac0546443ec37d0ac477c80', # fsaverage lh.curv
    '76ad91d2488de081392313ad5a87fafb', # fsaverage rh.curv
    'a3735566ef949bd4d7ed303837cc5e77', # fsaverage FreeSurferColorLUT.txt
    'b39610adfe02fdce2ad9d30797c567b3', # fsaverage LICENSE
    '49a367e65ec7ecffbb721404b274fb3f', # fsaverage3 lh.cortex.label
    '76e2d42894351427405cc01ab351719b', # fsaverage3 rh.cortex.label
    'b014033974bc5b4deb8b54dc140abda8', # fsaverage3 lh.white
    '09a133fd8499f3192e051bdbd8bec6e8', # fsaverage3 rh.white
    'b39610adfe02fdce2ad9d30797c567b3', # fsaverage3 LICENSE
    'd191f6833d1d36016b30504fed1ce138', # subject1 lh.thickness.fwhm0.fsaverage3.mgz
    'e874f8dc149fd11842f117c300d1a964'  # subject1 rh.thickness.fwhm0.fsaverage3.mgz
  );

  ext_urls = c(
    'subjects_dir/fsaverage/label/lh.aparc.a2009s.annot',
    'subjects_dir/fsaverage/label/rh.aparc.a2009s.annot',
    'subjects_dir/fsaverage/label/lh.aparc.annot',
    'subjects_dir/fsaverage/label/rh.aparc.annot',
    'subjects_dir/fsaverage/label/lh.cortex.label',
    'subjects_dir/fsaverage/label/rh.cortex.label',
    'subjects_dir/fsaverage/mri/brain.mgz',
    'subjects_dir/fsaverage/surf/lh.white',
    'subjects_dir/fsaverage/surf/rh.white',
    'subjects_dir/fsaverage/surf/lh.pial',
    'subjects_dir/fsaverage/surf/rh.pial',
    'subjects_dir/fsaverage/surf/lh.inflated',
    'subjects_dir/fsaverage/surf/rh.inflated',
    'subjects_dir/fsaverage/surf/lh.curv',
    'subjects_dir/fsaverage/surf/rh.curv',
    'subjects_dir/fsaverage/ext/FreeSurferColorLUT.txt',
    'subjects_dir/fsaverage/LICENSE',
    'subjects_dir/fsaverage3/label/lh.cortex.label',
    'subjects_dir/fsaverage3/label/rh.cortex.label',
    'subjects_dir/fsaverage3/surf/lh.white',
    'subjects_dir/fsaverage3/surf/rh.white',
    'subjects_dir/fsaverage3/LICENSE',
    'subjects_dir/subject1/surf/lh.thickness.fwhm0.fsaverage3.mgz',
    'subjects_dir/subject1/surf/rh.thickness.fwhm0.fsaverage3.mgz'
  );
  base_url = 'http://rcmd.org/projects/nitestdata/';
  urls = paste(base_url, ext_urls, sep='');

  # Sanity check: vectors must be aligned.
  expect_equal(length(local_filenames), length(urls));
  expect_equal(length(md5sums), length(urls));

  erase_file_cache(pkg_info); # start from a clean cache

  res = ensure_files_available(pkg_info, local_filenames, urls, md5sums=md5sums, on_errors="stop");
  expect_equal(res$file_status, rep(TRUE, length(urls)));
  expect_equal(length(res$available), length(urls));
  expect_equal(length(res$missing), 0L);

  # Every downloaded file must be resolvable through get_filepath.
  for (rel_file in local_filenames) {
    fp = get_filepath(pkg_info, rel_file, mustWork = TRUE);
    expect_true(file.exists(fp), info = sprintf("File '%s' must exist in cache.", flatten_filepath(rel_file)));
  }

  erase_file_cache(pkg_info); # clear the cache again
})
