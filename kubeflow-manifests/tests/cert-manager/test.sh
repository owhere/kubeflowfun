#! /bin/bash

kubectl apply -f self-signed-issuer.yaml

kubectl apply -f test-certificate.yaml

kubectl describe certificate test-certificate -n default

kubectl get secret test-certificate-secret -n default

# Expected events
# Events:
#  Type    Reason     Age   From                                       Message
#  ----    ------     ----  ----                                       -------
#  Normal  Issuing    9s    cert-manager-certificates-trigger          Issuing certificate as Secret does not exist
#  Normal  Generated  9s    cert-manager-certificates-key-manager      Stored new private key in temporary Secret resource "test-certificate-4nxsm"
#  Normal  Requested  9s    cert-manager-certificates-request-manager  Created new CertificateRequest resource "test-certificate-1"
#  Normal  Issuing    9s    cert-manager-certificates-issuing          The certificate has been successfully issued
