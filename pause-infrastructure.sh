#!/bin/bash
# pause-infrastructure.sh
# Immediately pause all running ECS services to save costs

echo "🛑 Pausing Who's My Good Boy infrastructure..."
echo "💰 This will reduce monthly costs from ~$30 to ~$5"
echo ""

# Get current workspace/environment info
CURRENT_WS=$(terraform workspace show 2>/dev/null || echo "unknown")
echo "Current Terraform workspace: $CURRENT_WS"
echo ""

# Function to pause ECS service
pause_service() {
    local cluster=$1
    local service=$2
    local env_name=$3
    
    echo "⏸️  Pausing $env_name environment..."
    echo "   Cluster: $cluster"
    echo "   Service: $service"
    
    # Check if service exists and get current status
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
    
    if [ "$CURRENT_COUNT" == "0" ]; then
        echo "   ✅ Already paused"
        return 0
    fi
    
    # Scale to 0
    aws ecs update-service \
        --cluster "$cluster" \
        --service "$service" \
        --desired-count 0 \
        --no-cli-pager > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ Successfully scaled to 0 tasks"
    else
        echo "   ❌ Failed to scale service"
        return 1
    fi
}

# Pause development environment
pause_service "whos-my-good-boy-dev-cluster" "whos-my-good-boy-dev-backend" "Development"
echo ""

# Pause production environment  
pause_service "whos-my-good-boy-prod-cluster" "whos-my-good-boy-prod-backend" "Production"
echo ""

echo "🎉 Infrastructure paused successfully!"
echo ""
echo "💡 What's still running (minimal cost):"
echo "   ✅ VPC and networking (free)"
echo "   ✅ ECR repositories (~$0.50/month)"
echo "   ✅ S3 storage (~$0.50/month)"
echo "   ✅ Load balancers (~$18/month per environment)"
echo ""
echo "💰 Estimated monthly cost while paused: ~$40 (was ~$70)"
echo ""
echo "🚀 To resume when needed:"
echo "   ./resume-infrastructure.sh"
echo "   OR"
echo "   aws ecs update-service --cluster CLUSTER_NAME --service SERVICE_NAME --desired-count 1"
echo ""
echo "⏱️  Tasks will take 2-3 minutes to fully stop."