# 🎃 Global Pumpkin Insurance - Platform Foundation

![Network Diagram](./assets/network-diagram.png)

## 🛡️ Architectural Decisions & Security Posture
Operating in a **regulated financial environment**, this infrastructure prioritizes the **"Zero Trust"** principle and the **Principle of Least Privilege (PoLP)**.

### 1. Network Isolation ("Data Vault" Approach)
* **Private-First EKS:** The EKS Worker Nodes are located in strictly private subnets. They have no public IP addresses and cannot be reached from the internet.
* **Controlled Egress:** Outbound traffic (for image pulls and security patches) is routed through a **NAT Gateway**, providing a single, auditable exit point.
* **No Public LoadBalancer:** To protect sensitive financial data, the Web API is not exposed to the public internet. Access is restricted to the internal network via `ClusterIP`.

### 2. Identity & Access Management (IAM)
* **Fine-Grained Roles:** Separate IAM roles were created for the Cluster Control Plane and the Node Groups, ensuring nodes only have the permissions necessary to pull images and manage networking.
* **Namespace Isolation:** The application is deployed into a dedicated `application` namespace to prevent "noisy neighbor" effects and allow for future NetworkPolicies.

### 3. Operational Readiness (The "Reproducibility" Factor)
* **Modular Terraform:** Infrastructure is split into reusable modules (`networking`, `eks`). This allows the same audited code to be used for `dev`, `staging`, and `prod` with zero drift.
* **Helm Overrides:** Deployment logic is separated from environment configuration. `values-dev.yaml` optimizes for cost (t3.mediums), while `values-prod.yaml` is architected for High Availability (HA).

---

## 🌍 Cloud Portability: AWS to Azure (AKS) Translation
As part of the design for a global company, the stack is designed to be provider-agnostic.

| Component | AWS Implementation | Azure (AKS) Equivalent |
| :--- | :--- | :--- |
| **Orchestrator** | EKS (Elastic Kubernetes Service) | AKS (Azure Kubernetes Service) |
| **Node Scaling** | Managed Node Groups (ASG) | AKS Node Pools (VMSS) |
| **Networking** | VPC with Private Subnets | VNet with Subnet Isolation |
| **Egress** | NAT Gateway + Elastic IP | Azure NAT Gateway |
| **Identity** | IAM Roles for Service Accounts | Azure Workload Identity |

---

## 🚀 Deployment & Verification

### Prerequisites
* Terraform >= 1.5.0
* Kubectl & Helm

### Step 1: Provision Infrastructure
```bash
cd terraform/environments/dev
terraform init
terraform apply
```

### Step 2: Deploy the Application via Helm

Since infrastructure lifecycle (Terraform) and application lifecycle (Helm) are decoupled to minimize the blast radius, the application is deployed independently.

First, update your local kubeconfig to connect to the cluster:
```bash
aws eks --region eu-central-1 update-kubeconfig --name dev-pumpkin-cluster
```

Deploy the application using the environment-specific values:

1) For Development

```Bash
helm upgrade --install pumpkin-app ./helm/pumpkin-app \
  --namespace application \
  --create-namespace \
  -f ./helm/pumpkin-app/values-dev.yaml
  ```

2) For Production

```Bash
helm upgrade --install pumpkin-app ./helm/pumpkin-app \
  --namespace application \
  --create-namespace \
  -f ./helm/pumpkin-app/values-prod.yaml
  ```

# 🛠️ Production Readiness & Future Improvements (Out of Scope for 3h Timebox)

To transition this platform foundation into a fully hardened, production-ready DevSecOps setup, the following architectural enhancements are required:

1. Identity & Least Privilege (IRSA): Currently, K8s workloads inherit the IAM role of the underlying EC2 worker node. For production, I would implement an OIDC provider and IAM Roles for Service Accounts (IRSA) to grant AWS permissions granularly at the Pod level.

2. Secrets Management: EKS etcd encryption is omitted to simplify the MVP. In a real financial environment, Kubernetes secret encryption via AWS KMS is mandatory. Furthermore, I would use the External Secrets Operator to fetch application secrets dynamically from AWS Secrets Manager.

3. High Availability vs. Cost (Networking): The production environment spans 3 Availability Zones, but currently routes egress traffic through a single NAT Gateway to optimize AWS costs for this challenge. A true production setup would provision one NAT Gateway per AZ to prevent a single point of failure.

4. Continuous Deployment (GitOps): While Terraform provisions the cluster infrastructure, application deployments via Helm should ideally be handled by a GitOps controller like ArgoCD or Flux in the target architecture, rather than executing Helm directly from local machines or standard CI pipelines.

5. Observability: Basic Readiness and Liveness probes are configured. Day-2 operations require deploying a logging stack (e.g., Fluent Bit) and monitoring (Prometheus/Grafana) to gain visibility into the cluster.