#'Test correlation of each row of an object to each column of pheno.mat
#'
#'Test correlation of each row of an object to each column of pheno.mat using 
#'one of Pearson's, Kendall's, or Spearman's correlation methods, or limma 
#'regression in \code{\link{limma.cor}}.
#'
#'@param object A matrix-like data object containing log-ratios or 
#'  log-expression values, with rows corresponding to features (eg genes) and 
#'  columns to samples.
#'@param pheno.mat matrix of phenotypes of the samples, with each column one 
#'  phenotype vector. Length and names of rows of \code{pheno.mat} should 
#'  correspond to columns of \code{object}.
#'@param method a character string indicating which association is to be used 
#'  for the test. One of \code{"pearson"}, \code{"spearman"}, \code{"kendall"}, 
#'  from \code{\link[stats]{cor.test}} or \code{"limma"} for 
#'  \code{\link{limma.cor}}.
#'@param reorder.rows logical, should rows be reordered by F-statistic from 
#'  \code{\link[limma]{topTableF}} or be left in the same order as 
#'  \code{object}? Default is to reorder.
#'@param prefix character string to add to beginning of column names.
#'@param adjust.method method used to adjust the p-values for multiple testing.
#'@param limma.cols if \code{method="limma"}, this specifies \code{cols} from 
#'  \code{\link{limma.cor}}. Ignored without a warning if \code{method} not 
#'  \code{"limma"}.
#'@return Dataframe with several statistical columns corresponding to each
#'  phenotype and one row per feature.
#'@export


multi_cor <- function(object, pheno.mat, method=c('pearson', 'spearman', 'kendall', 'limma'),
                     reorder.rows=TRUE, prefix='', adjust.method='BH', 
                     limma.cols=c('AveExpr', 'P.Value', 'adj.P.Val', 'logFC')){
  method <- match.arg(method)
  stopifnot(ncol(object)==nrow(pheno.mat), rownames(pheno.mat)==colnames(object))
  cor.mat <- NULL
  for (i in 1:ncol(pheno.mat)){
    prefix.tmp <- ifelse(prefix!='', paste(prefix, colnames(pheno.mat)[i], sep='.'), colnames(pheno.mat)[i])
    if (method=='limma'){
      cor.tmp <- data.matrix(limma.cor(object, pheno.mat[,i], reorder=FALSE, prefix=prefix.tmp, cols=limma.cols))
    } else {
      cor.tmp <- ezcor(object, pheno.mat[,i], method=method, reorder=FALSE, prefix=prefix.tmp, adjust.method=adjust.method)
    }
    if (!is.null(cor.mat)){ stopifnot(rownames(cor.mat)==rownames(cor.tmp)) }
    cor.mat <- cbind(cor.mat, cor.tmp)
  }
  if (reorder.rows){ cor.mat <- cor.mat[order(combine.pvalues(cor.mat)),] }
  return(cor.mat)
}