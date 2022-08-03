#' download reference
#'
#' Download, reference and track tar file
#'
#' @param url_ref The url of the reference
#' @param out_path Output path
download_ref <- function(url_ref, path_out) {

        dir_out <- gsub(basename(path_out), "", path_out)

        if (!file.exists(dir_out)) {
            dir.create(dir_out)
        }
        download.file(url_ref, path_out, quite = FALSE, method = "curl")
        path_out
}

#' untar ref
#'
#' Untar ref
#'
#' @param path_ref Path to tar.
untar_ref <- function(path_ref) {

  dir_out <- gsub(basename(path_ref), "", path_ref)

  sys_cmd <- paste0("tar xvf ", path_ref, " -C ", dir_out)
  system(sys_cmd)
  gsub("\\.tar\\.gz", "", path_ref)

}

#' check if exist
#'
#' Check if folder exists.
#'
#' @param x Path or list of paths.
#' @return List of paths that do not exist.
check_if_exist <- function(x) {

  dat <- file.exists(x)

  if (!all(dat)) {
    stop("One or more folders missing ", x[!dat])
  } else {
    message("All folders found!")
  }

  x[!dat]
}


#' align_scrna
#'
#' Use cellranger to align data.
#'
#' @param sample_name Sample name.
#' @param path_sample Path to folder containing fastqs.
#' @param path_out Path to folder where to save results.
#' @param path_reference Path to folder containing reference.
#' @param localcores Localcores to use.
#' @param localmem Localmem to use (note need to match resources requested in tar_request!!!!!)
#' @return List of paths that do filtered_matrix
align_scrna <- function(sample_name,
                        path_sample,
                        path_out = here::here("data", "alignment_results"),
                        path_reference,
                        localcores,
                        localmem) {

  # Check if cellranger is installed and parameters
  cellranger_installed <- system("cellranger --version") == 0
  if (cellranger_installed == FALSE) {
    stop("cellranger installation not found! Please install cellranger...")
  }

  if (!file.exists(path_out)) {
    dir.create(path_out)
  }


  sys_cmd <- paste0(
            "cd ", path_out, " &&",
            "cellranger count --id", sample_name,
            " --transcriptome=", path_reference,
            " --fastqs=", path_sample,
            " --localcores=", localcores,
            " --localmem", localmem
  )

  system(sys_cmd)

  file.path(path_out, sample_name, "outs", "filtered_feature_bc_matrix.h5")
}

