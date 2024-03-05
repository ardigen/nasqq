library(testthat)

test_that(
  desc = "Testing load_fids.R functionality",
  code = {
    script_path <- normalizePath("../../bin/load_fids.R")
    test_path <- "../../tests/testthat/"
    run_script <- function(args = c(), stdout = "", stderr = "", custom_temp_dir = tempdir()) {
      suppressWarnings(system2(
        command = "Rscript",
        args = c(script_path, args),
        stdout = stdout,
        stderr = stderr
      ))
    }
    # Test case 1: Error case when required options are missing
    output <- capture.output({
      script_res <- run_script(stderr = TRUE, stdout = "")
      expect_equal(attr(script_res, "status"), 1)
      expect_true(length(script_res) > 0)
      print(script_res[1])
      expect_true(grepl("Error: At least --id, --raw_data_path, and --pulse_program must be supplied.", script_res[1]))
    })

    # Test case 2: Success case with proper arguments
    output <- capture.output({
      script_res <- run_script(c("--id", "test", "--raw_data_path", paste0(test_path, "data/dataset/dataset1/"), "--pulse_program", "cpmgpr1d"))
      expect_equal(script_res, 0L)
      expect_true(file.exists(paste0(test_path, "results/tables/test_original_fid_list.rds")))
      expect_true(file.exists(paste0(test_path, "results/tables/test_selected_fid_list.rds")))
    })
    on.exit(unlink(paste0(test_path,"results"), recursive = TRUE))
  }
)
