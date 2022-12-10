#' @export
navitime_total_time <- function(X_orig, Y_orig, X_dest, Y_dest,
                                start_time = lubridate::today() + lubridate::hours(9),
                                url = "https://www.navitime.co.jp/maps") {
  start <- stringr::str_glue('{{"lat":{Y_orig},"lon":{X_orig}}}')
  goal <- stringr::str_glue('{{"lat":{Y_dest},"lon":{X_dest}}}')
  start_time <- format(start_time, format = "%Y-%d-%mT%H:%M:%S")
  url_route_result <- stringr::str_glue("{url}/routeResult?start={start}&goal={goal}&start-time={start_time}")

  driver <- driver_selenium()
  on.exit(driver$close())

  pb <- progress::progress_bar$new(total = vec_size(url_route_result))

  out <- url_route_result |>
    purrr::map(function(url_route_result) {
      driver$get(url_route_result)
      Sys.sleep(5)
      find_total_time <- purrr::insistently(
        function() {
          driver$find_element(By$CSS_SELECTOR, "div.overview-route-time > span.total-time")
        },
        rate = purrr::rate_backoff(max_times = 10)
      )
      total_time <- purrr::safely(find_total_time)()

      pb$tick()
      parse_time_ja(total_time$result$text %||% "")
    })
  vec_c(!!!out)
}
