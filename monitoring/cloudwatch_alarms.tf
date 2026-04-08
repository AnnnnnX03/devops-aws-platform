# monitoring/cloudwatch_alarms.tf
# ─────────────────────────────────────────────────────────────
# CLOUDWATCH ALARMS — based on the 4 Golden Signals
#
# The 4 Golden Signals (Google SRE Book):
# 1. Latency   — how long requests take
# 2. Traffic   — how many requests per second
# 3. Errors    — rate of failed requests
# 4. Saturation — how full your resources are (CPU, memory)
# ─────────────────────────────────────────────────────────────

# ── SIGNAL 1: LATENCY ────────────────────────────────────────
# Alert if 95% of requests take longer than 1 second
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "high-response-latency"
  alarm_description   = "ALB response time > 1 second (P95)"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60                   # Check every 60 seconds
  statistic           = "p95"                # 95th percentile
  threshold           = 1.0                  # 1 second

  alarm_actions = [var.sns_topic_arn]        # Send alert to SNS (email/Slack)
}

# ── SIGNAL 2: TRAFFIC ────────────────────────────────────────
# Track request count — useful for capacity planning
resource "aws_cloudwatch_metric_alarm" "high_traffic" {
  alarm_name          = "unusually-high-traffic"
  alarm_description   = "Request count spike — possible attack or viral traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10000                # Alert if > 10,000 requests/minute

  alarm_actions = [var.sns_topic_arn]
}

# ── SIGNAL 3: ERRORS ─────────────────────────────────────────
# Alert if error rate exceeds 5%
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "high-5xx-error-rate"
  alarm_description   = "5XX error rate > 5% — app is returning server errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10

  alarm_actions = [var.sns_topic_arn]
}

# ── SIGNAL 4: SATURATION ─────────────────────────────────────
# Alert if ECS CPU usage exceeds 80%
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ecs-high-cpu"
  alarm_description   = "ECS CPU > 80% — containers are under heavy load"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [var.sns_topic_arn]
}

# ── CLOUDWATCH DASHBOARD ─────────────────────────────────────
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "devops-platform-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "4 Golden Signals"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", { label = "Latency (P95)", stat = "p95" }],
            ["AWS/ApplicationELB", "RequestCount", { label = "Traffic", stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", { label = "Errors", stat = "Sum" }],
            ["AWS/ECS", "CPUUtilization", { label = "CPU Saturation", stat = "Average" }]
          ]
        }
      }
    ]
  })
}

variable "sns_topic_arn" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
