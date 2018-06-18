#!/bin/bash
# Copyright (c) 2018 Armin Ranjbar Daemi @rmin
# Licensed under the MIT License

set -e
readonly TENANT=$1
if [[ -z "${TENANT}" ]]; then
  echo "Usage: $0 TENANT-NAME"
  exit 1
fi
# validate tenant name
if [[ "${TENANT}" =~ [^a-zA-Z0-9] ]]; then
  echo "Use Alphanumeric string for tenant name."
  exit 1
fi

# generate access and secret keys
echo "Generating secrets for the new tenant."
readonly NEW_ACCESS=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 20 | head -n 1)
readonly NEW_SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 40 | head -n 1)
echo "${NEW_SECRET}" | sudo docker secret create "s3_${TENANT}_secret" -
echo "${NEW_ACCESS}" | sudo docker secret create "s3_${TENANT}_access" -

# generate the yml file
cat > "/vagrant/stack/s3_${TENANT}.yml" << EOF
version: '3.4'

services:
  minio1-${TENANT}:
    image: minio/minio
    volumes:
      - data:/export
    networks:
      - traefik_proxy
    environment:
      - MINIO_REGION=us-east-1
      - MINIO_BROWSER=off
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == us-east-1-1
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      labels:
        traefik.frontend.rule: "Host:${TENANT}.s3-us-east-1.example.com"
        traefik.backend.healthcheck.path: "/minio/health/ready"
        traefik.backend.healthcheck.interval: "10s"
        traefik.docker.network: "traefik_proxy"
        traefik.port: "9000"
    command: server http://minio1-${TENANT}/export http://minio2-${TENANT}/export http://minio3-${TENANT}/export http://minio4-${TENANT}/export
    secrets:
      - source: s3_${TENANT}_secret
        target: secret_key
      - source: s3_${TENANT}_access
        target: access_key

  minio2-${TENANT}:
    image: minio/minio
    volumes:
      - data:/export
    networks:
      - traefik_proxy
    environment:
      - MINIO_REGION=us-east-1
      - MINIO_BROWSER=off
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == us-east-1-2
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      labels:
        traefik.frontend.rule: "Host:${TENANT}.s3-us-east-1.example.com"
        traefik.backend.healthcheck.path: "/minio/health/ready"
        traefik.backend.healthcheck.interval: "10s"
        traefik.docker.network: "traefik_proxy"
        traefik.port: "9000"
    command: server http://minio1-${TENANT}/export http://minio2-${TENANT}/export http://minio3-${TENANT}/export http://minio4-${TENANT}/export
    secrets:
      - source: s3_${TENANT}_secret
        target: secret_key
      - source: s3_${TENANT}_access
        target: access_key

  minio3-${TENANT}:
    image: minio/minio
    volumes:
      - data:/export
    networks:
      - traefik_proxy
    environment:
      - MINIO_REGION=us-east-1
      - MINIO_BROWSER=off
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == us-east-1-3
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      labels:
        traefik.frontend.rule: "Host:${TENANT}.s3-us-east-1.example.com"
        traefik.backend.healthcheck.path: "/minio/health/ready"
        traefik.backend.healthcheck.interval: "10s"
        traefik.docker.network: "traefik_proxy"
        traefik.port: "9000"
    command: server http://minio1-${TENANT}/export http://minio2-${TENANT}/export http://minio3-${TENANT}/export http://minio4-${TENANT}/export
    secrets:
      - source: s3_${TENANT}_secret
        target: secret_key
      - source: s3_${TENANT}_access
        target: access_key

  minio4-${TENANT}:
    image: minio/minio
    volumes:
      - data:/export
    networks:
      - traefik_proxy
    environment:
      - MINIO_REGION=us-east-1
      - MINIO_BROWSER=off
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == us-east-1-4
      restart_policy:
        delay: 10s
        max_attempts: 10
        window: 60s
      labels:
        traefik.frontend.rule: "Host:${TENANT}.s3-us-east-1.example.com"
        traefik.backend.healthcheck.path: "/minio/health/ready"
        traefik.backend.healthcheck.interval: "10s"
        traefik.docker.network: "traefik_proxy"
        traefik.port: "9000"
    command: server http://minio1-${TENANT}/export http://minio2-${TENANT}/export http://minio3-${TENANT}/export http://minio4-${TENANT}/export
    secrets:
      - source: s3_${TENANT}_secret
        target: secret_key
      - source: s3_${TENANT}_access
        target: access_key

volumes:
  data:

networks:
  traefik_proxy:
    driver: overlay
    external: true

secrets:
  s3_${TENANT}_secret:
    external: true
  s3_${TENANT}_access:
    external: true
EOF

# deploy the stack for tenant
sudo docker stack deploy --compose-file="/vagrant/stack/s3_${TENANT}.yml" "s3_${TENANT}"

echo "Adding proxy endpoint into hosts file (you need a proper DNS record for this)."
echo "192.168.95.100 ${TENANT}.s3-us-east-1.example.com" | sudo tee --append /etc/hosts > /dev/null
echo ""
echo "Access key: ${NEW_ACCESS}"
echo "Secret key: ${NEW_SECRET}"
echo "Region: us-east-1"
echo "Endpoint-URL: ${TENANT}.s3-us-east-1.example.com"
