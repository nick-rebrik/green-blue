reload_nginx() {
  nginx_container_id=$(docker ps -f name=nginx -q | head -n1)
  echo "Reloading Nginx (container ID: $nginx_container_id)... "
  docker exec $nginx_container_id nginx -s reload
}

wait_for_container() {
  local container_id=$1
  local service_port=$2

  container_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container_id)

  echo "Waiting for new container to be available at $container_ip:$service_port..."
  curl --silent --include --retry-connrefused --retry 30 --retry-delay 4 --fail http://$container_ip:$service_port || {
    echo "New container failed health check at $container_ip:$service_port, exiting..."
    exit 1
  }
  echo "New container at $container_ip:$service_port working"
}

deploy_service() {
  local service_name=$1
  local service_port=$2

  echo "Deploying $service_name..."

  # bring a new container online, running new code
  echo "Scale $service_name..."
  docker-compose up -d --no-deps --scale $service_name=2 --no-recreate $service_name

  # wait for new container to be available
  echo "Check new container..."
  local new_container_id=$(docker ps -f name=$service_name -q | head -n1)
  wait_for_container $new_container_id $service_port

  # start routing requests to the new container (as well as the old)
  echo "Reload Nginx..."
  reload_nginx

  # take the old container offline
  local old_container_id=$(docker ps -f name=$service_name -q | tail -n1)
  docker stop $old_container_id
  docker rm $old_container_id

  # finalize scaling
  docker-compose up -d --no-deps --scale $service_name=1 --no-recreate $service_name

  # stop routing requests to the old container
  reload_nginx
}

zero_downtime_deploy() {
  deploy_service "web" "8000"
}

zero_downtime_deploy
