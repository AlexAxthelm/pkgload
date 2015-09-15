#' Coerce input to a package.
#'
#' Possible specifications of package:
#' \itemize{
#'   \item path
#'   \item package object
#' }
#' @param x object to coerce to a package
#' @param create only relevant if a package structure does not exist yet: if
#'   \code{TRUE}, create a package structure; if \code{NA}, ask the user
#'   (in interactive mode only)
#' @export
#' @keywords internal
as.package <- function(x = NULL, create = NA) {
  if (is.package(x)) return(x)

  x <- check_dir(x)
  load_pkg_description(x, create = create)
}


check_dir <- function(x) {
  if (is.null(x)) {
    stop("Path is null", call. = FALSE)
  }

  # Normalise path and strip trailing slashes
  x <- normalise_path(x)
  x <- package_root(x) %||% x

  if (!file.exists(x)) {
    stop("Can't find directory ", x, call. = FALSE)
  }
  if (!file.info(x)$isdir) {
    stop(x, " is not a directory", call. = FALSE)
  }

  x
}

package_root <- function(path) {
  if (is.package(path)) {
    return(path$path)
  }
  stopifnot(is.character(path))

  has_description <- function(path) {
    file.exists(file.path(path, 'DESCRIPTION'))
  }
  path <- normalizePath(path, mustWork = FALSE)
  while (!has_description(path) && !is_root(path)) {
    path <- dirname(path)
  }

  if (is_root(path)) {
    NULL
  } else {
    path
  }
}

is_root <- function(path) {
  identical(path, dirname(path))
}

normalise_path <- function(x) {
  x <- sub("\\\\+$", "/", x)
  x <- sub("/*$", "", x)
  x
}

# Load package DESCRIPTION into convenient form.
load_pkg_description <- function(path, create) {
  path <- normalizePath(path)
  path_desc <- file.path(path, "DESCRIPTION")

  if (!file.exists(path_desc)) {
    if (is.na(create)) {
      if (interactive()) {
        message("No package infrastructure found in ", path, ". Create it?")
        create <- (menu(c("Yes", "No")) == 1)
      } else {
        create <- FALSE
      }
    }

    if (create) {
      setup(path = path)
    } else {
      stop("No description at ", path_desc, call. = FALSE)
    }
  }

  desc <- as.list(read.dcf(path_desc)[1, ])
  names(desc) <- tolower(names(desc))
  desc$path <- path

  structure(desc, class = "package")
}


#' Is the object a package?
#'
#' @keywords internal
#' @export
is.package <- function(x) inherits(x, "package")

# Mockable variant of interactive
interactive <- function() .Primitive("interactive")()
