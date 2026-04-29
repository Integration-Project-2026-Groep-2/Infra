#!/bin/bash

# Function to create user and set permissions
create_service_user() {
    local username=$1
    local password=$2
    if [ -n "$username" ] && [ -n "$password" ]; then
        rabbitmqctl add_user "$username" "$password"
        rabbitmqctl set_permissions -p / "$username" ".*" ".*" ".*"
        echo "Created user: $username"
    fi
}

# Execute creation for all services
create_service_user "$RABBITMQ_USER_CONTROLROOM" "$RABBITMQ_PASS_CONTROLROOM"
create_service_user "$RABBITMQ_USER_BILLING" "$RABBITMQ_PASS_BILLING"
create_service_user "$RABBITMQ_USER_MAILING" "$RABBITMQ_PASS_MAILING"
create_service_user "$RABBITMQ_USER_KASSA" "$RABBITMQ_PASS_KASSA"
create_service_user "$RABBITMQ_USER_CRM" "$RABBITMQ_PASS_CRM"
create_service_user "$RABBITMQ_USER_FRONTEND" "$RABBITMQ_PASS_FRONTEND"
create_service_user "$RABBITMQ_USER_PLANNING" "$RABBITMQ_PASS_PLANNING"