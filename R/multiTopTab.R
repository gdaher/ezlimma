#' Combine one or more toptables extracted from linear model fit
#' 
#' Combine one or more toptables extracted from \code{fit}.
#' 
#' @param fit should be an object of class \code{MArrayLM} as produced by 
#' \code{lmFit} and \code{eBayes}.
#' @param cols columns of \code{topTable} output the user would like in the 
#' output, although the names are changed. If \code{logFC} is specified, 
#' \code{FC} will also be given.
#' @param adjust.method method used to adjust the p-values for multiple testing.
#' @details This function calls \code{\link{eztoptab}}. See also 
#' \code{\link[limma]{toptable}} for more details on many of these, as this 
#' fuction is a wrapper for that one.
#' @return Dataframe
#' @details This function is not meant to be called directly by the user.

#not exported
multiTopTab <- function(fit, cols=c('P.Value', 'adj.P.Val', 'logFC'), adjust.method='BH'){
  #remove spaces in names of contrasts to be valid R colnames
  contrasts <- gsub(' ', '', colnames(fit$contrasts))
  #get gene order
  #limma 3.16 has row.names=row number & 'ID' column; limma 3.18 has row.names=ID
  #fit doesn't have F-stat if using limma::treat()
  if (!is.null(fit$F)){
    ttf <- limma::topTableF(fit, number=Inf)
  } else {
    ttf <- limma::topTable(fit, coef=1, number=Inf, sort.by="p")
  }
  genes <- rownames(ttf)
	#go thru contrasts
	for (i in 1:length(contrasts)){
	  mtt.tmp <- eztoptab(fit, coef=i, cols=cols, adjust.method=adjust.method)
	  #this line alters "" rowname to "NA"
	  mtt.tmp <- mtt.tmp[genes,, drop=FALSE]
	  colnames(mtt.tmp) <- paste(contrasts[i], colnames(mtt.tmp), sep='.')
    if (i==1){
      mtt <- mtt.tmp
    } else {
      mtt <- cbind(mtt, mtt.tmp)
    }
	}
	return(mtt)
}