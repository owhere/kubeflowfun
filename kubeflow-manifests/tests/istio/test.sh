#! Install istio CLI 

curl -L https://istio.io/downloadIstio | sh -
cd istio-<version>
export PATH=$PWD/bin:$PATH

# echo server is not using istio, but ingress
kubectl label namespace default istio-injection=disabled --overwrite 

istioctl analyze

# Deploy an app
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/bookinfo/platform/kube/bookinfo.yaml

# Expose the service
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/bookinfo/networking/bookinfo-gateway.yaml

# Verify the Gateway and VirtualService
kubectl get gateway -n default
kubectl get virtualservice -n default
kubectl get svc istio-ingressgateway -n istio-system

#http://<EXTERNAL-IP>/productpage

#Test with Nodeport
kubectl edit svc istio-ingressgateway -n istio-system
#http://<ip>:<port>/productpage

#Clean up
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/bookinfo/platform/kube/bookinfo.yaml

#Remove Gateway and Virtual Services
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.24/samples/bookinfo/networking/bookinfo-gateway.yaml
