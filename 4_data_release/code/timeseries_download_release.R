
#' figure out what files are ready to be downloaded from SB
#' @param target_name the nwis_{site.id}_... target name. Format matters, since we parse it
#' @return a vector of file names for this site
ts_files_for_download <- function(target_name, ts.dir){
  
  library(dplyr)
  match.id <- paste0(paste(strsplit(target_name, '[_]')[[1]][1:2], collapse = '_'), '-')
  ts.files <- dir(ts.dir, full.names=TRUE) %>% {.[!grepl('all_ts_files|Thumbs.db', .)]}
  file.list <- c()
  for (file in ts.files){
    file.meta <- readr::read_tsv(file) %>%  filter(grepl(filepath, pattern = match.id))
    if (nrow(file.meta) == 1 && all(file.meta$posted, file.meta$tagged)){
      file.list <- c(file.list, file.meta$filepath)
    } else if (nrow(file.meta) > 1){
      stop('something is wrong, multiple file matches for ', target_name)
    }
  }
  return(file.list)
}

#' find all files that need to be local for a site, DL them
#' 
#' @param site.id the nwis_{site.no} to be used
#' @return a vector of file paths for the downloaded files

download_release_tses <- function(file.paths){
  for (file.path in file.paths){
    parsed.path <- mda.streams::parse_ts_path(file.path, out = c("dir_name", "file_name", "var_src", "site_name"))
    mda.streams::download_ts(var_src = parsed.path$var_src, site_name = parsed.path$site_name, 
                             folder = parsed.path$dir_name, on_local_exists = 'skip', on_remote_missing = 'stop')
  }
  return(file.paths)
}

post_release_tses <- function(target.name, parent.id, file.paths){
  
  tmpdir <- tempdir()
  zipfile <- file.path(tmpdir, paste0(target.name, '.zip'))
  
  rds.files <- file.paths
  tsv.files <- c()
  for (rds.file in rds.files){
    parsed.path <- mda.streams::parse_ts_path(rds.file, out = c("dir_name", "file_name", "var", "src", "site_name", "ts_name"))
    tsv.file <- make_ts_path(site_name = parsed.path$site_name, ts_name = parsed.path$ts_name, folder = tmpdir, version = 'tsv')
    tsv.file <- gsub(tsv.file,pattern = '.tsv.gz', replacement = '.tsv')
    write.table(x = unitted::deunitted(readRDS(rds.file)), file=tsv.file, sep='\t', row.names=FALSE, quote=TRUE)
    tsv.files <- c(tsv.files, tsv.file)
  }
  
  old.dir <- setwd(tmpdir)
  zip(zipfile = basename(zipfile), files = basename(tsv.files))
  setwd(old.dir)
  key <- strsplit(basename(zipfile), '[.]')[[1]][1]
  
  create_release_item(parent.id, key, zipfile)
  # zip those dogs and post
  unlink(c(zipfile, tsv.files))
}