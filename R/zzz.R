.onAttach <- function(libname, pkgname) {
  if (system('which bash', intern = TRUE) == '')
    packageStartupMessage('bash is required -- please install')
  
  if (system('which ruby', intern = TRUE) == '')
    packageStartupMessage('ruby is required -- please install')
  
  invisible(NULL)
}
