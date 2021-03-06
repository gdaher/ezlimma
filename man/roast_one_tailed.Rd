% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/roast_one_tailed.R
\name{roast_one_tailed}
\alias{roast_one_tailed}
\title{Convert roast two-tailed results to one-tailed}
\usage{
roast_one_tailed(roast.res, fun, alternative, nrot, adjust.method)
}
\arguments{
\item{roast.res}{Result from \code{mroast} or \code{fry}.}

\item{fun}{function to use, either \code{fry} or \code{mroast}.}

\item{alternative}{indicates the alternative hypothesis and must be one of
\code{"two.sided"}, \code{"greater"} or \code{"less"}. \code{"greater"}
corresponds to positive association, \code{"less"} to negative association.}

\item{nrot}{number of rotations used to estimate the p-values for \code{mroast}.}

\item{adjust.method}{method used to adjust the p-values for multiple testing.
Only for \code{mroast}.}
}
\value{
Modified result from \code{mroast} or \code{fry}.
}
\description{
Convert \code{mroast} or \code{fry} two-tailed results to one-tailed and remove 
non-directional, termed "Mixed", statistics.
}
\details{
This function is not meant to be called directly by the user.
}
