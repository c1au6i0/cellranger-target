library(future)
library(future.batchtools)
library(batchtools)
library(targets)
library(tarchetypes)
library(here)
library(ggplot2)
source(here("code", "targets_functions", "functions.R"))

# @@@@@@@@@@@@
# Set Up -----
# @@@@@@@@@@@


# Initiate file for defining slurm resources to use in targets
source(here::here("_targets_resources.conf.R"))


ggplot2::theme_set(theme_bw())

options(tidyverse.quiet = TRUE)

tar_option_set(
    resources = resources_all,
    packages = c(
    "janitor",
    "lubridate",
    "tidyverse",
    "vroom"
  ),
  workspace_on_error = TRUE,
  storage = "worker",
  garbage_collection = TRUE,
  retrieval = "worker",
  memory = "transient"
)


list(
     # Download Referece for Human
     tar_file(
                hum_ref_h38_tar,
                download_ref(url_ref =  "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-and-mm10-2020-A.tar.gz",
                             path_out = here::here("data", "refdata-gex-GRCh38-and-mm10-2020-A.tar.gz")
                             )
     ),
     tar_target(
                hum_ref_h38,
                untar_ref(hum_ref_h38_tar)
     ),
     # Import mapping
     tar_file_read(
                sample_mapping_first_batch,
                here::here("data", "mapping_folders.csv"),
                read.csv(!!.x) %>%
                    mutate(path_sample = file.path(parent_folder, sample_folder))
     ),
     tar_target(
          sample_names_first_batch,
          sample_mapping_first_batch$sample_name
     ),
     tar_target(
          path_sample_first_batch,
          sample_mapping_first_batch$path_sample
     ),
    # Check if samples exist
     tar_target(
          folders_f1_checked,
          check_if_exist(path_sample_first_batch)
     ),
     tar_target(
           filtered_matrix,
           align_scrna(
                       sample_name = sample_names_first_batch,
                       path_sample = path_sample_first_batch,
                       path_out = here::here("data", "alignment_results"),
                       path_reference = hum_ref_h38,
                       localcores = 16,
                       localmem = 32
               ),
               format = "file",
               pattern = map(sample_names_first_batch, path_sample_first_batch),
               resources = resources_align
      )
)
