% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/combine_pvalues.R
\name{combine_pvalues}
\alias{combine_pvalues}
\title{Combine p-values of a feature over multiple p-value columns of an object}
\usage{
combine_pvalues(mat, pv.cols = NULL)
}
\arguments{
\item{mat}{A matrix-like object with statistical columns, including some
containing p-values. Must have \code{nrow(mat)>1} & \code{ncol(mat)>1}.}

\item{pv.cols}{the column names or column indices with p-values. If
\code{NULL}, the function searches for columns that end with \code{.p} or \code{.pval}.}
}
\value{
A vector of p-values.
}
\description{
Combine p-values of a feature over multiple p-value columns of an object
}
\details{
This function uses the z-transform method to combine p-values across rows, equivalently to using unweighted 
\code{method="z.transform"} in \code{survcomp::combine.test}.
}
\examples{
 tab <- data.frame(foo.p=(1:9)/9, bar.p=(9:1)/9)
 combine_pvalues(tab)
}
