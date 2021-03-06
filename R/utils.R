#' Extracting a class of variables
#'
#' @description The get_class() gets class of variables in data.frame or tbl_df.
#'
#' @param df a data.frame or objects inheriting from data.frame
#' @return a data.frame
#' Variables of data.frame is as follows.
#' \itemize{
#' \item variable : variables name
#' \item class : class of variables
#' }
#' @seealso \code{\link{find_class}}.
#' @export
#' @examples
#' \dontrun{
#' # data.frame
#' get_class(iris)
#'
#' # tbl_df
#' get_class(ggplot2::diamonds)
#'
#' library(dplyr)
#' get_class(ggplot2::diamonds) %>%
#'   filter(class %in% c("integer", "numeric"))
#' }
#' @export
get_class <- function(df) {
  vars <- sapply(names(df), function(.x.) class(pull(df, .x.))[1])

  data.frame(variable = names(vars), class = vars, row.names = NULL)
}


#' Extract variable names or indices of a specific class
#'
#' @description The find_class() extracts variable information having a
#' certain class from an object inheriting data.frame.
#'
#' @param df a data.frame or objects inheriting from data.frame
#' @param type character. Defines a group of classes to be searched.
#' "numerical" searches for "numeric" and "integer" classes,
#' "categorical" searches for "factor" and "ordered" classes.
#' "categorical2" adds "character" class to "categorical".
#' @param index logical. If TRUE is return numeric vector that is variables index.
#' and if FALSE is return character vector that is variables name.
#' defalut is TRUE.
#'
#' @return character vector or numeric vector.
#' The meaning of vector according to data type is as follows.
#' \itemize{
#' \item character vector : variables name
#' \item numeric vector : variables index
#' }
#' @seealso \code{\link{get_class}}.
#' @export
#' @examples
#' \dontrun{
#' # data.frame
#' find_class(iris, "numerical")
#' find_class(iris, "numerical", index = FALSE)
#' find_class(iris, "categorical")
#' find_class(iris, "categorical", index = FALSE)
#'
#' # tbl_df
#' find_class(ISLR::Carseats, "numerical")
#' find_class(ISLR::Carseats, "numerical", index = FALSE)
#' find_class(ISLR::Carseats, "categorical")
#' find_class(ISLR::Carseats, "categorical", index = FALSE)
#'
#' # type is "categorical2"
#' iris2 <- data.frame(iris, char = "chars",
#'                     stringsAsFactors = FALSE)
#' find_class(iris2, "categorical", index = FALSE)
#' find_class(iris2, "categorical2", index = FALSE)
#' }
#' @importFrom methods is
#' @export
find_class <- function(df, type = c("numerical", "categorical", "categorical2"),
                       index = TRUE) {
  if (!is.data.frame(df)) {
    stop("The argument 'df' is not an object inheriting from data.frame.")
  }

  clist <- sapply(seq(df), function(.x.) is(pull(df, .x.))[1])

  type <- match.arg(type)

  if (type == "numerical") {
    idx <- which(clist %in% c("integer", "numeric"))
  } else if (type == "categorical") {
    idx <- which(clist %in% c("factor", "ordered"))
  } else if (type == "categorical2") {
    idx <- which(clist %in% c("factor", "ordered", "character"))
  }

  if (!index) idx <- names(df)[idx]

  idx
}


#' Finding variables including missing values
#'
#' @description
#' Find the variable that contains the missing value in the object
#' that inherits the data.frame or data.frame.
#'
#' @param .data a data.frame or a \code{\link{tbl_df}}.
#' @param index logical. When representing the information of a variable including
#' missing values, specify whether or not the variable is represented by an index.
#' Returns an index if TRUE or a variable names if FALSE.
#' @param rate logical. If TRUE, returns the percentage of missing values
#' in the individual variable.
#' @return Information on variables including missing values.
#' @seealso \code{\link{imputate_na}}, \code{\link{find_na}}.
#' @examples
#' \dontrun{
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' find_na(carseats)
#'
#' find_na(carseats, index = FALSE)
#'
#' find_na(carseats, rate = TRUE)
#'
#' ## using dplyr -------------------------------------
#' library(dplyr)
#'
#' # Perform simple data quality diagnosis of variables with missing values.
#' carseats %>%
#'   select(find_na(.)) %>%
#'   diagnose()
#' }
#' @importFrom purrr map_lgl map_dbl
#' @export
#'
find_na <- function(.data, index = TRUE, rate = FALSE) {
  if (rate) {
    idx <- .data %>%
      map_dbl(function(x) sum(is.na(x)) / length(x) * 100) %>%
      round(3)
  } else {
    idx <- .data %>%
      map_lgl(function(x) any(is.na(x))) %>%
      which()
    
    names(idx) <- NULL

    if (!index) idx <- names(.data)[idx]
  }

  idx
}


#' Finding variables including outliers
#'
#' @description
#' Find the numerical variable that contains outliers in the object
#' that inherits the data.frame or data.frame.
#'
#' @param .data a data.frame or a \code{\link{tbl_df}}.
#' @param index logical. When representing the information of a variable including
#' outliers, specify whether or not the variable is represented by an index.
#' Returns an index if TRUE or a variable names if FALSE.
#' @param rate logical. If TRUE, returns the percentage of outliers
#' in the individual variable.
#' @return Information on variables including outliers.
#' @seealso \code{\link{find_na}}, \code{\link{imputate_outlier}}.
#' @examples
#' \dontrun{
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' find_outliers(carseats)
#'
#' find_outliers(carseats, index = FALSE)
#'
#' find_outliers(carseats, rate = TRUE)
#'
#' ## using dplyr -------------------------------------
#' library(dplyr)
#'
#' # Perform simple data quality diagnosis of variables with outliers.
#' carseats %>%
#'   select(find_outliers(.)) %>%
#'   diagnose()
#' }
#' @importFrom purrr map_lgl map_dbl
#' @export
#'
find_outliers <- function(.data, index = TRUE, rate = FALSE) {
  numeric_flag <- sapply(seq(.data),
    function(.x.) is(pull(.data, .x.))[1] == "numeric")

  if (rate) {
    idx <- .data %>%
      .[, numeric_flag] %>%
      map_dbl(function(x) length(boxplot.stats(x)$out) / length(x) * 100) %>%
      round(3)
  } else {
    idx <- .data %>%
      .[, numeric_flag] %>%
      map_lgl(function(x) length(boxplot.stats(x)$out) > 0) %>%
      which()

    names(idx) <- NULL
    
    if (!index) idx <- names(.data)[idx]
  }

  idx
}


#' Finding skewed variables
#'
#' @description
#' Find the numerical variable that skewed variable
#' that inherits the data.frame or data.frame.
#'
#' @param .data a data.frame or a \code{\link{tbl_df}}.
#' @param index logical. When representing the information of a skewed variable,
#' specify whether or not the variable is represented by an index.
#' Returns an index if TRUE or a variable names if FALSE.
#' @param value logical. If TRUE, returns the skewness value
#' in the individual variable.
#' @param thres Returns a skewness threshold value that has an absolute skewness
#' greater than thres. The default is NULL to ignore the threshold.
#' but, If value = TRUE, default to 0.5.
#' @return Information on variables including skewness.
#' @seealso \code{\link{find_na}}, \code{\link{find_outliers}}.
#' @examples
#' \dontrun{
#' # Generate data for the example
#' carseats <- ISLR::Carseats
#' carseats[sample(seq(NROW(carseats)), 20), "Income"] <- NA
#' carseats[sample(seq(NROW(carseats)), 5), "Urban"] <- NA
#'
#' find_skewness(carseats)
#'
#' find_skewness(carseats, index = FALSE)
#'
#' find_skewness(carseats, thres = 0.1)
#'
#' find_skewness(carseats, value = TRUE)
#'
#' find_skewness(carseats, value = TRUE, thres = 0.1)
#'
#' ## using dplyr -------------------------------------
#' library(dplyr)
#'
#' # Perform simple data quality diagnosis of variables with outliers.
#' carseats %>%
#'   select(find_skewness(.)) %>%
#'   diagnose()
#' }
#' @importFrom purrr map_lgl map_dbl
#' @importFrom moments skewness
#' @export
find_skewness <- function(.data, index = TRUE, value = FALSE, thres = NULL) {
  numeric_flag <- sapply(seq(.data),
    function(.x.) is(pull(.data, .x.))[1] == "numeric")

  if (value) {
    idx <- .data %>%
      .[, numeric_flag] %>%
      map_dbl(moments::skewness) %>%
      round(3)
    if (!is.null(thres)) idx <- idx[abs(idx) >= thres & !is.na(idx)]
  } else {
    if (is.null(thres)) thres <- 0.5

    idx <- .data %>%
      .[, numeric_flag] %>%
      map_lgl(function(x) abs(moments::skewness(x)) >= thres) %>%
      which()

    names(idx) <- NULL
    
    if (!index) idx <- names(.data)[idx]
  }

  idx
}


#' Finding Users Machine's OS
#'
#' @description
#' Get the operating system that users machines.
#'
#' @return OS names. "windows" or "osx" or "linux"
#'
#' @examples
#' get_os()
#'
#' @export
get_os <- function() {
  system_info <- Sys.info()

  if (!is.null(system_info)) {
    os <- system_info['sysname']

    if (os == 'Darwin')
      os <- "osx"
  } else {
    os <- .Platform$OS.type

    if (grepl("^darwin", R.version$os))
      os <- "osx"
    if (grepl("linux-gnu", R.version$os))
      os <- "linux"
  }
  tolower(os)
}

