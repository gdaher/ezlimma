#' Wrapper for limma topTable function
#' 
#' Wrapper for limma topTable function that subsets and changes colnames
#' 
#' @param fit should be an object of class \code{MArrayLM} as produced by 
#' \code{lmFit} and \code{eBayes}.
#' @param cols columns of \code{topTable} output the user would like in the 
#' output, although the names are changed. If \code{logFC} is specified, 
#' \code{FC} will also be given.
#' @param adjust.method method used to adjust the p-values for multiple testing.
#' @param prefix character string to add to beginning of column names.
#' @param coef column number or column name specifying which coefficient or 
#' contrast of the linear model is of interest.
#' @details See \code{\link{[limma]{topTable}}} for more details on many of 
#' these, as this fuction is a wrapper for that one.
#' @return Dataframe.

#sort by p
#assume that if 'logFC' in cols, then want 'FC'
eztoptab <- function(fit, cols=c('P.Value', 'adj.P.Val', 'logFC'), adjust.method='BH', 
                     prefix='', coef=NULL){
  stopifnot(cols %in% 
            c('CI.L', 'CI.R', 'AveExpr',  't', 'F', 'P.Value', 'adj.P.Val', 'B', 'logFC'))
  
  tt <- topTable(fit, number=Inf, sort.by='P', adjust.method=adjust.method, coef=coef)
  #FC
  if ('logFC' %in% cols){
    tt$FC <- logfc2fc(tt$logFC)
    cols <- c(cols, 'FC')
  }    
  tt <- tt[,cols]
  colnames(tt) <- sub('P.Value', 'p', colnames(tt))
  #p.adjust says fdr is alias for BH
  if (adjust.method %in% c('BH', 'fdr')){
    colnames(tt) <- sub('adj\\.P\\.Val', 'FDR', colnames(tt))
  } else {
    colnames(tt) <- sub('adj\\.P\\.Val', adjust.method, colnames(tt))
  } 
  if (prefix!=''){ colnames(tt) <- paste(prefix, colnames(tt), sep='.') }
  return(tt)
}