test_that("cr_build_experiment assembles and validates", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_s3_class(exp, "cr_experiment")
  expect_true(all(c("cells", "design", "channels") %in% names(exp)))
  expect_true(cr_validate_experiment(exp))
  expect_equal(exp$spatial_unit, "well")
})

test_that("validation catches missing spatial unit", {
  cells <- tibble::tibble(cell_id = "c1", x = 1, y = 1, area = 10,
                          marker_1 = 1)
  design <- tibble::tibble(well = "A01", treatment = "t1")
  expect_error(cr_build_experiment(cells, design), "spatial unit")
})

test_that("validation catches missing treatment", {
  cells <- tibble::tibble(cell_id = "c1", well = "A01", area = 10,
                          marker_1 = 1)
  design <- tibble::tibble(well = "A01")
  expect_error(cr_build_experiment(cells, design), "treatment")
})

test_that("validation catches wells in cells not covered by design", {
  cells <- tibble::tibble(cell_id = c("c1", "c2"),
                          well = c("A01", "B02"),
                          area = c(10, 20), marker_1 = c(1, 2))
  design <- tibble::tibble(well = "A01", treatment = "t1")
  expect_error(cr_build_experiment(cells, design), "does not cover")
})

test_that("auto-detected channels exclude morphology columns", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 5)
  expect_true("DAPI" %in% exp$channels$channel)
  expect_false("area" %in% exp$channels$channel)
  expect_false("x" %in% exp$channels$channel)
})
