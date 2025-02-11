# Research on GPU Slicing for Cost Optimization in EKS Clusters

## Introduction
GPU slicing is a technique that allows a single physical GPU to be partitioned into multiple smaller virtual GPUs (vGPUs). This enables multiple workloads to share the same GPU, improving resource utilization and reducing costs, especially for GPU-intensive AI workloads. For clients running such workloads on Amazon Elastic Kubernetes Service (EKS), enabling GPU slicing can significantly optimize cost efficiency.

This research explores how to enable GPU slicing on EKS clusters, including those using the Karpenter autoscaler. The focus is on leveraging the NVIDIA GPU Operator for node configuration and GPU resource management.

## Key Concepts

### GPU Slicing
- GPU slicing divides a physical GPU into smaller virtual GPUs, allowing multiple workloads to share the same GPU.
- This is particularly useful for workloads that do not require the full capacity of a GPU, enabling better resource utilization and cost savings.

### NVIDIA GPU Operator
- The NVIDIA GPU Operator simplifies the management of GPU resources in Kubernetes clusters.
- It automates the deployment of NVIDIA drivers, Kubernetes device plugins, and other components required for GPU workloads.
- The operator supports GPU slicing through the NVIDIA Multi-Instance GPU (MIG) feature, which is available on NVIDIA A100 and newer GPUs.

### Karpenter Autoscaler
- Karpenter is a Kubernetes autoscaler that dynamically provisions nodes based on workload requirements.
- It can be configured to provision GPU-enabled nodes and support GPU slicing.

## Enabling GPU Slicing on EKS Clusters

### Prerequisites
- An EKS cluster running Kubernetes version 1.20 or later.
- NVIDIA GPUs that support MIG (e.g., A100, A30).
- Helm installed for deploying the NVIDIA GPU Operator.
- Karpenter installed (if using Karpenter for autoscaling).

### Step 1: Install the NVIDIA GPU Operator
The NVIDIA GPU Operator automates the deployment of GPU-related components in the EKS cluster.

#### Add the NVIDIA Helm repository:
```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
```

#### Install the GPU Operator:
```bash
helm install --wait --generate-name \
  -n gpu-operator --create-namespace \
  nvidia/gpu-operator
```

#### Verify the installation:
```bash
kubectl get pods -n gpu-operator
```

### Step 2: Configure GPU Slicing with MIG
To enable GPU slicing, configure the NVIDIA GPU Operator to use MIG.

#### Create a `values.yaml` file for the GPU Operator configuration:
```yaml
mig:
  strategy: mixed
```

#### Upgrade the GPU Operator with the new configuration:
```bash
helm upgrade gpu-operator nvidia/gpu-operator -f values.yaml
```

#### Verify that MIG is enabled on GPU nodes:
```bash
kubectl describe node <gpu-node-name> | grep nvidia.com/mig.strategy
```

### Step 3: Configure Karpenter for GPU Slicing
If the EKS cluster uses Karpenter for autoscaling, configure Karpenter to provision GPU-enabled nodes with MIG support.

#### Create a Karpenter provisioner configuration for GPU nodes:
```yaml
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: gpu-provisioner
spec:
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["on-demand", "spot"]
    - key: "topology.kubernetes.io/zone"
      operator: In
      values: ["us-east-1a", "us-east-1b", "us-east-1c"]
    - key: karpenter.k8s.aws/instance-category
      operator: In
      values:
        - g
        - p
    - key: "node.kubernetes.io/instance-type"
      operator: In
      values:
        - p4d.24xlarge  # Example instance type with NVIDIA A100 GPUs
  ttlSecondsAfterEmpty: 300
```

#### Add labels and taints to the provisioner for GPU workloads:
```yaml
spec:
  labels:
    nvidia.com/gpu.present: "true"
  taints:
    - key: "nvidia.com/gpu"
      effect: "NoSchedule"
```

#### Apply the provisioner configuration:
```bash
kubectl apply -f gpu-provisioner.yaml
```

### Step 4: Deploy GPU Workloads with GPU Slicing
Deploy workloads that request fractional GPU resources using MIG.

#### Example Pod specification requesting a fraction of a GPU:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-slice-pod
spec:
  containers:
    - name: gpu-container
      image: nvidia/cuda:11.0-base
      resources:
        limits:
          nvidia.com/gpu: 1  # Request 1 vGPU
  nodeSelector:
    nvidia.com/gpu.present: "true"
```

#### Apply the Pod specification:
```bash
kubectl apply -f gpu-slice-pod.yaml
```

## Benefits of GPU Slicing on EKS
- **Cost Efficiency:** By sharing GPUs across multiple workloads, clients can reduce the number of GPUs required, lowering infrastructure costs.
- **Improved Resource Utilization:** GPU slicing ensures that GPU resources are fully utilized, avoiding underutilization.
- **Scalability:** Karpenter dynamically provisions GPU-enabled nodes, ensuring that workloads have access to the required resources.

## Limitations and Considerations
- **GPU Compatibility:** GPU slicing requires NVIDIA GPUs that support MIG (e.g., A100, A30).
- **Workload Requirements:** Not all workloads are suitable for GPU slicing. Workloads with high GPU utilization may require dedicated GPUs.
- **Karpenter Configuration:** Ensure that Karpenter is configured to provision GPU-enabled nodes with the correct instance types and labels.

## Conclusion
Enabling GPU slicing on EKS clusters using the NVIDIA GPU Operator and Karpenter autoscaler is a feasible and effective way to optimize cost efficiency for GPU-intensive AI workloads. By following the steps outlined above, clients can leverage GPU slicing to reduce costs while maintaining performance and scalability.

For further optimization, clients should monitor GPU utilization and adjust MIG configurations as needed to balance cost and performance.

