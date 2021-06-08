#' rmemod
#' 
#' Discovering functional modules by identifying recurrent and mutually
#' exclusive mutational patterns in tumors.
#' 
#' Assays of multiple tumor samples frequently reveal recurrent genomic
#' aberrations, including point mutations and copy-number alterations, that
#' affect individual genes. Analyses that extend beyond single genes are often
#' restricted to examining pathways, interactions, and functional modules that
#' are already known.
#' 
#' \code{rmemod} is a method that identifies functional modules without any
#' information other than patterns of recurrent and mutually exclusive
#' aberrations (RME patterns) that arise due to positive selection for key
#' cancer phenotypes. 
#' 
#' This algorithm efficiently constructs and searches networks of potential
#' interactions and identifies significant modules (RME modules) by using the
#' algorithmic significance test.
#' 
#' @seealso
#' \url{http://brl.bcm.tmc.edu/rme/index.rhtml}
#' 
#' \url{https://bmcmedgenomics.biomedcentral.com/articles/10.1186/1755-8794-4-34}
#' 
#' @references
#' Miller CA, SH Settle, EP Sulman, KD Aldape, A Milosavljevic. Discovering
#' functional modules relevant for cancer progression by identifying patterns
#' of recurrent and mutually exclusive aberrations in tumor samples.
#' \emph{BMC Medical Genomics} 2011, \strong{4}:34.
#' 
#' @name rmemod-package
#' @docType package
#' @import utils
NULL
