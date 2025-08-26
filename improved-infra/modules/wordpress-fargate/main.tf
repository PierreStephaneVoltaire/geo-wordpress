terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# Local variables
locals {
  is_primary = var.region_config.is_primary
  container_port = 80
}

# ECS Cluster
resource "aws_ecs_cluster" "wordpress" {
  name = "${var.project_name}-cluster-${var.region_name}-${var.random_suffix}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ecs-cluster-${var.region_name}-${var.random_suffix}"
  })
}

# Application Load Balancer
resource "aws_lb" "wordpress" {
  name               = "${var.project_name}-alb-${var.region_name}-${var.random_suffix}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-${var.region_name}-${var.random_suffix}"
  })
}

# ALB Target Group
resource "aws_lb_target_group" "wordpress" {
  name        = "${var.project_name}-tg-${var.region_name}-${var.random_suffix}"
  port        = local.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,302"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 10
    unhealthy_threshold = 5
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tg-${var.region_name}-${var.random_suffix}"
  })
}

# ALB Listener
resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id         = "${var.project_name}-redis-${var.region_name}-${var.random_suffix}"
  description                  = "Redis cluster for WordPress caching"
  
  node_type                    = "cache.t4g.nano"  # Smallest possible for cost optimization
  port                         = 6379
  parameter_group_name         = "default.redis7"
  
  num_cache_clusters           = 1  # Single node for cost optimization with low traffic
  automatic_failover_enabled   = false  # Disabled for single node setup
  multi_az_enabled            = false   # Disabled for cost optimization
  
  subnet_group_name           = var.elasticache_subnet_group_name
  security_group_ids          = [var.redis_security_group_id]
  
  at_rest_encryption_enabled  = true
  transit_encryption_enabled  = true
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-redis-${var.region_name}-${var.random_suffix}"
  })
}

# IAM execution role for ECS tasks
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project_name}-ecs-execution-${var.region_name}-${var.random_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM task role for WordPress container
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-${var.region_name}-${var.random_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policies
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Custom policy for Parameter Store access
resource "aws_iam_role_policy" "ecs_task_parameter_store" {
  name = "${var.project_name}-parameter-store-${var.region_name}-${var.random_suffix}"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${var.region_config.region}:*:parameter/${var.project_name}/${var.environment}/*"
        ]
      }
    ]
  })
}

# Custom policy for S3 access
resource "aws_iam_role_policy" "ecs_task_s3" {
  name = "${var.project_name}-s3-${var.region_name}-${var.random_suffix}"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# ECS Task Definition with custom WordPress container
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.project_name}-wordpress-${var.region_name}-${var.random_suffix}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.fargate_cpu)    # Configurable CPU
  memory                   = tostring(var.fargate_memory) # Configurable memory

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "wordpress"
      image = "wordpress:6.4-apache"
      
      portMappings = [
        {
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.db_name
        },
        {
          name  = "WORDPRESS_TABLE_PREFIX"
          value = "wp_"
        },
        {
          name  = "AWS_REGION"
          value = var.region_config.region
        },
        {
          name  = "WORDPRESS_CONFIG_EXTRA"
          value = <<-EOF
            // S3 Uploads Plugin Configuration
            define('S3_UPLOADS_BUCKET', '${var.s3_bucket_name}');
            define('S3_UPLOADS_REGION', '${var.region_config.region}');
            define('S3_UPLOADS_USE_INSTANCE_PROFILE', true);
            
            // Redis Object Cache Configuration
            define('WP_REDIS_HOST', '${aws_elasticache_replication_group.redis.primary_endpoint_address}');
            define('WP_REDIS_PORT', 6379);
            define('WP_REDIS_PASSWORD', '');
            define('WP_REDIS_TIMEOUT', 1);
            define('WP_REDIS_READ_TIMEOUT', 1);
            define('WP_REDIS_DATABASE', 0);
            
            // Database Read/Write Splitting - HyperDB Configuration
            define('DB_HOST_PRIMARY', '${var.db_primary_endpoint}');
            ${local.is_primary ? "" : "define('DB_HOST_REPLICA', '${var.db_replica_endpoint}');"}
            
            // Security enhancements
            define('DISALLOW_FILE_EDIT', true);
            define('WP_DEBUG', false);
            define('WP_DEBUG_LOG', false);
            define('WP_DEBUG_DISPLAY', false);
          EOF
        }
      ]

      secrets = [
        {
          name      = "WORDPRESS_DB_HOST"
          valueFrom = "/${var.project_name}/${var.environment}/database/endpoint/${local.is_primary ? "primary" : var.region_name}"
        },
        {
          name      = "WORDPRESS_DB_USER"
          valueFrom = "/${var.project_name}/${var.environment}/database/username"
        },
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "/${var.project_name}/${var.environment}/database/password"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.wordpress.name
          "awslogs-region"        = var.region_config.region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval = 30
        timeout = 10
        retries = 3
        startPeriod = 60
      }

      essential = true
    }
  ])

  tags = var.tags
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "wordpress" {
  name              = "/ecs/${var.project_name}-wordpress-${var.region_name}-${var.random_suffix}"
  retention_in_days = 7

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "wordpress" {
  name            = "${var.project_name}-service-${var.region_name}-${var.random_suffix}"
  cluster         = aws_ecs_cluster.wordpress.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = var.region_config.fargate.desired_capacity
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  # Default deployment configuration

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress.arn
    container_name   = "wordpress"
    container_port   = local.container_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.wordpress.arn
  }

  depends_on = [aws_lb_listener.wordpress]

  tags = var.tags
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "wordpress" {
  name = "${var.project_name}.local"
  vpc  = var.vpc_id

  tags = var.tags
}

resource "aws_service_discovery_service" "wordpress" {
  name = "wordpress-${var.region_name}"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.wordpress.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = var.tags
}

# Auto Scaling
resource "aws_appautoscaling_target" "wordpress" {
  max_capacity       = var.region_config.fargate.max_capacity
  min_capacity       = var.region_config.fargate.min_capacity
  resource_id        = "service/${aws_ecs_cluster.wordpress.name}/${aws_ecs_service.wordpress.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "wordpress_up" {
  name               = "${var.project_name}-scale-up-${var.region_name}-${var.random_suffix}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

resource "aws_appautoscaling_policy" "wordpress_memory" {
  name               = "${var.project_name}-scale-memory-${var.region_name}-${var.random_suffix}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.wordpress.resource_id
  scalable_dimension = aws_appautoscaling_target.wordpress.scalable_dimension
  service_namespace  = aws_appautoscaling_target.wordpress.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80.0
  }
}