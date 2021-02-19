/* provider "newrelic" {
    # Your New Relic User API key
    api_key = var.newrelic_api_key
    # New Relic Account Number
    account_id = var.newrelic_account_id
    # Region "US" or "EU"
    region = var.region
} */

provider "newrelic" {
    api_key = "YOUR-PERSONAL-API-KEY"
    account_id = "YOUR-ACCOUNT-ID"
    region = "US"
}

data "newrelic_entity" "app" {
  name = "YOUR_APPLICATION-NAME"
  domain = "APM"
  type = "APPLICATION"
}

resource "newrelic_alert_policy" "golden_signal_policy" {
    name = "New Golden Signal - ${data.newrelic_entity.app.name}"
}

# The newrelic_nrql_alert_condition resource is preferred
resource "newrelic_nrql_alert_condition" "nrql_alert" {
    policy_id = newrelic_alert_policy.golden_signal_policy.id

    name    = "high_throughput"
    type    = "static"
    violation_time_limit = "one_hour" 
    value_function = "single_value"
    
    # either `since_value` or `evaluation_offset` must be configured for block `nrql`
    nrql {
        query   = "SELECT count(*) FROM Transaction WHERE appName ='WebPortal'"
        evaluation_offset = 3
    }
    
    critical {
        operator              = "above"
        threshold             = 400
        threshold_duration    = 300
        threshold_occurrences = "ALL"
    }
}

# Fetches the data for this policy from your New Relic account
# and is referenced in the newrelic_alert_policy_channel block below.

# Create a Email Notification channel
resource "newrelic_alert_channel" "alert_notification_email" {
  name = "sshetty@newrelic.com"
  type = "email"
  config {
    recipients              = "sshetty@newrelic.com"
    include_json_attachment = "1"
  }
}

# Creates a Slack Notification channel.
resource "newrelic_alert_channel" "alert_notification_slack" {
  name = "slack-channel-example"
  type = "slack"

  config {
    channel = "#example-channel"
    url     = "http://example-org.slack.com"
  }
}

# use existing channel
data "newrelic_alert_channel" "another_slack" {
  name = "Sri - Gama"
}

# Link the above notification channel to your policy
resource "newrelic_alert_policy_channel" "alert_policy_email" {
  policy_id  = newrelic_alert_policy.golden_signal_policy.id
  channel_ids = [
    newrelic_alert_channel.alert_notification_email.id,
    newrelic_alert_channel.alert_notification_slack.id,
    data.newrelic_alert_channel.another_slack.id
  ]
}
