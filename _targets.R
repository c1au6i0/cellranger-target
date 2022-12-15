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
     # @@@@@@@@@@@
     # Set up ----
     # @@@@@@@@@@@

     # Download Referece for Human
     tar_file(
                hum_ref_h38_tar,
                download_ref(url_ref =  "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-and-mm10-2020-A.tar.gz",
                             path_out = here::here("data", "referece", "refdata-gex-GRCh38-and-mm10-2020-A.tar.gz")
                             )
     ),
     tar_target(
                hum_ref_h38,
                untar_ref(hum_ref_h38_tar)
     ),

     # @@@@@@@@@@@@@@@@@@@
     # First Batch ----
     # @@@@@@@@@@@@@@@@@@@

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
     # @@@@@@@@@@@
     # Align ----
     # @@@@@@@@@@@

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
      ),
     # @@@@@@@@@@@@@@@@@@@
     # Second Batch ----
     # @@@@@@@@@@@@@@@@@@@

     # Import mapping
     tar_file_read(
                sample_mapping_second_batch,
                here::here("data", "mapping_folders_2.csv"),
                read.csv(!!.x) %>%
                    mutate(path_sample = file.path(parent_folder, sample_folder))
     ),
     tar_target(
          sample_names_second_batch,
          sample_mapping_second_batch$sample_name
     ),
     tar_target(
          path_sample_second_batch,
          sample_mapping_second_batch$path_sample
     ),
    # Check if samples exist
     tar_target(
          folders_f2_checked,
          check_if_exist(path_sample_second_batch)
     ),
     # @@@@@@@@@@@@
     # Align 2 ----
     # @@@@@@@@@@@@

     # 2 samples have a different mixuture of R1 lenghts and so they were analized separatelly so that --r1-length flag could be
     # set. The funcion align_scrna_2 has just a ... argument. The orginal function was not changed to avoid to realign all the samples.
     tar_target(
           filtered_matrix_2,
           align_scrna_2(
                       sample_name = sample_names_second_batch,
                       path_sample = path_sample_second_batch,
                       path_out = here::here("data", "alignment_results"),
                       path_reference = hum_ref_h38,
                       localcores = 16,
                       localmem = 32,
                       other_args = " --r1-length=26 "
               ),
               format = "file",
               pattern = map(sample_names_second_batch, path_sample_second_batch),
               resources = resources_align
      ),
     # @@@@@@@@@@@@@@@@@@@@@
     # Combine targets ----
     # @@@@@@@@@@@@@@@@@@@@@
     tar_target(
          all_matrixes,
          append(filtered_matrix_2, filtered_matrix)
          ),
     # csv used by cellranger aggr to aggregate the data. Note normalize=none
     tar_file(
          aggr_csv,
          {
          create_aggr_df(all_matrixes) %>%
            distinct(sample_id, .keep_all = TRUE) %>%
            write.csv(file = here::here("data", "batch_1_2_aggr.csv"), row.names = FALSE)
            here::here("data", "batch_1_2_aggr.csv")
          }
     ),
     # Aggregate filtered_matrix
     tar_target(
           filtered_matrix_aggr,
           cellranger_aggr(
                       id_pj = "batch_1_2",
                       path_csv = aggr_csv,
                       path_out = here::here("data", "alignment_results"),
                       localcores = 16,
                       localmem = 32
               ),
               format = "file",
               resources = resources_align
      )
)
