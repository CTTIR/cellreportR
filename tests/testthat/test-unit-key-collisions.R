test_that("distinct unit tuples cannot silently collapse through separators", {
  x <- data.frame(compound = c("a|b", "a"), plate = c("c", "b|c"), replicate = "1")
  expect_error(cr_assign_units(x, c("compound", "plate")), "unit key collision")
  out <- cr_assign_units(x, c("compound", "plate"), sep = "::")
  expect_equal(attr(out, "n_units"), 2L)
  expect_length(unique(out$well_id), 2L)
  missing <- data.frame(compound = c(NA_character_, "NA"), replicate = "1")
  expect_error(cr_assign_units(missing, "compound"), "unit key collision")
})

test_that("declared merges and repeated rows retain one analysis unit", {
  x <- data.frame(compound = "a|b", replicate = c("1", "1.1", "1"),
                  merge_unit = c(FALSE, TRUE, FALSE))
  out <- cr_assign_units(x, "compound")
  expect_equal(attr(out, "n_units"), 1L)
  expect_identical(out$replicate_merged, rep("1", 3))
  expect_length(unique(out$well_id), 1L)
})
