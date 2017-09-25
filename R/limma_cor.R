#'Test correlation of each row of object to phenotype using moderated variance
#'
#'Test correlation of each row of object to phenotype using 
#'\code{design=model.matrix(~1+phenotype)}, testing 2nd coefficient.
#'
#'@param object A matrix-like data object containing log-ratios or 
#'  log-expression values for a series of arrays, with rows corresponding to 
#'  genes and columns to samples.
#'@param phenotype Vector of phenotypes of the samples. Should be same length as
#'  \code{ncol(object)}. If the vector is named, names should match 
#'  \code{colnames(object)}.
#'@param design the design matrix of the experiment, with rows corresponding to 
#'  arrays and columns to coefficients to be estimated. Can be used to provide 
#'  covariates.
#'@param prefix character string to add to beginning of column names.
#'@param weights non-negative observation weights. Can be a numeric matrix of 
#'  individual weights, of same size as the object expression matrix, or a 
#'  numeric vector of array weights with length equal to \code{ncol} of the 
#'  expression matrix, or a numeric vector of gene weights with length equal to 
#'  \code{nrow} of the expression matrix.
#'@param trend logical, should an intensity-trend be allowed for the prior 
#'  variance? Default is that the prior variance is constant.
#'@param adjust.method method used to adjust the p-values for multiple testing.
#'@param cols columns of \code{topTable} output the user would like in the 
#'  result. Some column names, such as \code{adj.P.Val} are changed. If \code{logFC}
#'  is specified, \code{FC} will also be given.
#'@param reorder.rows logical, should rows be reordered by F-statistic from 
#'  \code{\link[limma]{topTableF}} or be left in the same order as 
#'  \code{object}? Default is to reorder.
#'@return Dataframe.
#'@details If \code{design} is \code{NULL} and \code{phenotype} is given, design
#'  will be calculated as \code{model.matrix(~0+phenotype)}. However, 
#'  \code{phenotype} isn't needed if \code{design} is provided. See further 
#'  details in \code{\link[limma]{lmFit}}.
#'@seealso \code{\link[limma]{lmFit}} and \code{\link[limma]{eBayes}}.
#'@export

limma_cor <- function(object, phenotype=NULL, design=NULL, prefix='', weights=NULL, 
                      trend=FALSE, adjust.method='BH', 
                      cols=c('AveExpr', 'P.Value', 'adj.P.Val', 'logFC'), 
                      reorder.rows=TRUE){
   stopifnot(dim(weights)==dim(object)|length(weights)==nrow(object)|
               length(weights)==ncol(object))
  
  if (!is.null(phenotype)){
    stopifnot(length(phenotype)==ncol(object), is.numeric(phenotype), 
              names(phenotype)==colnames(object))
    #model.matrix clips NAs in phenotype, so need to also remove from mat
    n.na <- sum(is.na(phenotype))
    if (is.null(design)){
      #model.matrix clips NAs in pheno, so need to also remove from mat
      n.na <- sum(is.na(phenotype))
      if (n.na>0){
        message(n.na, 'NAs in phenotype removed')
        pheno.nona <- phenotype[!is.na(phenotype)]
        object <- object[,!is.na(phenotype)]
        if (!is.null(weights)){ 
          if (length(weights)==ncol(object)){ weights <- weights[!is.na(phenotype)] }
          if (dim(weights)[2]==ncol(object)){ weights <- weights[,!is.na(phenotype)] }
        }
      } else {
        pheno.nona <- phenotype
      }
      design <- model.matrix(~1+pheno.nona) 
    }
  }#end if !is.null(pheno)
  
  stopifnot(colnames(design)[1] == '(Intercept)' & is.numeric(design[,2]))
  
  if (!missing(weights)){
    if (!is.matrix(object) && !is.null(object$weights)){ warning('object$weights are being ignored') }
    fit <- lmFit(object, design, weights=weights)
  } else {
    fit <- lmFit(object, design)
  }
  fit2 <- eBayes(fit, trend=trend)
  res.mat <- eztoptab(fit2, coef=2, cols=cols, adjust.method=adjust.method)
  
  #change logFC to coeff and get rid of FC
  colnames(res.mat) <- gsub('logFC', 'slope', colnames(res.mat))
  res.mat <- res.mat[,setdiff(colnames(res.mat), 'FC')]
  
  if (!reorder.rows){ res.mat <- res.mat[rownames(object),] }
  if (prefix!=''){ colnames(res.mat) <- paste(prefix, colnames(res.mat), sep='.') }
  return(res.mat)
}