#' Apply lmFit, contrasts.fit, & eBayes to one or more contrasts
#' 
#' Apply lmFit, contrasts.fit, & eBayes to one or more contrasts by passing each 
#' object row, phenotype groups, and contrasts to only this function.
#' 
#' @param object A matrix-like data object containing log-ratios or 
#'   log-expression values for a series of arrays, with rows corresponding to 
#'   genes and columns to samples. Must have non-duplicated, non-empty rownames.
#' @param grp Vector of phenotype groups of the samples, which represent valid 
#'   variable names in R. Should be same length as \code{ncol(object)}. If the 
#'   vector is named, names should match \code{colnames(object)}.
#' @param contrast.v A named vector of contrasts for \code{\link[limma]{makeContrasts}}.
#' @param design the design matrix of the microarray experiment, with rows 
#'   corresponding to arrays and columns to coefficients to be estimated.
#' @param weights non-negative observation weights. Can be a numeric matrix of 
#'   individual weights, of same size as the object expression matrix, or a 
#'   numeric vector of array weights with length equal to \code{ncol} of the 
#'   expression matrix, or a numeric vector of gene weights with length equal to
#'   \code{nrow} of the expression matrix.
#' @param trend logical, should an intensity-trend be allowed for the prior 
#'   variance? Default is that the prior variance is constant.
#' @param block vector or factor specifying a blocking variable on the arrays. 
#'   Has length equal to the number of arrays.
#' @param correlation the inter-duplicate or inter-technical replicate 
#'   correlation.
#' @param adjust.method method used to adjust the p-values for multiple testing.
#' @param add.means logical indicating if (unweighted) group means per row
#'   should be added to the output.
#' @param treat.lfc Vector of logFC passed to \code{\link[limma]{treat}} \code{lfc}. It is recycled as needed to match
#'  rows of \code{object}. If given, \code{length(contrast.v)} must be 1. McCarthy & Smyth suggest a 10% fold-change,
#'  which is \code{treat.lfc=log2(1.1)}.
#' @param cols columns of \code{topTable} the user would like in the 
#'   output. Possibilities include \code{'logFC', 'AveExpr', 't', 'P.Value', 'adj.P.Val', 'B'}. 
#'   Once selected, the column names of the output may be different than \code{cols}.
#'   If \code{logFC} is specified, \code{FC} will automatically also be given.
#' @return Data frame.
#' @details If \code{design} is \code{NULL} and \code{grp} is given, design will be calculated as 
#' \code{model.matrix(~0+grp)}. However, \code{grp} isn't needed if \code{design} is provided & \code{add.means} 
#' is \code{FALSE}. See further details in \code{\link[limma]{lmFit}}.
#' @references McCarthy DJ & Smyth GK (2009). Testing significance relative to a fold-change threshold is a TREAT. 
#' Bioinformatics 25, 765-771.
#' @seealso \code{\link[ezlimma]{limma_cor}}, \code{\link[limma]{lmFit}} and \code{\link[limma]{eBayes}}.
#' @export

#don't include parameters for robust fitting, since ppl unlikely to use
limma_contrasts <- function(object, grp=NULL, contrast.v, design=NULL, weights=NULL,
                            trend=FALSE, block=NULL, correlation=NULL, adjust.method='BH', 
                            add.means=TRUE, treat.lfc=NULL, cols=c('P.Value', 'adj.P.Val', 'logFC')){
  
  stopifnot(is.null(treat.lfc) || length(contrast.v)==1)
  if (is.null(design)|add.means) stopifnot(ncol(object)==length(grp), colnames(object)==names(grp))
  if (any(duplicated(rownames(object)))) stop("object cannot have duplicated rownames.")
  if (any(rownames(object)=="")) stop("object cannot have an empty rowname ''.")

  if (is.null(design)){
    design <- stats::model.matrix(~0+grp)
    colnames(design) <- sub('grp', '', colnames(design), fixed=TRUE)
  }
  
  #can't set weights=NULL in lmFit when using voom, since lmFit only assigns
  #weights "if (missing(weights) && !is.null(y$weights))"
  #can't make this into separate function, since then !missing(weights)
  if (!missing(weights)){
    if (!is.matrix(object) && !is.null(object$weights)){ warning('object$weights are being ignored') }
    fit <- limma::lmFit(object, design, block = block, correlation = correlation, weights=weights)
  } else {
    fit <- limma::lmFit(object, design, block = block, correlation = correlation)
  }
  
  contr.mat <- limma::makeContrasts(contrasts=contrast.v, levels=design)
  fit2 <- limma::contrasts.fit(fit, contr.mat)
  if (is.null(treat.lfc)){
    fit2 <- limma::eBayes(fit2, trend=trend)
  } else {
    fit2 <- limma::treat(fit2, lfc=treat.lfc, trend=trend)
  }
  #limma ignores names of contrast.v when it's given as vector
  if (!is.null(names(contrast.v))){
    stopifnot(colnames(fit2$contrasts)==contrast.v)
    colnames(fit2$contrasts) <- names(contrast.v)
  }
  
  mtt <- multiTopTab(fit2, cols=cols, adjust.method=adjust.method)
  
  #cbind grp means
  if (add.means){
    grp.means <- t(apply(object, MARGIN=1, FUN=function(v) tapply(v, INDEX=grp, FUN=mean, na.rm=TRUE)))
    colnames(grp.means) <- paste(colnames(grp.means), 'avg', sep='.')
    mtt <- cbind(grp.means[rownames(mtt),], mtt)
  }
  return(mtt)
}