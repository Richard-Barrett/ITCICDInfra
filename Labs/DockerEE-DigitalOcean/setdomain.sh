#!/bin/bash
DOMAIN="$1"
DOMAIN="${DOMAIN:-example.co}"
sed "s/DOMAIN/$DOMAIN/g" ansible-hosts.template > ansible-hosts
sed "s/DOMAIN/$DOMAIN/g" babyswarm.auto.tfvars.template > babyswarm.auto.tfvars

sed "s/DOMAIN/$DOMAIN/g" ./cafe/cafe-ingress.yaml.template > ./cafe/cafe-ingress.yaml
sed "s/DOMAIN/$DOMAIN/g" ./cafe/cafe-ingress-http.yaml.template > ./cafe/cafe-ingress-http.yaml
