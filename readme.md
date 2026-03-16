# Docker & Kubernetes Command Guide 🐳⚙️

A friendly, step-by-step guide for common Docker and Kubernetes commands. Perfect for building, deploying, and managing your containerized applications.

---

## 🧠 Introduction to the Kubernetes Cluster

Before we dive in, let's understand the big picture! When we talk about a Kubernetes "cluster," we're talking about a team of computers working together. This team has two main roles:

* **The Master Node 👑**: This is the brain of the cluster. We tell the master what we want our application to look like (our *desired state*), usually by giving it YAML files.
* **Worker Nodes 👷**: These are the machines that do the actual work of running our application containers.

![alt text](./Images/image-1.png)

The master's job is to make the cluster's *current state* match our *desired state*. It's always checking and re-checking in a "reconciliation loop." If a pod crashes, the master sees it and tells a worker to start a new one. It's a self-healing system!

![alt text](./Images/image-2.png)
![alt text](./Images/image-3.png)

---

## 🏗️ Step 1: Build & Push Your Docker Image

First, we need to package our application into a Docker image and push it to a registry so Kubernetes can access it.

**1. Build the Image**
This command builds the image from the `Dockerfile` in your current directory (`.`) and gives it a memorable name and version tag (`-t`).

```bash
docker build . -t brianstorti/hellok8s:v1
```

**2. Push the Image**
Next, upload your newly built image to a container registry like Docker Hub.

```bash
docker push brianstorti/hellok8s:v1
```

---

## 🚀 Step 2: Deploy to Kubernetes

Now let's get your application running on the Kubernetes cluster.

**Apply a Configuration**
This command tells Kubernetes to create or update resources from a configuration file.

```bash
# The output confirms the resource was created
# deployment.apps/hellok8s created
kubectl apply -f deployment.yaml
```

---

## 🔍 Step 3: Manage & Access Your Deployment

Your app is running! Here are some essential commands for interacting with it.

**List Resources**
Check the status of your resources. Use the `-w` flag to watch for changes in real-time.

```bash
# List all deployments
kubectl get deployments

# List all pods and watch for changes
kubectl get pods -w
```

**Inspect a Pod**
Get detailed information about a specific pod. This is super useful for debugging! You can see events, container status, IP addresses, and more.

![alt text](./Images/image-4.png)
![alt text](./Images/image-5.png)

```bash
kubectl describe pod <your-pod-name>
# Example: kubectl describe pod hellok8s-68f47f657c-zwn6g
```

**View Pod Logs** 📄
Stream the logs from a container within a pod. This is crucial for seeing what your app is doing or why it's failing.

```bash
kubectl logs --follow <your-pod-name>
# Example: kubectl logs --follow nginx
```

**Run Commands in a Container** 💻
Execute a command directly inside a running container. Use `-it` for an interactive shell session, which is like SSHing into your container.

```bash
# Run a single command
kubectl exec <your-pod-name> -- <command>
# Example: kubectl exec nginx -- ls /app

# Get an interactive shell inside the container
kubectl exec -it <your-pod-name> -- bash
```

**Port Forwarding** 🔌
Access your application on your local machine without exposing it to the internet. This is perfect for testing and development.

```bash
# Forward local port 3000 to pod's port 80
kubectl port-forward pod/<pod-name> 3000:80

# Allow remote access (from your network)
kubectl port-forward --address 0.0.0.0 pod/<pod-name> 3000:80
```

**Delete Resources** 🗑️
Remove resources from your cluster.

```bash
# Delete a specific pod by name
kubectl delete pod <your-pod-name>

# Delete all resources defined in a YAML file
kubectl delete -f nginx.yaml
```

---

## 🔄 Step 4: Update & Rollback Your Application

Time to release a new version! Here's how to manage updates and roll back if something goes wrong.

### Deployment Strategies

* **Rolling Update (Default)**: This strategy ensures zero downtime by gradually replacing old pods with new ones. For a moment, both v1 and v2 will be running together.
    * `maxSurge`: How many *extra* pods can be created during the update.
    * `maxUnavailable`: How many old pods can be *missing* during the update.
    ![alt text](./Images/image-6.png)

* **Recreate Strategy**: This strategy terminates all old pods *before* creating new ones. This causes a short downtime but guarantees that v1 and v2 never run at the same time.
    ```yaml
    # In your deployment.yaml
    spec:
      strategy:
        type: Recreate
    ```
    ![alt text](./Images/image-7.png)

### Rollback a Deployment
Did the new version introduce a bug? No problem! You can quickly revert to the previous stable version.

```bash
kubectl rollout undo deployment hellok8s
```

---

## ❤️ Step 5: Health Checks & Services

Let's make our application robust and accessible to the world.

### Health Checks: Liveness & Readiness Probes

Kubernetes can automatically check if your application is healthy and ready to receive traffic.

* **Readiness Probe ✅**: Prevents traffic from being sent to a pod until it's fully ready (e.g., a database connection is established). If the probe fails, Kubernetes just waits patiently.
    > *Probe failed: Readiness probe failed with statuscode: 500*
    ![alt text](./Images/image-8.png)

* **Liveness Probe 🩺**: Periodically checks if your application is still healthy. If the liveness probe fails, Kubernetes will restart the container, attempting to fix the issue automatically.

### Exposing Pods with a Service

A **Service** is a crucial Kubernetes resource that gives us a single, stable network endpoint for a group of pods. It sits in front of the pods and acts like a traffic cop, load balancing requests among all the healthy pods behind it.

![alt text](./Images/image.png)

You create a service using a YAML file, just like a deployment:
```bash
kubectl apply -f service.yaml
```

And you can check its status:
```bash
kubectl get service hellok8s-svc
```

Let's explore the different types of Services:

#### 1. ClusterIP (Default)
This is the most basic service type. It's used for **internal cluster communication only**.

![alt text](./Images/cluster-ip.png)

#### 2. NodePort
This service type is perfect for exposing your application to the **outside world** for development or testing. It opens a specific port on *all* worker nodes.

![alt text](./Images/nodePort.png)

#### 3. LoadBalancer
This is the most powerful and production-ready service type. It automatically provisions a **cloud load balancer**.

![alt text](./Images/loadbalancer.png)

#### 4. ExternalName
This service type is different. It acts as an alias for an **external service** by returning a `CNAME` record, making it easy to manage external dependencies.

![alt text](./Images/externalName.png)

### Service Discovery: How Pods Find Each Other

So we have a Service, but how does `app-a` actually find and talk to `app-b`? Kubernetes provides two main ways for this to happen.

#### DNS (The Recommended Way) 🌐
Kubernetes comes with a built-in DNS service that works out of the box. When you create a Service, it automatically gets a DNS entry. For example, if you create a service named `hellok8s-svc`, any other pod in the cluster can reliably reach it just by using its name: `http://hellok8s-svc:4567`.

#### Environment Variables (The Old Way) 📜
Another way services can be found is through environment variables. When Kubernetes starts a container, it automatically injects environment variables for every service that is *already running*.

You could see variables like `HELLOK8S_SVC_SERVICE_HOST` and `HELLOK8S_SVC_SERVICE_PORT`.

**Why isn't this recommended?**
There's a big catch: these variables are only created when the pod starts.
* If you create a new service *after* a pod is already running, that pod won't have the environment variables for the new service.
* If a service's IP address changes, the environment variables in existing pods **will not be updated**.

Because of these limitations, **DNS is the preferred and more reliable solution** for service discovery.

---

## 🛠️ Useful Tools

**Install `watch`** 👀
A fantastic tool for monitoring changes in real-time by running a command repeatedly.

```bash
# On macOS with Homebrew
brew install watch

# Example: Watch your pods every 2 seconds
watch -n 2 kubectl get pods
```

---

## 📝 Recap

Let's review the key concepts we've covered:

* **Pods are Ephemeral**: Pods can be created and destroyed at any time, so we should never rely on their IP addresses.
* **Services Provide Stability**: Services give us a stable, reliable endpoint (IP address and DNS name) to access our pods. The connection between a Service and its Pods is made using **labels** and **selectors**.
* **Service Types**:
    * **ClusterIP**: For internal communication inside the cluster only.
    * **NodePort**: Exposes the service on a port on each worker node, allowing external access for testing.
    * **LoadBalancer**: Creates a cloud load balancer for production-grade external access.
    * **ExternalName**: Creates a DNS alias to a service outside the cluster.
* **Service Discovery**:
    * **DNS (Recommended)**: The best way for pods to find services. Kubernetes automatically creates a DNS record like `my-service` that pods can use.
    * **Environment Variables**: An older method that is less reliable because variables are not updated after a pod star