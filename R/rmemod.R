### rmemod
# rmemod, print.rmemod, plot.rmemod
###


#' rmemod
#' 
#' Build a weighted graph using the Winnow algorithm and search for modules
#' that are highly recurrent (across samples) and have high levels of mutual
#' exclusivity. The significance of these patterns is determined using the
#' algorithmic significance test.
#' 
#' The d-score is the algorithmic significance value with significance being
#' equal to \code{2^-d}. Coverage is defined as the percentage of samples that
#' contain at least one aberration within the module. Exclusivity is defined
#' as the percentage of covered samples that contain exactly one aberration
#' within the module.
#' 
#' @param x an \code{n x p} \emph{binary} matrix of \code{n} genes and
#'   \code{p} samples or an object returned by \code{rmemod} for print and
#'   plot methods
#' @param modsize the largest module that the algorithm will attempt to find,
#'   i.e., potential modules will be between 2 and \code{modsize} genes
#'   
#'   warning: the algorithm's complexity grows very quickly as a result of
#'   using combinatorial search, e.g., values over 5 applied to very large
#'   matrices may take a long time
#' @param ngenes an integer representing the total number of genes assayed
#'   which allows for multiple testing correction; include all genes assayed
#'   even if they are not represented in \code{x} (there is little reason to
#'   include genes in the matrix that have no mutations in any sample)
#' @param bgrate the background mutation rate, i.e., the expected odds of a
#'   particular attribute in a particular sample being altered assuming no
#'   selective pressure; the default value (0.01037848) assumes data composed
#'   of copy number and somatic mutation assays and is derived from HapMap
#'   data and estimation of passenger mutation rates in glioblastoma multiforme
#' @param winnow Winnow score threshold; the algorithm speeds up the search
#'   process by excluding poor edges, and this parameter controls the threshold
#'   score for an edge to be kept; due to Winnow's design, these values should
#'   be powers of 2 (4, 8, 16, ...), and if not will be coerced to a power of
#'   2 using \code{2 ^ floor(log2(winnow))} before running algorithm
#'   
#'   suggested values:
#'   
#'     \tabular{llll}{
#'     \tab \code{attributes} \tab \code{samples} \tab \code{winnow} \cr
#'     \tab \code{1k} \tab \code{200} \tab \code{4} \cr
#'     \tab \code{5k} \tab \code{500} \tab \code{32} \cr
#'     \tab \code{18k} \tab \code{500} \tab \code{128} \cr
#'     }
#' @param minfreq minimum frequency of alteration required for a gene to be
#'   included in the search for modules; recommended default is 0.10 as the
#'   false positive rate increases below that point
#' @param threshold the minimum threshold for algorithmic significance value
#'   that a module must exceed; optimal values will depend on input data size
#'   
#'   suggested values:
#'   
#'     \tabular{llll}{
#'     \tab \code{genes} \tab \code{samples} \tab \code{threshold} \cr
#'     \tab \code{1k} \tab \code{200} \tab \code{100} \cr
#'     \tab \code{5k} \tab \code{500} \tab \code{200} \cr
#'     \tab \code{18k} \tab \code{500} \tab \code{300} \cr
#'     }
#' @param verbose logical; if \code{TRUE}, stderr/stdout output will be printed
#' @param outdir optional directory to save output files (i.e., those created
#'   by \code{rmemod} as data frames); otherwise, temporary files are used
#'   and deleted at the end of the current \code{R} session
#' @param timeout timeout in seconds for allowing the algorithm to run; use
#'   0 for no timeout (see \code{\link{system2}}); if the algorithm is still
#'   running after \code{timeout} seconds, the process will be killed and no
#'   results will be returned
#' @param ... additional arguments passed to or from other methods
#' 
#' @importFrom graphics legend par text
#' @importFrom stats quantile setNames
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
#' @return
#' A list of class \code{"rmemode"} with the following elements:
#' 
#' \item{\code{potential}}{a data frame of the complete list of all potential
#'   modules and the d-score for each}
#' \item{\code{top}}{a data frame of the largest and most significant non
#'   overlapping modules which have d-score of at least \code{threshold};
#'   coverage, exclusivity, and p-value are also included; see details}
#' \item{\code{call}}{the call used to invoke the algorithm with options}
#' \item{\code{sys}}{the return value of \code{\link{system2}}, potentially
#'   warnings or errors, stdout/stderr if \code{verbose = TRUE}, or \code{0}
#'   otherwise upon successful completion of the algorithm}
#' 
#' @examples
#' ## basic usage
#' set.seed(1)
#' x <- matrix(rbinom(1000 * 50, 1, 0.1), 100)
#' r <- rmemod(x)
#' r
#' plot(r)
#' 
#' 
#' ## miller, 2011
#' f <- system.file(
#'   'etc', 'rmeMod', 'exampleFiles', 'input.dat',
#'   package = 'rmemod'
#' )
#' x <- as.matrix(read.table(f))
#' r <- rmemod(x, 3, threshold = 200)
#' r
#' 
#' ## potential modules
#' head(r$pot)
#' ## significance
#' head(2 ^ -r$pot$d)
#' 
#' r <- rmemod(x, 3, threshold = 50)
#' plot(r)
#' 
#' @export

rmemod <- function(x, modsize = 2L, ngenes = nrow(x), bgrate = 0.01037848,
                   winnow = 4, minfreq = 0.1, threshold = 50,
                   verbose = FALSE, outdir = NULL, timeout = 30) {
  x <- as.matrix(x)
  if (is.null(colnames(x)))
    colnames(x) <- sprintf('sample%s', seq.int(ncol(x)))
  if (is.null(rownames(x)))
    rownames(x) <- sprintf('gene%s', seq.int(nrow(x)))
  
  winnow <- 2 ^ floor(log2(winnow))
  
  outdir <- if (!is.null(outdir)) {
    dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
    outdir
  } else tempdir()
  input <- tempfile('input-', outdir)
  
  output1 <- tempfile('potentialModules-', outdir)
  output2 <- tempfile('topModules-', outdir)
  
  stopifnot(
    all(c(x) %in% 0:1),
    ngenes >= nrow(x),
    # modsize <= 5,
    minfreq >= 0, minfreq < 1,
    bgrate >= 0, bgrate < 1,
    timeout >= 0
  )
  
  if (modsize > 5)
    warning(
      'complexity may be high and take some time - ',
      'may need to increase value of \'timeout\' arg'
    )
  
  colnames(x)[1L] <- sprintf('\t%s', colnames(x)[1L])
  write.table(x, file = input, quote = FALSE, sep = '\t')
  
  path <- system.file('scripts', 'run.sh', package = 'rmemod')
  args <- list(
    s = modsize, i = input, g = ngenes,
    o = basename(output1), p = basename(output2), d = outdir,
    b = bgrate, w = winnow, m = minfreq, t = threshold
  )
  
  call <- paste(sprintf('-%s %s', names(args), args), collapse = ' ')
  verb <- if (verbose)
    '' else TRUE
  
  sys <- tryCatch(
    system2(path, call, stdout = verb, stderr = verb, timeout = timeout),
    error = function(e) e$message,
    warning = function(w) w$message
  )
  
  if (any(grepl('timed out after', sys)))
    message(sys)
  
  null <- data.frame(
    d = NA_real_, coverage = NA_real_,
    exclusivity = NA_real_, module = NA_character_
  )
  
  ## potential modules
  pmod <- tryCatch(
    setNames(read.table(output1, header = FALSE), names(null)[-(2:3)]),
    warning = function(w) null[0L, -(2:3)], error = function(e) null[0L, ]
  )
  
  ## top modules
  tmod <- tryCatch({
    tmod <- read.table(output2, header = FALSE)
    names(tmod) <- c('d', 'coverage', 'exclusivity', 'module')
    tmod$p.value <- 2 ^ -tmod$d
    tmod
  }, warning = function(w) null[0L, ], error = function(e) null[0L, ])
  
  structure(
    list(potential = pmod, top = tmod, call = paste(path, call), sys = sys),
    class = 'rmemod'
  )
}

#' @rdname rmemod
#' @export
print.rmemod <- function(x, ...) {
  print(x$top)
  invisible(x)
}

#' @rdname rmemod
#' @export
plot.rmemod <- function(x, ...) {
  if (nrow(x$top) <= 2L) {
    message('not enough modules to plot')
    print(x$top)
    return(invisible(x))
  }
  
  rescaler <- function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
    (x - from[1L]) / diff(from) * diff(to) + to[1L]
  }
  
  op <- par(las = 1L, mar = c(5, 5, 5, 2) + 0.1, xpd = NA, bty = 'l')
  on.exit(par(op))
  
  plot(
    x$top$coverage, x$top$exclusivity, ...,
    cex = rescaler(-log10(x$top$p.value), c(1, 3)),
    xlab = 'coverage', ylab = 'exclusivity',
  )
  text(x$top$coverage, x$top$exclusivity, x$top$module, pos = 3L, cex = 0.75)
  leg <- quantile(x$top$p.value, c(1, 0.5, 0))
  legend(
    'top', title = expression(p-value~(2^-d)), bty = 'n', col = 1L, pch = 1L,
    xpd = NA, inset = c(0, -0.15), horiz = TRUE,
    legend = format(leg, digits = 3L), pt.cex = rescaler(leg, c(3, 1))
  )
  
  invisible(x)
}
