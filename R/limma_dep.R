#' Test (conditional) dependence of two variables
#'
#' Test (conditional) dependence of \code{y} with rows of \code{object}.
#' @param object A matrix-like data object with rows corresponding to features and columns to samples.
#' @param y A vector. If not numeric, treated as a nominal group variable. To ensure that \code{object} matches \code{y},
#' it is checked that \code{colnames(object)==names(y)}. This check will pass if one of these is \code{NULL}.
#' @param covar A matrix-like data object with rows corresponding to samples and columns to covariates. If \code{covar}
#' has rownames, they should match \code{names(y)}.
#' @param prefix Character string to add to beginning of column names.
#' @param verbose If \code{TRUE} reports messages.
#' @return Dataframe with \code{t-statistic} or \code{F-statistic} and \code{p-value} per row of \code{object}.

#transform to |z-score| using sqrt of chisq w/ df=1
limma_dep <- function(object, y, covar=NULL, prefix="", verbose=FALSE){
  stopifnot(is.vector(y), ncol(object)==length(y), colnames(object)==names(y),
            !is.null(covar)||all(nrow(covar)==length(y), rownames(covar)==names(y)))
  p.col <- "p"
  if (is.numeric(y)){
    if (verbose) message("y treated as continuous numeric vector")
    if (is.null(covar)){
      tt <- limma_cor(object=object, phenotype = y, cols=c('t', 'P.Value'))
    } else {
      dat <- data.frame(y, covar)
      design <- model.matrix(~., data=dat)
      tt <- limma_cor(object = object, design = design, cols=c('t', 'P.Value'))
    }
  } else {
    if (verbose) message("y treated as an unordered factor")
    ngrps <- length(unique(y))
    if (ngrps==1){
      stop("'y' is not numeric and has only one group, but needs more.")
    } else {
      if (!is.null(covar)){
        design <- model.matrix(~y+covar)
        covar.ncol <- ncol(as.matrix(covar))
        coef <- 2:(ncol(design)-covar.ncol)
      } else {
        design <- model.matrix(~y)
        coef <- 2:ncol(design)
      }

      if (length(coef)==1){
        tt <- limmaF(object, design = design, coef=coef, cols=c('t', 'P.Value'))
      } else {
        tt <- limmaF(object, design = design, coef=coef, cols=c('F', 'P.Value'))
      }
    }#end else ngrps>1
  }#end else not numeric
  if (prefix!=''){ colnames(tt) <- paste(prefix, colnames(tt), sep='.') }
  return(tt)
}