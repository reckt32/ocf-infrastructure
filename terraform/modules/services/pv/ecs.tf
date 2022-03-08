# define aws ecs task definition
# needs access to the internet

resource "aws_ecs_task_definition" "pv-task-definition" {
  family                   = "pv"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  # specific values are needed -
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  cpu    = 256
  memory = 512

  task_role_arn      = aws_iam_role.consumer-pv-iam-role.arn
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name  = "pv-consumer"
      image = "openclimatefix/pvconsumer:${var.docker_version}"
      #      cpu       = 128
      #      memory    = 128
      essential = true

      environment : [
        { "name" : "LOG_LEVEL", "value" : "DEBUG"},
      ]

      secrets : [
        {
          "name" : "API_KEY",
          "valueFrom" : "${data.aws_secretsmanager_secret_version.pv-api-version.arn}:api_key::",
        },
        {
          "name" : "SYSTEM_ID",
          "valueFrom" : "${data.aws_secretsmanager_secret_version.pv-api-version.arn}:system_id::",
        },
        {
          "name" : "DB_URL",
          "valueFrom" : "${var.database_secret.arn}:url::",
        }
      ]

      logConfiguration : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : var.log-group-name,
          "awslogs-region" : var.region,
          "awslogs-stream-prefix" : "streaming"
        }
      }
    }
  ])

  # add volume? So we dont have to keep downloading same docker image
}
