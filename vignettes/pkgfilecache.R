## ---- eval = FALSE-------------------------------------------------------
#      library("pkgfilecache")
#  
#      pkg_info = fc.get_pkg_info("yourpackage");   # Something to identify the package that uses the package file cache.
#  
#      local_filenames = c("file1.txt", "file2.txt");    # How the files should be called in the local package file cache
#      urls = c("https://your.server/yourpackage/large_file1.txt", "https://your.server/yourpackage/large_file2.txt"); # Remote URLs where to download files from
#      md5sums = c("35261471bcd198583c3805ee2a543b1f", "85ffec2e6efb476f1ee1e3e7fddd86de");    # MD5 checksums. Optional but recommended.
#  
#  

## ---- eval = FALSE-------------------------------------------------------
#      files_exist_now = fc.ensure_files_in_data_dir(pkg_info, local_filenames, urls, md5sums=md5sums);

## ---- eval = FALSE-------------------------------------------------------
#      wanted_local_file = "file1.txt";
#      file_path = fc.getfile(pkg_info, wanted_local_file, mustWork=TRUE);

