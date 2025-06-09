#!/bin/bash
# resume-infrastructure.sh  
# Resume all paused ECS services

echo "🚀 Resuming Who's My Good Boy infrastructure..."
echo "⏱️  Services will take 2-3 minutes to become healthy"
echo ""

# Function to resume ECS service
resume_service() {
    local cluster=$1
    local service=$2
    local desired_count=$3
    local env_name=$4
    
    echo "▶️  Resuming $env_name environment..."
    echo "   Cluster: $cluster"
    echo "   Service: $service"
    echo "   Target tasks: $desired_count"
    
    # Check current status
    CURRENT_COUNT=$(aws ecs describe-services \
        --cluster "$cluster" \
        --services "$service" \
        --query 'services[0].runningCount' \
        --output text 2>/dev/null)
    
    if [ "$CURRENT_COUNT" == "None" ] || [ "$CURRENT_COUNT" == "" ]; then
        echo "   ❌ Service not found or not accessible"
        return 1
    fi
    
    echo "   Current running tasks: $CURRENT_COUNT"
    
    if [ "$CURRENT_COUNT" == "$desired_count" ]; then
        echo "   ✅ Already running at desired capacity"
        return 0
    fi
    
    # Scale up
    aws ecs update-service \
        --cluster "$cluster" \
        --service "$service" \
        --desired-count "$desired_count" \
        --no-cli-pager > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Successfully scaled to $desired_count tasks"
        echo "   ⏱️  Waiting for tasks to start..."
    else
        echo "   ❌ Failed to scale service"
        return 1
    fi
}

# Resume development environment (1 task)
resume_service "whos-my-good-boy-dev-cluster" "whos-my-good-boy-dev-backend" "1" "Development"
echo ""

# Resume production environment (2 tasks)
resume_service "whos-my-good-boy-prod-cluster" "whos-my-good-boy-prod-backend" "2" "Production"
echo ""

echo "🎉 Infrastructure resume initiated!"
echo ""
echo "⏱️  Please wait 2-3 minutes for services to become healthy"
echo ""
echo "🔍 Check status with:"
echo "   aws ecs describe-services --cluster whos-my-good-boy-dev-cluster --services whos-my-good-boy-dev-backend"
echo "   aws ecs describe-services --cluster whos-my-good-boy-prod-cluster --services whos-my-good-boy-prod-backend"
echo ""
echo "🌐 Access your application via the ALB DNS names shown in AWS console"
echo ""
echo "💰 Monthly cost resumed to ~$70"
echo ""
echo "💡 To pause again when done:"
echo "   ./pause-infrastructure.sh"