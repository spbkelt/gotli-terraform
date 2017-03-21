apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: gotli
spec:
  replicas: ${instance_replicas}
  template:
    metadata:
      labels:
        app: gotli
    spec:
      containers:
      - name: gotli
        image: ${image_uri}
        ports:
        - containerPort: ${app_container_port}
---
apiVersion: v1
kind: Service
metadata:
  name: gotli
  labels:
    app: gotli
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${aws_tls_cert_arn}"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: http
spec:
  ports:
  - port: 80
    targetPort: 8000
    protocol: HTTP
    name: http
  - port: 443
    targetPort: 8000
    protocol: HTTP
    name: https
  selector:
    app: gotli
  type: LoadBalancer
