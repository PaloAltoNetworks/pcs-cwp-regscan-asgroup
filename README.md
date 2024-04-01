# Registry Scanning Auto Scaling Group
Auto Scaling group deployment for scanning container registries using Prisma Cloud Container Defender

## Purpose
For many enterprises, scanning huge image registries with Prisma Cloud defenders using a single linux instance or a kubernetes node group can take a long time, be resource inefficient, expensive in cloud costs, and other deficiencies. The setup proposed is meant to improve the way that registries are being scanned and reduce most of the deficiencies that the previously mentioned methods have.


## Advantages 
Compared with the Kubernetes node group with autoscaling, the Auto Scaling Group has the following advantages:
* **Easier to patch**: You can patch the host for vulnerabilities and compliance issues without worrying that something might break the running applications.
* **More resource efficient**: The defender used in the host can consume almost all memory of the host itself.
* **No VM tags needed**: You can use a host naming convention of your choice.
* **Dedicated resource**: No need to monitor all other containers that come by default in the kubernetes cluster or any container that you have deployed already in the cluster and also the entire kubernetes network which in this case also translates to resource efficiency.
* **Faster instance creation**: it takes a lot less time to create an EC2 instance in an EC2 Auto Scaling group than in a kubernetes node group because it's not needed to install all the packages of kubernetes and add the instance to the cluster.
* **Cost Reduction**: The instances deployed can be spot instances and since is more resource efficient then the nodes can have lower specs.