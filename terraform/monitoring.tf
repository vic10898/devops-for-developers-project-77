resource "datadog_monitor" "redmine_check" {
  name    = "Redmine App Alive Monitor"
  type    = "service check"
  message = "Redmine application is down on host {{host.name}}! Please investigate."

  query = "\"http.can_connect\".over(\"instance:redmine_app_check\").by(\"host\").last(2).count_by_status()"

  monitor_thresholds {
    critical = 1
    warning  = 1
    ok       = 1
  }

  notify_no_data    = true
  no_data_timeframe = 10
  renotify_interval = 60
}
