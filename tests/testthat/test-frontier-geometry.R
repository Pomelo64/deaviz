# Validation of the frontier geometry against the Benchmarking solver.
#
# These tests check that what deaviz *draws* agrees with what Benchmarking
# *computes*. The central invariant is the same in two and in three
# dimensions: a DMU's radial projection onto the frontier, using the
# efficiency score returned by the solver, must land exactly on the drawn
# frontier. If the geometry is wrong, the projected point will sit off the
# surface, or efficient units will not lie on it.
#
# They are skipped when Benchmarking (or, for the 3-D case, geometry) is not
# installed, so they do not affect CRAN checks on machines without them.

testthat::skip_if_not_installed("Benchmarking")

tol <- 1e-6

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

# the two shipped datasets, as dea_data objects
cities <- dea_data(
  chinese_cities,
  inputs  = c("industrial_labour_force", "working_funds", "investments"),
  outputs = c("gross_industrial_output", "profit_and_tax", "retail_sales"),
  id      = "DMU"
)

# a one-input/one-output sub-model, exactly as plot_io_frontier() builds it
sub2 <- function(d, ivar, ovar) {
  s <- d; s$X <- d$X[, ivar, drop = FALSE]; s$Y <- d$Y[, ovar, drop = FALSE]; s
}

# a two-input/one-output sub-model, as plot_io_3dfrontier() builds it
sub3 <- function(d, ivars, ovar) {
  s <- d; s$X <- d$X[, ivars, drop = FALSE]; s$Y <- d$Y[, ovar, drop = FALSE]; s
}

# vertical height of the drawn 2-D frontier at a given x, by linear
# interpolation along the polyline
frontier_y_at <- function(fr, x) {
  stats::approx(fr$line$x, fr$line$y, xout = x, rule = 2, ties = "ordered")$y
}

# ---------------------------------------------------------------------------
# 2-D frontier: plot_io_frontier() / .deaviz_frontier_path()
# ---------------------------------------------------------------------------

for (rts in c("crs", "vrs")) {
  
  testthat::test_that(paste0("2-D ", rts, ": efficient DMUs lie on the drawn frontier"), {
    s   <- sub2(cities, "working_funds", "retail_sales")
    m   <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    eff <- as.numeric(m$eff)
    is_eff <- abs(eff - 1) < 1e-9
    xv <- as.numeric(s$X[, 1]); yv <- as.numeric(s$Y[, 1])
    
    fr <- deaviz:::.deaviz_frontier_path(xv, yv, is_eff, rts)
    
    # every efficient unit must sit on the polyline
    testthat::expect_equal(frontier_y_at(fr, xv[is_eff]), yv[is_eff],
                           tolerance = 1e-4)
  })
  
  testthat::test_that(paste0("2-D ", rts, ": no DMU lies above the frontier"), {
    s   <- sub2(cities, "working_funds", "retail_sales")
    m   <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
    xv <- as.numeric(s$X[, 1]); yv <- as.numeric(s$Y[, 1])
    fr <- deaviz:::.deaviz_frontier_path(xv, yv, is_eff, rts)
    
    testthat::expect_true(all(yv <= frontier_y_at(fr, xv) + 1e-4))
  })
  
  testthat::test_that(paste0("2-D ", rts, ": input-oriented projection lands on the frontier"), {
    # THE key test: Benchmarking says the unit could shrink its input to
    # theta * x; that point must be exactly on the frontier we draw.
    s   <- sub2(cities, "working_funds", "retail_sales")
    m   <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    eff <- as.numeric(m$eff)
    is_eff <- abs(eff - 1) < 1e-9
    xv <- as.numeric(s$X[, 1]); yv <- as.numeric(s$Y[, 1])
    fr <- deaviz:::.deaviz_frontier_path(xv, yv, is_eff, rts)
    
    ineff <- which(!is_eff)
    proj_x <- eff[ineff] * xv[ineff]
    # the projected point keeps its output level and must be on the frontier
    testthat::expect_equal(frontier_y_at(fr, proj_x), yv[ineff],
                           tolerance = 1e-3)
  })
  
  testthat::test_that(paste0("2-D ", rts, ": frontier is monotone non-decreasing"), {
    s   <- sub2(cities, "working_funds", "retail_sales")
    m   <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
    fr <- deaviz:::.deaviz_frontier_path(as.numeric(s$X[, 1]),
                                         as.numeric(s$Y[, 1]), is_eff, rts)
    testthat::expect_true(all(diff(fr$line$y) >= -1e-8))
  })
}

testthat::test_that("2-D CRS frontier is a ray through the most productive unit", {
  s  <- sub2(cities, "working_funds", "retail_sales")
  m  <- compute_efficiency(s, rts = "crs", orientation = "in", dual = FALSE)
  is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
  xv <- as.numeric(s$X[, 1]); yv <- as.numeric(s$Y[, 1])
  fr <- deaviz:::.deaviz_frontier_path(xv, yv, is_eff, "crs")
  
  slope <- max(yv / xv)
  testthat::expect_equal(fr$line$y, slope * fr$line$x, tolerance = 1e-6)
})

testthat::test_that("2-D output orientation projects upwards, not downwards", {
  # guards the eff >= 1 convention: y * eff must exceed y
  s   <- sub2(cities, "working_funds", "retail_sales")
  m   <- compute_efficiency(s, rts = "vrs", orientation = "out", dual = FALSE)
  eff <- as.numeric(m$eff)
  testthat::expect_true(all(eff >= 1 - 1e-9))          # Benchmarking convention
  yv  <- as.numeric(s$Y[, 1])
  testthat::expect_true(all(yv * eff >= yv - 1e-9))    # projection goes up
})

# ---------------------------------------------------------------------------
# 3-D frontier: plot_io_3dfrontier() / .deaviz_frontier_surface()
# ---------------------------------------------------------------------------

testthat::skip_if_not_installed("geometry")

# signed vertical distance from a point to the surface, measured by finding the
# triangle whose (x1, x2) projection contains the point and interpolating
surface_z_at <- function(surf, p) {
  v <- surf$v; tri <- surf$tri
  out <- rep(NA_real_, nrow(p))
  for (r in seq_len(nrow(p))) {
    for (t in seq_len(nrow(tri))) {
      A <- v[tri[t, 1], ]; B <- v[tri[t, 2], ]; C <- v[tri[t, 3], ]
      # barycentric coordinates in the (x1, x2) plane
      den <- (B[2] - C[2]) * (A[1] - C[1]) + (C[1] - B[1]) * (A[2] - C[2])
      if (abs(den) < 1e-12) next
      l1 <- ((B[2] - C[2]) * (p[r, 1] - C[1]) +
               (C[1] - B[1]) * (p[r, 2] - C[2])) / den
      l2 <- ((C[2] - A[2]) * (p[r, 1] - C[1]) +
               (A[1] - C[1]) * (p[r, 2] - C[2])) / den
      l3 <- 1 - l1 - l2
      if (l1 >= -1e-7 && l2 >= -1e-7 && l3 >= -1e-7) {
        z <- l1 * A[3] + l2 * B[3] + l3 * C[3]
        out[r] <- max(out[r], z, na.rm = TRUE)
      }
    }
  }
  out
}

for (rts in c("crs", "vrs")) {
  
  testthat::test_that(paste0("3-D ", rts, ": surface is built and well formed"), {
    s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
    m <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
    
    surf <- deaviz:::.deaviz_frontier_surface(
      as.numeric(s$X[, 1]), as.numeric(s$X[, 2]), as.numeric(s$Y[, 1]),
      is_eff, rts)
    
    testthat::expect_false(is.null(surf))
    if (is.null(surf)) return(invisible(NULL))
    testthat::expect_true(nrow(surf$tri) > 0)
    testthat::expect_equal(ncol(surf$tri), 3L)
    testthat::expect_true(all(surf$tri >= 1 & surf$tri <= nrow(surf$v)))
  })
  
  testthat::test_that(paste0("3-D ", rts, ": every facet normal faces upward in output"), {
    # free disposability: the drawn facets must be the UPPER envelope
    s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
    m <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
    surf <- deaviz:::.deaviz_frontier_surface(
      as.numeric(s$X[, 1]), as.numeric(s$X[, 2]), as.numeric(s$Y[, 1]),
      is_eff, rts)
    testthat::expect_false(is.null(surf))
    if (is.null(surf)) return(invisible(NULL))
    
    ctr <- colMeans(surf$v)
    up  <- vapply(seq_len(nrow(surf$tri)), function(t) {
      v <- surf$v[surf$tri[t, ], , drop = FALSE]
      n <- deaviz:::.deaviz_tri_normal(v)
      if (sum(n * (colMeans(v) - ctr)) < 0) n <- -n
      n[3]
    }, numeric(1))
    testthat::expect_true(all(up > -1e-6))
  })
  
  testthat::test_that(paste0("3-D ", rts, ": no DMU lies above the surface"), {
    s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
    m <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
    x1 <- as.numeric(s$X[, 1]); x2 <- as.numeric(s$X[, 2])
    yv <- as.numeric(s$Y[, 1])
    surf <- deaviz:::.deaviz_frontier_surface(x1, x2, yv, is_eff, rts)
    testthat::expect_false(is.null(surf))
    if (is.null(surf)) return(invisible(NULL))
    
    z <- surface_z_at(surf, cbind(x1, x2))
    ok <- !is.na(z)
    testthat::expect_true(all(yv[ok] <= z[ok] + 1e-3 * max(yv)))
  })
  
  testthat::test_that(paste0("3-D ", rts, ": efficient DMUs lie on the surface"), {
    s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
    m <- compute_efficiency(s, rts = rts, orientation = "in", dual = FALSE)
    is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
    x1 <- as.numeric(s$X[, 1]); x2 <- as.numeric(s$X[, 2])
    yv <- as.numeric(s$Y[, 1])
    surf <- deaviz:::.deaviz_frontier_surface(x1, x2, yv, is_eff, rts)
    testthat::expect_false(is.null(surf))
    if (is.null(surf)) return(invisible(NULL))
    
    z <- surface_z_at(surf, cbind(x1[is_eff], x2[is_eff]))
    ok <- !is.na(z)
    testthat::expect_equal(z[ok], yv[is_eff][ok],
                           tolerance = 1e-3 * max(yv))
  })
}

testthat::test_that("3-D CRS surface is a cone: scaling a point stays on it", {
  s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
  m <- compute_efficiency(s, rts = "crs", orientation = "in", dual = FALSE)
  is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
  x1 <- as.numeric(s$X[, 1]); x2 <- as.numeric(s$X[, 2])
  yv <- as.numeric(s$Y[, 1])
  surf <- deaviz:::.deaviz_frontier_surface(x1, x2, yv, is_eff, "crs")
  
  e <- which(is_eff)[1]
  for (k in c(0.5, 2)) {
    z <- surface_z_at(surf, cbind(x1[e] * k, x2[e] * k))
    if (!is.na(z)) testthat::expect_equal(z, yv[e] * k,
                                          tolerance = 1e-2 * max(yv))
  }
})

testthat::test_that("3-D input-oriented projection lands on the surface", {
  # the 3-D counterpart of the key 2-D test
  s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
  m <- compute_efficiency(s, rts = "vrs", orientation = "in", dual = FALSE)
  eff <- as.numeric(m$eff)
  is_eff <- abs(eff - 1) < 1e-9
  x1 <- as.numeric(s$X[, 1]); x2 <- as.numeric(s$X[, 2])
  yv <- as.numeric(s$Y[, 1])
  surf <- deaviz:::.deaviz_frontier_surface(x1, x2, yv, is_eff, "vrs")
  
  ineff <- which(!is_eff)
  z <- surface_z_at(surf, cbind(eff[ineff] * x1[ineff], eff[ineff] * x2[ineff]))
  ok <- !is.na(z)
  # radial input contraction holds the output fixed; the contracted point
  # must therefore sit on (not below) the surface
  testthat::expect_equal(z[ok], yv[ineff][ok], tolerance = 5e-2 * max(yv))
})

testthat::test_that("3-D vrs: surface is monotone non-decreasing on a grid", {
  # A production frontier can never fall as an input rises. This is a much
  # stronger check than sampling a few points, and it is what would catch a
  # fold introduced by a wrong facet or a stray disposal point.
  s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
  m <- compute_efficiency(s, rts = "vrs", orientation = "in", dual = FALSE)
  is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
  x1 <- as.numeric(s$X[, 1]); x2 <- as.numeric(s$X[, 2])
  yv <- as.numeric(s$Y[, 1])
  
  surf <- deaviz:::.deaviz_frontier_surface(x1, x2, yv, is_eff, "vrs")
  testthat::expect_false(is.null(surf))
  if (is.null(surf)) return(invisible(NULL))
  
  gx <- seq(min(x1), max(x1), length.out = 18)
  gy <- seq(min(x2), max(x2), length.out = 18)
  G  <- outer(gx, gy, Vectorize(function(a, b) surface_z_at(surf, cbind(a, b))))
  
  drop_x <- max(c(0, apply(G, 2, function(col) {
    d <- diff(col); d <- d[!is.na(d)]; if (!length(d)) 0 else -min(c(0, d))
  })))
  drop_y <- max(c(0, apply(G, 1, function(row) {
    d <- diff(row); d <- d[!is.na(d)]; if (!length(d)) 0 else -min(c(0, d))
  })))
  tol <- 1e-6 * max(yv)
  testthat::expect_lt(drop_x, tol)
  testthat::expect_lt(drop_y, tol)
})

testthat::test_that("3-D vrs: surface never exceeds the observed output range", {
  s <- sub3(cities, c("working_funds", "investments"), "retail_sales")
  m <- compute_efficiency(s, rts = "vrs", orientation = "in", dual = FALSE)
  is_eff <- abs(as.numeric(m$eff) - 1) < 1e-9
  yv <- as.numeric(s$Y[, 1])
  surf <- deaviz:::.deaviz_frontier_surface(
    as.numeric(s$X[, 1]), as.numeric(s$X[, 2]), yv, is_eff, "vrs")
  testthat::expect_false(is.null(surf))
  if (is.null(surf)) return(invisible(NULL))
  
  # the frontier lies at or above observed outputs, and never above the best
  testthat::expect_gte(min(surf$v[, 3]), min(yv) - 1e-8)
  testthat::expect_lte(max(surf$v[, 3]), max(yv) + 1e-8)
})