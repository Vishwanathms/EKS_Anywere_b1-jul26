#!/bin/bash
echo "Validating cluster"
kubectl cluster-info
helm install database charts/database
helm install controller charts/controller
helm install monitoring charts/monitoring
