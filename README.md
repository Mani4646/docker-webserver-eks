# Simple WebServer for Docker & EKS

A complete, production-ready Docker webserver application designed to run on Amazon EKS. This project includes Flask application, Docker configuration, Kubernetes manifests, and deployment automation.

## 📋 Project Overview

This repository contains:
- **Flask WebServer** - Simple Python web application with health checks
- **Docker Configuration** - Complete Dockerfile with best practices
- **Kubernetes Manifests** - Ready-to-deploy Kubernetes configurations for EKS
- **Build Automation** - Scripts to build and push to AWS ECR
- **Health Checks** - Built-in endpoint monitoring for container health

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    EKS Cluster                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────────────────────────────────────────┐ │
│  │         Ingress (ALB - Optional)                 │ │
│  │  simple-webserver.example.com                    │ │
│  └──────────────────────────┬──────────────────────────┘ │
│                             │                              │
│  ┌──────────────────────────┴──────────────────────────┐ │
│  │  Service (LoadBalancer)                          │ │
│  │  simple-webserver-service:80                     │ │
│  └──────────────────────────┬──────────────────────────┘ │
│                             │                              │
│  ┌──────────────────────────┴──────────────────────────┐ │
│  │        Deployment (3 Replicas)                   │ │
│  │                                                  │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  │ Pod 1      │  │ Pod 2      │  │ Pod 3      │ │
│  │  │ Flask App  │  │ Flask App  │  │ Flask App  │ │
│  │  │ Port: 5000 │  │ Port: 5000 │  │ Port: 5000 │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘ │
│  └──────────────────────────────────────────────────────┘ │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
docker-webserver-eks/
├── .dockerignore                 # Docker build exclusions
├── .gitignore                    # Git exclusions
├── Dockerfile                    # Docker container image definition
├── app.py                        # Flask web application
├── requirements.txt              # Python dependencies
├── build-and-push.sh            # AWS ECR build and push script
├── kubernetes/
│   ├── deployment.yaml          # Kubernetes Deployment manifest
│   ├── service.yaml             # Kubernetes Service (LoadBalancer)
│   └── ingress.yaml             # AWS ALB Ingress (optional)
└── README.md                     # Project documentation
```

## 🚀 Quick Start

### Prerequisites

- **Local Development**: Docker, Python 3.9+
- **EKS Deployment**: AWS Account, EKS Cluster, kubectl, AWS CLI, ECR access

### Option 1: Run Locally (Python)

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py

# Test endpoints
curl http://localhost:5000/               # Home
curl http://localhost:5000/health         # Health check
curl http://localhost:5000/version        # Version info
```

### Option 2: Run Locally (Docker)

```bash
# Build Docker image
docker build -t simple-webserver:latest .

# Run container
docker run -p 5000:5000 simple-webserver:latest

# Test endpoints
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/version
```

### Option 3: Deploy to EKS

#### Step 1: Build and Push to AWS ECR

```bash
# Make the build script executable
chmod +x build-and-push.sh

# Run the build script
./build-and-push.sh us-east-1 simple-webserver latest

# Script will:
# - Get your AWS Account ID
# - Create ECR repository if it doesn't exist
# - Login to ECR
# - Build Docker image
# - Push to ECR
```

#### Step 2: Update Kubernetes Manifests

Update the image URI in `kubernetes/deployment.yaml`:

```yaml
image: <AWS_ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/simple-webserver:latest
```

#### Step 3: Deploy to EKS

```bash
# Ensure you're connected to your EKS cluster
kubectl cluster-info

# Deploy the application
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# (Optional) Deploy Ingress for ALB
kubectl apply -f kubernetes/ingress.yaml

# Verify deployment
kubectl get pods
kubectl get svc simple-webserver-service
```

## 🔍 Application Endpoints

| Endpoint | Method | Description | Response |
|----------|--------|-------------|-----------| 
| `/` | GET | Home endpoint | "Hello from Simple WebServer!" |
| `/health` | GET | Health check | `{"status": "healthy"}` |
| `/version` | GET | Version info | `{"version": "1.0.0"}` |

## 📊 Testing the Application

### Get Service Information

```bash
# Get the LoadBalancer external IP
kubectl get svc simple-webserver-service

# Wait for external IP to be assigned (may take 1-2 minutes)
kubectl get svc simple-webserver-service --watch
```

### Access the Application

```bash
# Using LoadBalancer external IP
EXTERNAL_IP=$(kubectl get svc simple-webserver-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl http://$EXTERNAL_IP/
curl http://$EXTERNAL_IP/health
curl http://$EXTERNAL_IP/version
```

### Access Logs

```bash
# View logs from a specific pod
kubectl logs <pod-name>

# Stream logs
kubectl logs <pod-name> -f

# View logs from all pods
kubectl logs -l app=simple-webserver --all-containers=true -f
```

## 🐳 Docker Image Details

- **Base Image**: `python:3.9-slim`
- **Size**: ~200MB (optimized with slim image)
- **Health Check**: HTTP GET to `/health` every 30 seconds
- **Exposed Port**: 5000
- **User**: Non-root user for security

## ⚙️ Kubernetes Configuration

### Deployment
- **Replicas**: 3
- **Resource Requests**:
  - CPU: 100m
  - Memory: 128Mi
- **Resource Limits**:
  - CPU: 500m
  - Memory: 256Mi
- **Health Checks**:
  - Liveness probe: TCP on port 5000
  - Readiness probe: HTTP GET on `/health`

### Service
- **Type**: LoadBalancer
- **Port**: 80
- **Target Port**: 5000
- **Protocol**: TCP

### Ingress (Optional)
- **Controller**: AWS ALB
- **Protocol**: HTTP/HTTPS
- **Health Check Path**: `/health`

## 🔐 Security Best Practices Implemented

✅ Non-root user in Docker container
✅ Read-only filesystem where applicable
✅ Resource limits and requests defined
✅ Health checks configured
✅ Minimal base image (python:3.9-slim)
✅ Security context in Kubernetes

## 🛠️ Customization

### Change Application Port

1. Update `app.py`: `app.run(host='0.0.0.0', port=YOUR_PORT)`
2. Update `Dockerfile`: `EXPOSE YOUR_PORT`
3. Update `kubernetes/deployment.yaml` and `kubernetes/service.yaml`

### Change Number of Replicas

Edit `kubernetes/deployment.yaml`:

```yaml
spec:
  replicas: 5  # Change from 3 to desired number
```

### Update Resource Limits

Edit `kubernetes/deployment.yaml`:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

## 📝 Environment Variables

Current configuration doesn't use environment variables, but you can add them:

1. Update `app.py` to read env variables
2. Add to `kubernetes/deployment.yaml`:

```yaml
env:
  - name: FLASK_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "INFO"
```

## 🐛 Troubleshooting

### Pods not starting?

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check deployment events
kubectl describe deployment simple-webserver-deployment

# View pod logs
kubectl logs <pod-name>
```

### Service not accessible?

```bash
# Verify service is created
kubectl get svc simple-webserver-service

# Check endpoints
kubectl get endpoints simple-webserver-service

# Test connectivity from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside the container:
# wget -O- http://simple-webserver-service/health
```

### ECR Push Failed?

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Verify ECR repository exists
aws ecr describe-repositories --region us-east-1

# Check Docker login
docker login -u AWS -p <password> <ECR-URL>
```

## 📚 Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## 📧 Support

For issues, questions, or suggestions, please open an issue in the GitHub repository.

---

**Last Updated**: 2026-07-14  
**Version**: 1.0.0  
**Maintainer**: Mani4646