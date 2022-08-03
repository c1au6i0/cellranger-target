---
output: github_document
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



# barb-mars

<!-- badges: start -->
<!-- badges: end -->

Repo of Collaboration with


Project uses `{targets}`and `{renv}` and `{here}`. 

`data\` : contains 

`code\` : functions called by `_targets.R` in `here::here("code", "targets_functions"))`

`reports\`: output files

# Howto

Initialize and install packages with:

```
renv::restore()
```

Run the pipeline.

```
targets::tar_make()
```

Check manifest with `targets::tar_manifest()` and Load targets with `targets::tar_load("name_of_target)`


