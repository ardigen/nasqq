library(testthat)

test_that(
  desc = "Testing script functionality",
  code = {
    script_path <- "../../bin/raw_fids_visualisation.R"
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
      expect_equal(attr(script_res, "status"), 1) # script returned an error
      expect_true(length(script_res) > 0) # error message has been provided
      expect_true(grepl("Error: --id and --raw_rds must be provided.", script_res))
    })

    # Test case 2: Success case with proper arguments
    output <- capture.output({
      script_res <- run_script(c("--id", "test", "--raw_rds", paste0(test_path, "data/test_dataset.rds")))
      expect_equal(script_res, 0L) # script succeeded
      expect_true(file.exists(paste0("test_", test_path, "raw_plots_list.rds")))
    })

    # Cleanup after tests
    on.exit(unlink(paste0("test_", test_path), recursive = TRUE))
  }
)