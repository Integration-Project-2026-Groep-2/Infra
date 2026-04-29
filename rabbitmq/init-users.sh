#!/bin/bash
# Create users for each service
rabbitmqctl add_user crm_user ${CRM_RABBIT_PASS}
rabbitmqctl add_user billing_user ${BILLING_RABBIT_PASS}
rabbitmqctl add_user mailing_user ${MAILING_RABBIT_PASS}
rabbitmqctl add_user kassa_user ${KASSA_RABBIT_PASS}
rabbitmqctl add_user frontend_user ${FRONTEND_RABBIT_PASS}
rabbitmqctl add_user planning_user ${PLANNING_RABBIT_PASS}

# Set permissions (vhost is often "/")
rabbitmqctl set_permissions -p / crm_user ".*" ".*" ".*"
rabbitmqctl set_permissions -p / billing_user ".*" ".*" ".*"
rabbitmqctl set_permissions -p / mailing_user ".*" ".*" ".*"
rabbitmqctl set_permissions -p / kassa_user ".*" ".*" ".*"
rabbitmqctl set_permissions -p / frontend_user ".*" ".*" ".*"
rabbitmqctl set_permissions -p / planning_user ".*" ".*" ".*"