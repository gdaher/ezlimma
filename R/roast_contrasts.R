#' Test contrasts of gene sets between groups using rotation testing with output
#' to Excel
#'
#' Test contrasts of gene sets using \code{\link[limma]{roast}} with functions
#' \code{mroast} or \code{fry}. It returns a data frame with statistics per gene set, 
#' and writes this to an Excel file. The Excel file links to CSV files, which contain 
#' statistics per gene set. Some of the arguments only apply to \code{mroast}.
#' 
#' @param object A matrix-like data object containing log-ratios or
#'  log-expression values for a series of arrays, with rows corresponding to
#'  genes and columns to samples.
#' @param G a gene set list as returned from \code{\link{read_gmt}}.
#' @param stats.tab a table of feature (e.g. gene) statistics that the Excel
#'  table can link to.
#' @param grp Vector of phenotype groups of the samples, which represent valid
#'   variable names in R. Should be same length as \code{ncol(object)}. If the
#'   vector is named, names should match \code{colnames(object)}.
#' @param contrast.v A named vector of contrasts for
#'   \code{\link[limma]{makeContrasts}}.
#' @param design the design matrix of the experiment, with rows corresponding to
#'  arrays and columns to coefficients to be estimated.
#' @param fun function to use, either \code{fry} or \code{mroast}.
#' @param set.statistic summary set statistic. Possibilities are \code{"mean"},
#'  \code{"floormean"}, \code{"mean50"}, or \code{"msq"}. Only for \code{mroast}.
#' @param name a name for the folder and Excel file that get written. Set to \code{NA} to avoid writing output.
#' @param weights non-negative precision weights passed to \code{lmFit}. Can be
#'  a numeric matrix of individual weights of same size as \code{object} or a numeric 
#'  vector of array weights with length equal to \code{ncol(object)}, or a numeric vector 
#'  of gene weights with length equal to \code{nrow(object)}.
#' @param gene.weights numeric vector of directional (positive or negative) genewise weights. These represent
#'  each gene's contribution to pathways. They are not for precision weights, from \code{weights}. This 
#'  vector must have length equal to \code{nrow(object)}. Only for \code{mroast}.
#' @param trend logical, should an intensity-trend be allowed for the prior
#'  variance? Default is that the prior variance is constant.
#' @param block vector or factor specifying a blocking variable on the arrays.
#'  Has length equal to the number of arrays.
#' @param correlation the inter-duplicate or inter-technical replicate
#'  correlation.
#' @param adjust.method method used to adjust the p-values for multiple testing.
#' Only for \code{mroast}.
#' @param min.ngenes minimum number of genes needed in a gene set for testing.
#' @param max.ngenes maximum number of genes needed in a gene set for testing.
#' @param nrot number of rotations used to estimate the p-values for \code{mroast}.
#' @param alternative indicates the alternative hypothesis and must be one of
#'  \code{"two.sided"}, \code{"greater"} or \code{"less"}. \code{"greater"}
#'  corresponds to positive association, \code{"less"} to negative association.
#' @param n.toptabs number of gene set toptables to write to CSV and link to from
#'  Excel
#' @return data frame of gene set statistics.
#' @details Pathway names are altered to be valid filenames in Windows and Linux.
#' @export

#limma 3.34.6 fixed array weights bug, but I don't require this version of limma, since don't have it on server
roast_contrasts <- function(object, G, stats.tab, grp=NULL, contrast.v, design=NULL,
                          fun=c("fry", "mroast"), set.statistic = 'mean', name=NA,
                          weights = NULL, gene.weights = NULL, trend = FALSE, block = NULL,
                          correlation = NULL, adjust.method = 'BH', min.ngenes=3, max.ngenes=1000,
                          nrot=999, alternative=c("two.sided", "less", "greater"), n.toptabs = Inf){

  stopifnot(rownames(object) %in% rownames(stats.tab), !is.null(design)|!is.null(grp),
            is.null(gene.weights)|length(gene.weights)==nrow(object))
  #only mroast takes some arguments
  if (fun=="fry" && (!is.null(gene.weights)||adjust.method!="BH")){
    warning("fry method does not take arguments: gene.weights or adjust.method. These arguments will be ignored.")
  }

  if (!is.null(grp)){
    stopifnot(length(grp)==ncol(object), names(grp)==colnames(object))
  }
  fun <- match.arg(fun)
  alternative <- match.arg(alternative)

  ##get G index
  index <- g_index(G=G, object=object, min.ngenes=min.ngenes, max.ngenes=max.ngenes)

  if (is.null(design)){
      stopifnot(ncol(object) == length(grp), colnames(object) == names(grp))
      design <- stats::model.matrix(~0+grp)
      colnames(design) <- sub('grp', '', colnames(design), fixed=TRUE)
  }

  contr.mat <- limma::makeContrasts(contrasts = contrast.v, levels = design)
  
  #deal with weights
  if (!is.matrix(object)){
      if (!is.null(object$weights)){
          if (!is.null(weights)){
              warning('object$weights are being ignored')
          } else {
              if (is.null(dimnames(object$weights))) dimnames(object$weights) <- dimnames(object)
              weights <- object$weights
          }
      }
  }#end if(!is.matrix(object))

  ##run fry or mroast for each contrast
  #block & correlation from lmFit, trend from eBayes
  for (i in seq_along(contrast.v)){
    if (fun=="fry"){
      res.tmp <- limma::fry(y = object, index = index, design = design, contrast = contr.mat[, i], weights = weights, 
                     block=block, correlation=correlation, trend=trend)
    } else {
      res.tmp <- limma::mroast(y = object, index = index, design = design, contrast = contr.mat[, i],
                     weights = weights, gene.weights = gene.weights, trend = trend,
                     block = block, correlation = correlation, adjust.method = adjust.method,
                     set.statistic = set.statistic, nrot=nrot)
    }
    #need to coerce "direction" from factor to char
    res.tmp$Direction <- as.character(res.tmp$Direction)
    
    #if want one-sided test, change p-values, calc new FDRs, then remove Mixed columns
    if (alternative!="two.sided"){
      res.tmp <- roast_one_tailed(roast.res=res.tmp, fun=fun, alternative=alternative, 
                                  nrot=nrot, adjust.method=adjust.method)
    }#end if one.tailed
    colnames(res.tmp) <- gsub("PValue", "p", gsub("FDR.Mixed", "Mixed.FDR", 
                                                  gsub("PValue.Mixed", "Mixed.p", colnames(res.tmp))))
    #add contrast names to each column except 1st, which is NGenes
    colnames(res.tmp)[-1] <- paste(names(contrast.v[i]), colnames(res.tmp)[-1], sep = '.')
    if (i == 1){
        res <- res.tmp
    } else {
        res <- cbind(res, res.tmp[rownames(res), -1])
    }
  }#end for i
  #let combine_pvalues find pvalue columns
  res <- res[order(combine_pvalues(res)), ]

  #change FDR to appropriate adjustment name if user doesn't use FDR
  if (!(adjust.method %in% c("BH", "fdr"))){
    colnames(res) <- gsub("FDR$", adjust.method, colnames(res))
  }

  #write xlsx file with links
  if (!is.na(name)){
    write_linked_xlsx(name=name, fun=fun, res=res, index=index, stats.tab=stats.tab, n.toptabs=n.toptabs)
  }#end if !is.na(name)
  return(res)
}#end fcn