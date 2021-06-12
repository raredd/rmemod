.onAttach <- function(libname, pkgname) {
  if (system2('which', 'ruby', stdout = FALSE))
    packageStartupMessage('ruby is required -- please install')
  
  invisible(NULL)
}
