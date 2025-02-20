<<<<<<< HEAD
#' Ken Deng, s2617343
#' Add your own function definitions on this file.

#' Log-Exponential density
#'
#' Compute the density or log-density for a Log-Exponential (LogExp)
#' distribution
#'
#' @param x vector of quantiles
#' @param rate vector of rates
#' @param log logical; if TRUE, the log-density is returned

dlogexp <- function(x, rate = 1, log = FALSE) {
  result <- log(rate) + x - rate * exp(x)
  if (!log) {
    exp(result)
  }
  result
}


#' Log-Sum-Exp
#'
#' Convenience function for computing log(sum(exp(x))) in a
#' numerically stable manner
#'
#' @param x numerical vector

log_sum_exp <- function(x) {
  max_x <- max(x, na.rm = TRUE)
  max_x + log(sum(exp(x - max_x)))
}

#' wquantile
#'
#' Calculates empirical sample quantiles with optional weights, for given probabilities.
#' Like in quantile(), the smallest observation corresponds to a probability of 0 and the largest to a probability of 1.
#' Interpolation between discrete values is done when type=7, as in quantile().
#' Use type=1 to only generate quantile values from the raw input samples.
#'
#' @param x numeric vector whose sample quantiles are wanted
#' NA and NaN values are not allowed in numeric vectors unless na.rm is TRUE
#' @param probs numeric vector of probabilities with values in [0,1]
#' @param na.rm logical; if true, any NA and NaN's are removed from x before the quantiles are computed
#' @param type numeric, 1 for no interpolation, or 7, for interpolated quantiles. Default is 7
#' @param weights	 numeric vector of non-negative weights, the same length as x, or NULL. The weights are normalised to sum to 1. If NULL, then wquantile(x) behaves the same as quantile(x), with equal weight for each sample value

wquantile <- function(x, probs = seq(0, 1, 0.25), na.rm = FALSE, type = 7,
                      weights = NULL, ...) {
  if (is.null(weights) || (length(weights) == 1)) {
    weights <- rep(1, length(x))
  }
  stopifnot(all(weights >= 0))
  stopifnot(length(weights) == length(x))
  if (length(x) == 1) {
    return(rep(x, length(probs)))
  }
  n <- length(x)
  q <- numeric(length(probs))
  reorder <- order(x)
  weights <- weights[reorder]
  x <- x[reorder]
  wecdf <- pmin(1, cumsum(weights) / sum(weights))
  if (type == 1) {
  } else {
    weights2 <- (weights[-n] + weights[-1]) / 2
    wecdf2 <- pmin(1, cumsum(weights2) / sum(weights2))
  }
  for (pr_idx in seq_along(probs)) {
    pr <- probs[pr_idx]
    if (pr <= 0) {
      q[pr_idx] <- x[1]
    } else if (pr >= 1) {
      q[pr_idx] <- x[n]
    } else {
      if (type == 1) {
        j <- 1 + pmax(0, pmin(n - 1, sum(wecdf <= pr)))
        q[pr_idx] <- x[j]
      } else {
        j <- 1 + pmax(0, pmin(n - 2, sum(wecdf2 <= pr)))
        g <- (pr - c(0, wecdf2)[j]) / (wecdf2[j] - c(
          0,
          wecdf2
        )[j])
        q[pr_idx] <- (1 - g) * x[j] + g * x[j + 1]
      }
    }
  }
  q
}

#' Compute empirical weighted cumulative distribution
#'
#' Version of `ggplot2::stat_ecdf` that adds a `weights` property for each
#' observation, to produce an empirical weighted cumulative distribution function.
#' The empirical cumulative distribution function (ECDF) provides an alternative
#' visualisation of distribution. Compared to other visualisations that rely on
#' density (like [geom_histogram()]), the ECDF doesn't require any
#' tuning parameters and handles both continuous and discrete variables.
#' The downside is that it requires more training to accurately interpret,
#' and the underlying visual tasks are somewhat more challenging.
#'
# @inheritParams layer
# @inheritParams geom_point
#' @param na.rm If `FALSE` (the default), removes missing values with
#'    a warning.  If `TRUE` silently removes missing values.
#' @param n if NULL, do not interpolate. If not NULL, this is the number
#'   of points to interpolate with.
#' @param pad If `TRUE`, pad the ecdf with additional points (-Inf, 0)
#'   and (Inf, 1)
#' @section Computed variables:
#' \describe{
#'   \item{x}{x in data}
#'   \item{y}{cumulative density corresponding x}
#' }
#' @seealso wquantile
#' @export
#' @examples
#' library(ggplot2)
#'
#' n <- 100
#' df <- data.frame(
#'   x = c(rnorm(n, 0, 10), rnorm(n, 0, 10)),
#'   g = gl(2, n),
#'   w = c(rep(1 / n, n), sort(runif(n))^sqrt(n))
#' )
#' ggplot(df, aes(x, weights = w)) +
#'   stat_ewcdf(geom = "step")
#'
#' # Don't go to positive/negative infinity
#' ggplot(df, aes(x, weights = w)) +
#'   stat_ewcdf(geom = "step", pad = FALSE)
#'
#' # Multiple ECDFs
#' ggplot(df, aes(x, colour = g, weights = w)) +
#'   stat_ewcdf()
#' ggplot(df, aes(x, colour = g, weights = w)) +
#'   stat_ewcdf() +
#'   facet_wrap(vars(g), ncol = 1)
stat_ewcdf <- function(mapping = NULL, data = NULL,
                       geom = "step", position = "identity",
                       ...,
                       n = NULL,
                       pad = TRUE,
                       na.rm = FALSE,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = StatEwcdf,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      n = n,
      pad = pad,
      na.rm = na.rm,
      ...
    )
  )
}


#' @title StatEwcdf ggproto object
#' @name StatEwcdf
#' @rdname StatEwcdf
#' @aliases StatEwcdf
#' @format NULL
#' @usage NULL
#' @export
#' @importFrom ggplot2 aes after_stat has_flipped_aes Stat
NULL

StatEwcdf <- ggplot2::ggproto(
  "StatEwcdf", ggplot2::Stat,
  required_aes = c("x|y", "weights"),
  dropped_aes = c("weights"),
  default_aes = ggplot2::aes(y = ggplot2::after_stat(y)),
  setup_params = function(data, params) {
    params$flipped_aes <-
      ggplot2::has_flipped_aes(data,
        params,
        main_is_orthogonal = FALSE,
        main_is_continuous = TRUE
      )

    has_x <- !(is.null(data$x) && is.null(params$x))
    has_y <- !(is.null(data$y) && is.null(params$y))
    if (!has_x && !has_y) {
      rlang::abort("stat_ewcdf() requires an x or y aesthetic.")
    }
    has_weights <- !(is.null(data$weights) && is.null(params$weights))
    #    if (!has_weights) {
    #      rlang::abort("stat_ewcdf() requires a weights aesthetic.")
    #    }

    params
  },
  compute_group = function(data, scales, n = NULL, pad = TRUE, flipped_aes = FALSE) {
    data <- flip_data(data, flipped_aes)
    # If n is NULL, use raw values; otherwise interpolate
    if (is.null(n)) {
      x <- unique(data$x)
    } else {
      x <- seq(min(data$x), max(data$x), length.out = n)
    }

    if (pad) {
      x <- c(-Inf, x, Inf)
    }
    if (is.null(data$weights)) {
      data_ecdf <- ecdf(data$x)(x)
    } else {
      data_ecdf <-
        spatstat.geom::ewcdf(
          data$x,
          weights = data$weights / sum(abs(data$weights))
        )(x)
    }

    df_ecdf <- vctrs::new_data_frame(list(x = x, y = data_ecdf), n = length(x))
    df_ecdf$flipped_aes <- flipped_aes
    ggplot2::flip_data(df_ecdf, flipped_aes)
  }
)

#' Neg-Log-Likelihood
#'
#' According to the selected model, the negative log-likelihood function is calculated
#'
#' @param beta model parameter
#' @param data data.frame containing CAD_Weight and Actual_Weight
#' @param model model selection, A or B

neg_log_like <- function(beta, data, model) {
  X.vec <- data$CAD_Weight
  Y.vec <- data$Actual_Weight

  if (model == "A") {
    log.dense.vec <- dnorm(Y.vec,
      mean = beta[1] + beta[2] * X.vec,
      sd = sqrt(exp(beta[3] + beta[4] * X.vec)),
      log = TRUE
    )
    return(-sum(log.dense.vec)) # return negative log_likelihood
  } else if (model == "B") {
    log.dense.vec <- dnorm(Y.vec,
      mean = beta[1] + beta[2] * X.vec,
      sd = sqrt(exp(beta[3]) + exp(beta[4]) * X.vec^2),
      log = TRUE
    )
    return(-sum(log.dense.vec)) # return negative log_likelihood
  } else {
    stop("Unknown model. Please specify model A or B.")
  }
}

#' Model parameter estimation
#'
#' According to the selected model,
#' optim() is used to perform convergence calculation from different initial values,
#' and finally the optimal model parameters and corresponding hessian matrix are returned
#'
#' @param data data.frame containing CAD_Weight and Actual_Weight
#' @param model model selection, A or B

filament1_estimate <- function(data, model) {
  if (model == "A") {
    beta0 <- c(-0.1, 1.07, -2, 0.05)
    result <- optim(
      par = beta0,
      fn = neg_log_like,
      data = data,
      model = model,
      hessian = TRUE
    )
    return(list(optimal = result$par, hessian = result$hessian))
    # return model parameters estimation and Hessian matrix at estimators
  } else {
    beta0 <- c(-0.15, 1.07, -13.5, -6.5)
    result <- optim(
      par = beta0,
      fn = neg_log_like,
      data = data,
      model = model,
      hessian = TRUE
    )
    return(list(optimal = result$par, hessian = result$hessian))
    # return model parameters estimation and Hessian matrix at estimators
  }
}

#' Log_prior_density
#'
#' Assuming that the model parameters are also random variables,
#' the prior logarithmic probability density is calculated
#'
#' @param theta model parameters
#' @param params parameters of the prior distribution of theta

log_prior_density <- function(theta, params) {
  log.d1 <- dnorm(theta[1], mean = 0, sd = sqrt(params[1]), log = TRUE)
  log.d2 <- dnorm(theta[2], mean = 1, sd = sqrt(params[2]), log = TRUE)
  log.d3 <- dlogexp(theta[3], rate = params[3], log = TRUE)
  log.d4 <- dlogexp(theta[4], rate = params[4], log = TRUE)
  log.dense.vec <- c(log.d1, log.d2, log.d3, log.d4)
  return(sum(log.dense.vec)) # return log joint density
}

#' Log_likelihood
#'
#' Calculate the log-likelihood function of the model parameters for given samples
#'
#' @param theta model parameters
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter

log_like <- function(theta, x, y) {
  log.dense.vec <- dnorm(y,
    mean = theta[1] + theta[2] * x,
    sd = sqrt(exp(theta[3]) + exp(theta[4]) * (x)^2),
    log = TRUE
  )
  return(sum(log.dense.vec)) # return log-likelihood
}

#' Log_posterior_density
#'
#' Calculate the probability density of the posterior distribution of the model parameters
#'
#' @param theta model parameters
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter
#' @param params parameters of the prior distribution of theta

log_posterior_density <- function(theta, x, y, params) {
  return(log_prior_density(theta = theta, params = params) + log_like(theta = theta, x = x, y = y))
  # return log posterior density
}

#' Approximation of the mean and covariance matrix of a Gaussian distribution
#'
#' optim() is used to calculate the maximum point and hessian matrix
#' of the probability density of the posterior distribution,
#' and returns the inverse of the maximum point and the negative hessian matrix
#'
#' @param theta_start The initial theta of the optim() process
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter
#' @param params parameters of the prior distribution of theta

posterior_mode <- function(theta_start, x, y, params) {
  result <- optim(
    par = theta_start,
    fn = log_posterior_density,
    x = x, y = y, params = params,
    hessian = TRUE,
    control = list(fnscale = -1)
  ) # Do maximisation instead of minimisation
  S <- solve(-result$hessian) # Compute the inverse of a negative hessian matrix
  return(list(mode = result$par, hessian = result$hessian, S = S))
  # return model parameters estimation and Hessian and S matrix at estimators
}

#' Importance Sampling
#'
#' The approximate Gaussian distribution is used to sample,
#' and the weights are set for each sample to better approximate the original distribution
#'
#' @param N number of samples
#' @param mu approximate Gaussian distribution mean
#' @param S covariance matrix of approximate Gaussian distribution
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter
#' @param params parameters of the prior distribution of theta

do_importance <- function(N, mu, S, x, y, params) {
  X <- rmvnorm(N, mean = mu, sigma = S)
  log.weights <- numeric(N)
  for (i in 1:N) {
    log.weights[i] <- log_posterior_density(X[i, ], x = x, y = y, params = params) - dmvnorm(X[i, ], mean = mu, sigma = S, log = TRUE)
    # Compute the logarithm of weights
  }
  normalized.log.weights <- log.weights - log_sum_exp(x = log.weights) # Normalization
  return(data.frame(beta1 = X[, 1], beta2 = X[, 2], beta3 = exp(X[, 3]), beta4 = exp(X[, 4]), log_weights = normalized.log.weights))
  # return all samples and corresponding normalized log-weight
}

#' Calculated prediction interval
#'
#' For a given set of weighted samples,
#' the quantile is calculated to construct the prediction interval
#'
#' @param x samples
#' @param weights weight of samples
#' @param prob the probability of the quantile, formatted as c(alpha, 1 - alpha)

make_CI <- function(x, weights, prob) {
  quantiles <- wquantile(x, probs = prob, weights = weights)
  return(data.frame(lower = min(quantiles), upper = max(quantiles)))
  # return prediction interval estimation based on samples with normalized weight
}
=======
#' Ken Deng, s2617343
#' Add your own function definitions on this file.

#' Log-Exponential density
#'
#' Compute the density or log-density for a Log-Exponential (LogExp)
#' distribution
#'
#' @param x vector of quantiles
#' @param rate vector of rates
#' @param log logical; if TRUE, the log-density is returned

dlogexp <- function(x, rate = 1, log = FALSE) {
  result <- log(rate) + x - rate * exp(x)
  if (!log) {
    exp(result)
  }
  result
}


#' Log-Sum-Exp
#'
#' Convenience function for computing log(sum(exp(x))) in a
#' numerically stable manner
#'
#' @param x numerical vector

log_sum_exp <- function(x) {
  max_x <- max(x, na.rm = TRUE)
  max_x + log(sum(exp(x - max_x)))
}

#' wquantile
#'
#' Calculates empirical sample quantiles with optional weights, for given probabilities.
#' Like in quantile(), the smallest observation corresponds to a probability of 0 and the largest to a probability of 1.
#' Interpolation between discrete values is done when type=7, as in quantile().
#' Use type=1 to only generate quantile values from the raw input samples.
#'
#' @param x numeric vector whose sample quantiles are wanted
#' NA and NaN values are not allowed in numeric vectors unless na.rm is TRUE
#' @param probs numeric vector of probabilities with values in [0,1]
#' @param na.rm logical; if true, any NA and NaN's are removed from x before the quantiles are computed
#' @param type numeric, 1 for no interpolation, or 7, for interpolated quantiles. Default is 7
#' @param weights	 numeric vector of non-negative weights, the same length as x, or NULL. The weights are normalised to sum to 1. If NULL, then wquantile(x) behaves the same as quantile(x), with equal weight for each sample value

wquantile <- function(x, probs = seq(0, 1, 0.25), na.rm = FALSE, type = 7,
                      weights = NULL, ...) {
  if (is.null(weights) || (length(weights) == 1)) {
    weights <- rep(1, length(x))
  }
  stopifnot(all(weights >= 0))
  stopifnot(length(weights) == length(x))
  if (length(x) == 1) {
    return(rep(x, length(probs)))
  }
  n <- length(x)
  q <- numeric(length(probs))
  reorder <- order(x)
  weights <- weights[reorder]
  x <- x[reorder]
  wecdf <- pmin(1, cumsum(weights) / sum(weights))
  if (type == 1) {
  } else {
    weights2 <- (weights[-n] + weights[-1]) / 2
    wecdf2 <- pmin(1, cumsum(weights2) / sum(weights2))
  }
  for (pr_idx in seq_along(probs)) {
    pr <- probs[pr_idx]
    if (pr <= 0) {
      q[pr_idx] <- x[1]
    } else if (pr >= 1) {
      q[pr_idx] <- x[n]
    } else {
      if (type == 1) {
        j <- 1 + pmax(0, pmin(n - 1, sum(wecdf <= pr)))
        q[pr_idx] <- x[j]
      } else {
        j <- 1 + pmax(0, pmin(n - 2, sum(wecdf2 <= pr)))
        g <- (pr - c(0, wecdf2)[j]) / (wecdf2[j] - c(
          0,
          wecdf2
        )[j])
        q[pr_idx] <- (1 - g) * x[j] + g * x[j + 1]
      }
    }
  }
  q
}

#' Compute empirical weighted cumulative distribution
#'
#' Version of `ggplot2::stat_ecdf` that adds a `weights` property for each
#' observation, to produce an empirical weighted cumulative distribution function.
#' The empirical cumulative distribution function (ECDF) provides an alternative
#' visualisation of distribution. Compared to other visualisations that rely on
#' density (like [geom_histogram()]), the ECDF doesn't require any
#' tuning parameters and handles both continuous and discrete variables.
#' The downside is that it requires more training to accurately interpret,
#' and the underlying visual tasks are somewhat more challenging.
#'
# @inheritParams layer
# @inheritParams geom_point
#' @param na.rm If `FALSE` (the default), removes missing values with
#'    a warning.  If `TRUE` silently removes missing values.
#' @param n if NULL, do not interpolate. If not NULL, this is the number
#'   of points to interpolate with.
#' @param pad If `TRUE`, pad the ecdf with additional points (-Inf, 0)
#'   and (Inf, 1)
#' @section Computed variables:
#' \describe{
#'   \item{x}{x in data}
#'   \item{y}{cumulative density corresponding x}
#' }
#' @seealso wquantile
#' @export
#' @examples
#' library(ggplot2)
#'
#' n <- 100
#' df <- data.frame(
#'   x = c(rnorm(n, 0, 10), rnorm(n, 0, 10)),
#'   g = gl(2, n),
#'   w = c(rep(1 / n, n), sort(runif(n))^sqrt(n))
#' )
#' ggplot(df, aes(x, weights = w)) +
#'   stat_ewcdf(geom = "step")
#'
#' # Don't go to positive/negative infinity
#' ggplot(df, aes(x, weights = w)) +
#'   stat_ewcdf(geom = "step", pad = FALSE)
#'
#' # Multiple ECDFs
#' ggplot(df, aes(x, colour = g, weights = w)) +
#'   stat_ewcdf()
#' ggplot(df, aes(x, colour = g, weights = w)) +
#'   stat_ewcdf() +
#'   facet_wrap(vars(g), ncol = 1)
stat_ewcdf <- function(mapping = NULL, data = NULL,
                       geom = "step", position = "identity",
                       ...,
                       n = NULL,
                       pad = TRUE,
                       na.rm = FALSE,
                       show.legend = NA,
                       inherit.aes = TRUE) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = StatEwcdf,
    geom = geom,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      n = n,
      pad = pad,
      na.rm = na.rm,
      ...
    )
  )
}


#' @title StatEwcdf ggproto object
#' @name StatEwcdf
#' @rdname StatEwcdf
#' @aliases StatEwcdf
#' @format NULL
#' @usage NULL
#' @export
#' @importFrom ggplot2 aes after_stat has_flipped_aes Stat
NULL

StatEwcdf <- ggplot2::ggproto(
  "StatEwcdf", ggplot2::Stat,
  required_aes = c("x|y", "weights"),
  dropped_aes = c("weights"),
  default_aes = ggplot2::aes(y = ggplot2::after_stat(y)),
  setup_params = function(data, params) {
    params$flipped_aes <-
      ggplot2::has_flipped_aes(data,
        params,
        main_is_orthogonal = FALSE,
        main_is_continuous = TRUE
      )

    has_x <- !(is.null(data$x) && is.null(params$x))
    has_y <- !(is.null(data$y) && is.null(params$y))
    if (!has_x && !has_y) {
      rlang::abort("stat_ewcdf() requires an x or y aesthetic.")
    }
    has_weights <- !(is.null(data$weights) && is.null(params$weights))
    #    if (!has_weights) {
    #      rlang::abort("stat_ewcdf() requires a weights aesthetic.")
    #    }

    params
  },
  compute_group = function(data, scales, n = NULL, pad = TRUE, flipped_aes = FALSE) {
    data <- flip_data(data, flipped_aes)
    # If n is NULL, use raw values; otherwise interpolate
    if (is.null(n)) {
      x <- unique(data$x)
    } else {
      x <- seq(min(data$x), max(data$x), length.out = n)
    }

    if (pad) {
      x <- c(-Inf, x, Inf)
    }
    if (is.null(data$weights)) {
      data_ecdf <- ecdf(data$x)(x)
    } else {
      data_ecdf <-
        spatstat.geom::ewcdf(
          data$x,
          weights = data$weights / sum(abs(data$weights))
        )(x)
    }

    df_ecdf <- vctrs::new_data_frame(list(x = x, y = data_ecdf), n = length(x))
    df_ecdf$flipped_aes <- flipped_aes
    ggplot2::flip_data(df_ecdf, flipped_aes)
  }
)

#' Neg-Log-Likelihood
#'
#' According to the selected model, the negative log-likelihood function is calculated
#'
#' @param beta model parameter
#' @param data data.frame containing CAD_Weight and Actual_Weight
#' @param model model selection, A or B

neg_log_like <- function(beta, data, model) {
  X.vec <- data$CAD_Weight
  Y.vec <- data$Actual_Weight

  if (model == "A") {
    log.dense.vec <- dnorm(Y.vec,
      mean = beta[1] + beta[2] * X.vec,
      sd = sqrt(exp(beta[3] + beta[4] * X.vec)),
      log = TRUE
    )
    return(-sum(log.dense.vec)) # return negative log_likelihood
  } else if (model == "B") {
    log.dense.vec <- dnorm(Y.vec,
      mean = beta[1] + beta[2] * X.vec,
      sd = sqrt(exp(beta[3]) + exp(beta[4]) * X.vec^2),
      log = TRUE
    )
    return(-sum(log.dense.vec)) # return negative log_likelihood
  } else {
    stop("Unknown model. Please specify model A or B.")
  }
}

#' Model parameter estimation
#'
#' According to the selected model,
#' optim() is used to perform convergence calculation from different initial values,
#' and finally the optimal model parameters and corresponding hessian matrix are returned
#'
#' @param data data.frame containing CAD_Weight and Actual_Weight
#' @param model model selection, A or B

filament1_estimate <- function(data, model) {
  if (model == "A") {
    beta0 <- c(-0.1, 1.07, -2, 0.05)
    result <- optim(
      par = beta0,
      fn = neg_log_like,
      data = data,
      model = model,
      hessian = TRUE
    )
    return(list(optimal = result$par, hessian = result$hessian))
    # return model parameters estimation and Hessian matrix at estimators
  } else {
    beta0 <- c(-0.15, 1.07, -13.5, -6.5)
    result <- optim(
      par = beta0,
      fn = neg_log_like,
      data = data,
      model = model,
      hessian = TRUE
    )
    return(list(optimal = result$par, hessian = result$hessian))
    # return model parameters estimation and Hessian matrix at estimators
  }
}

#' Log_prior_density
#'
#' Assuming that the model parameters are also random variables,
#' the prior logarithmic probability density is calculated
#'
#' @param theta model parameters
#' @param params parameters of the prior distribution of theta

log_prior_density <- function(theta, params) {
  log.d1 <- dnorm(theta[1], mean = 0, sd = sqrt(params[1]), log = TRUE)
  log.d2 <- dnorm(theta[2], mean = 1, sd = sqrt(params[2]), log = TRUE)
  log.d3 <- dlogexp(theta[3], rate = params[3], log = TRUE)
  log.d4 <- dlogexp(theta[4], rate = params[4], log = TRUE)
  log.dense.vec <- c(log.d1, log.d2, log.d3, log.d4)
  return(sum(log.dense.vec)) # return log joint density
}

#' Log_likelihood
#'
#' Calculate the log-likelihood function of the model parameters for given samples
#'
#' @param theta model parameters
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter

log_like <- function(theta, x, y) {
  log.dense.vec <- dnorm(y,
    mean = theta[1] + theta[2] * x,
    sd = sqrt(exp(theta[3]) + exp(theta[4]) * (x)^2),
    log = TRUE
  )
  return(sum(log.dense.vec)) # return log-likelihood
}

#' Log_posterior_density
#'
#' Calculate the probability density of the posterior distribution of the model parameters
#'
#' @param theta model parameters
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter
#' @param params parameters of the prior distribution of theta

log_posterior_density <- function(theta, x, y, params) {
  return(log_prior_density(theta = theta, params = params) + log_like(theta = theta, x = x, y = y))
  # return log posterior density
}

#' Approximation of the mean and covariance matrix of a Gaussian distribution
#'
#' optim() is used to calculate the maximum point and hessian matrix
#' of the probability density of the posterior distribution,
#' and returns the inverse of the maximum point and the negative hessian matrix
#'
#' @param theta_start The initial theta of the optim() process
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter
#' @param params parameters of the prior distribution of theta

posterior_mode <- function(theta_start, x, y, params) {
  result <- optim(
    par = theta_start,
    fn = log_posterior_density,
    x = x, y = y, params = params,
    hessian = TRUE,
    control = list(fnscale = -1)
  ) # Do maximisation instead of minimisation
  S <- solve(-result$hessian) # Compute the inverse of a negative hessian matrix
  return(list(mode = result$par, hessian = result$hessian, S = S))
  # return model parameters estimation and Hessian and S matrix at estimators
}

#' Importance Sampling
#'
#' The approximate Gaussian distribution is used to sample,
#' and the weights are set for each sample to better approximate the original distribution
#'
#' @param N number of samples
#' @param mu approximate Gaussian distribution mean
#' @param S covariance matrix of approximate Gaussian distribution
#' @param x x is used to compute the likelihood function as parameter
#' @param y y is used to compute the likelihood function as parameter
#' @param params parameters of the prior distribution of theta

do_importance <- function(N, mu, S, x, y, params) {
  X <- rmvnorm(N, mean = mu, sigma = S)
  log.weights <- numeric(N)
  for (i in 1:N) {
    log.weights[i] <- log_posterior_density(X[i, ], x = x, y = y, params = params) - dmvnorm(X[i, ], mean = mu, sigma = S, log = TRUE)
    # Compute the logarithm of weights
  }
  normalized.log.weights <- log.weights - log_sum_exp(x = log.weights) # Normalization
  return(data.frame(beta1 = X[, 1], beta2 = X[, 2], beta3 = exp(X[, 3]), beta4 = exp(X[, 4]), log_weights = normalized.log.weights))
  # return all samples and corresponding normalized log-weight
}

#' Calculated prediction interval
#'
#' For a given set of weighted samples,
#' the quantile is calculated to construct the prediction interval
#'
#' @param x samples
#' @param weights weight of samples
#' @param prob the probability of the quantile, formatted as c(alpha, 1 - alpha)

make_CI <- function(x, weights, prob) {
  quantiles <- wquantile(x, probs = prob, weights = weights)
  return(data.frame(lower = min(quantiles), upper = max(quantiles)))
  # return prediction interval estimation based on samples with normalized weight
}
>>>>>>> 7dc8da347d623c1e78355b38242813f25bbda514
