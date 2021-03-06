## .movingAverage
##  runs a simple 2-side moving average.
##
## params:
##  y: double, intensity values
##  halfWindowSize: integer, half window size
##  weighted: boolean, if TRUE then applies weighted average,
##      otherwise unweighted average.
## returns:
##  double
##
.movingAverage <- function(y, halfWindowSize=2L, weighted=FALSE) {
  .stopIfNotIsValidHalfWindowSize(halfWindowSize, n=length(y))

  windowSize <- 2L * halfWindowSize + 1L

  if (weighted) {
    weights <- 1 / 2^abs(-halfWindowSize:halfWindowSize)
  } else {
    weights <- rep.int(1L, windowSize)
  }
  .filter(y, hws=halfWindowSize,
          coef=matrix(weights / sum(weights),
                      nrow=windowSize, ncol=windowSize, byrow=TRUE))
}

## .savitzkyGolay
##  runs a savitzky golay filter
##
## Savitzky, A., & Golay, M. J. (1964). Smoothing and differentiation of data
## by simplified least squares procedures. Analytical chemistry, 36(8), 1627-1639.
##
## params:
##  y: double, intensity values
##  halfWindowSize: integer, half window size.
##  polynomialOrder: integer, polynomial order of sg-filter
##
## returns:
##  double
##
.savitzkyGolay <- function(y, halfWindowSize=10L, polynomialOrder=3L) {
  .stopIfNotIsValidHalfWindowSize(halfWindowSize, n=length(y))

  windowSize <- 2L * halfWindowSize + 1L

  if (windowSize < polynomialOrder) {
    stop("The window size has to be larger than the polynomial order.")
  }
  .filter(y, hws=halfWindowSize,
          coef=.savitzkyGolayCoefficients(m=halfWindowSize, k=polynomialOrder))
}

## .savitzkyGolayCoefficients
##
## Savitzky, A., & Golay, M. J. (1964). Smoothing and differentiation of data
## by simplified least squares procedures. Analytical chemistry, 36(8), 1627-1639.
##
## Implementation based on:
## Steinier, J., Termonia, Y., & Deltour, J. (1972). Comments on Smoothing and
## differentiation of data by simplified least square procedure.
## Analytical Chemistry, 44(11), 1906-1909.
##
## Implemention of left/right extrema based on:
## sgolay in signal 0.7-3/R/sgolay.R by Paul Kienzle <pkienzle@users.sf.net>
## modified by Sebastian Gibb <mail@sebastiangibb.de>
##
## params:
##  m: integer, half window size
##  k: integer, polynomial order (k == 0 = moving average)
.savitzkyGolayCoefficients <- function(m, k=3L) {
  k <- 0L:k
  nm <- 2L * m + 1L
  nk <- length(k)
  K <- matrix(k, nrow=nm, ncol=nk, byrow=TRUE)

  ## filter is applied to -m:m around current data point
  ## to avoid removing (NA) of left/right extrema
  ## lhs: 0:2*m
  ## rhs: (n-2m):n

  ## filter matrix contains 2*m+1 rows
  ## row 1:m == lhs coef
  ## row m+1 == typical sg coef
  ## row (n-m-1):n == rhs coef
  F <- matrix(double(), nrow=nm, ncol=nm)
  for (i in seq_len(m + 1L)) {
    M <- matrix(seq_len(nm) - i, nrow=nm, ncol=nk, byrow=FALSE)
    X <- M^K
    T <- solve(t(X) %*% X) %*% t(X)
    F[i, ] <- T[1L, ]
  }
  ## rhs (row (n-m):n) are equal to reversed lhs
  F[(m + 2L):nm, ] <- rev(F[seq_len(m), ])

  F
}

## .filter
##  remove time series attributes and NA at left/right extrema
.filter <- function(x, hws, coef) {
  n <- length(x)
  w <- 2L * hws + 1L
  y <- stats::filter(x=x, filter=coef[hws + 1L, ], sides=2L)
  attributes(y) <- NULL

  ## fix left/right extrema
  y[seq_len(hws)] <- head(coef, hws) %*% head(x, w)
  y[(n - hws + 1L):n] <- tail(coef, hws) %*% tail(x, w)
  y
}
