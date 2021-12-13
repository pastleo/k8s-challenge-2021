k8s-challenge-2021
===

The DigitalOcean Kubernetes Challenge at 2021, [campaign page](https://www.digitalocean.com/community/pages/kubernetes-challenge)

### Which Challenge Attempting: ***Deploy a scalable SQL database cluster***

## Roadmap

* [x] build a Phoenix liveView demo project
* [x] create a Kubernetes Cluster in DigitalOcean
* [x] create a scalable database on Kubernetes
* [x] make Phoenix app scallable as well
* [x] wire everything up to production for demonstration
* [x] write up about the project
* [ ] submit a PR against [the DigitalOcean Kubernetes Challenge repo](https://github.com/do-community/kubernetes-challenge)
* [ ] [filling out this form](https://docs.google.com/forms/d/e/1FAIpQLSe-CT6ynhORAL04GqsvrvYn8d_6bUJuHUsMNFRG8L9mVxE1IA/viewform) to complete the challenge

---

## `PopKube` Application

This is an web application that counts clicks on logo of kubernetes from users, like [https://popcat.click/](https://popcat.click/):

### [https://popkube.pastleo.me](https://popkube.pastleo.me)

![PopKube screencast](https://i.imgur.com/FFBJHV5.gif)

This web application is built with [Phoenix -- Elixir web framework](https://www.phoenixframework.org/), using [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html), application project is located at [`pop_kube/`](https://github.com/pastleo/k8s-challenge-2021/tree/main/pop_kube)

`PopKube` docker image is built and published on dockerhub: [`chgu82837/phoenix-pop-kube`](https://hub.docker.com/r/chgu82837/phoenix-pop-kube)

> Phoenix comes with a nice generator to quickly setup release for docker: `mix phx.gen.release --docker`, which generates `Dockerfile` and so on. see [docs](https://hexdocs.pm/phoenix/releases.html#containers) for more info

## How I deploy `PopKube` to k8s

### 1. install required software on local machine

* [kubectl](https://kubernetes.io/docs/tasks/tools/): core commandline tool to control k8s
* [helm](https://helm.sh/): like npm for k8s that allow us to reuse community's work
* [LENS](https://k8slens.dev/): a GUI application to view/monitor k8s

> BTW, my local machine is ArchLinux,
>> [`kubectl`](https://archlinux.org/packages/community/x86_64/kubectl/) and [`helm`](https://archlinux.org/packages/community/x86_64/helm/) can be installed by [`pacman`](https://wiki.archlinux.org/title/pacman): `pacman -S kubectl helm`
>> LENS provides `Linux x64 (AppImage)` build, download from its website and use [`appimagelauncher`](https://github.com/TheAssassin/AppImageLauncher) ([AUR available](https://aur.archlinux.org/packages/appimagelauncher/)) to integrate into system

### 2. create a Kubernetes cluster on DigitalOcean

![](https://i.imgur.com/kRQ9LuA.png)

![](https://i.imgur.com/sV78oHS.png)

> I use `$15/month per node ($0.020/hour)` because this is for learning/testing purpose

![](https://i.imgur.com/pX7jePY.png)

### 3. connect to k8s cluster

![](https://i.imgur.com/aLdB1hU.png)

```bash
cd path/to/this/project
mv ~/Downloads/popkube-2021-k8s-challenge-kubeconfig.yaml ./
export KUBECONFIG=./popkube-2021-k8s-challenge-kubeconfig.yaml # . ./envrc
kubectl config get-contexts # do-sgp1-popkube-2021-k8s-challenge show up
kubectl get node # 3 nodes show up
```

#### for LENS:

![](https://i.imgur.com/ZaWl6dI.png)

paste content of `popkube-2021-k8s-challenge-kubeconfig.yaml` and `Add cluster`, then `add to Hotbar`:

![](https://i.imgur.com/eaXQhTK.png)

Click into Cluster > Nodes, should see 3 nodes:

![](https://i.imgur.com/fsT7LCq.png)

#### To see metrics on LENS:

![](https://i.imgur.com/H0Ef0lU.png)

![](https://i.imgur.com/xc8jj1l.png)

This will install extensions on "k8s cluster" to have better integration with LENS:

![](https://i.imgur.com/mW0M7y8.png)

### 4. Setup a stateless webapp as `hello world` service

> from https://kubernetes.io/docs/tasks/run-application/run-stateless-application-deployment/

```yaml
# main-app.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: main-app-deployment
spec:
  selector:
    matchLabels:
      app: main-app
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: main-app
    spec:
      containers:
      - name: main-app-nginx # as stateless application
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f main-app.yml
```

then 2 `main-app-deployment` should show up on LENS:

![](https://i.imgur.com/UTP4SUz.png)

```yaml
# main-app-svc.yml
apiVersion: v1
kind: Service
metadata:
  name: main-app-svc
spec:
  selector:
    app: main-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

```bash
kubectl apply -f main-app-svc.yml
```

![](https://i.imgur.com/hvtCGKQ.png)

![](https://i.imgur.com/iIF2TfA.png)

![](https://i.imgur.com/0Wr4enb.png)

this means our hello world service is working, just not publicly exposed, this `port forwarding` can be deleted

### 5. setup ingress: http://popkube.pastleo.me => `main-app-svc`

> from Step 2 of https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true
```

```yaml
# main-app-ingress.yml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: main-app-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: "popkube.pastleo.me"
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: main-app-svc
            port:
              number: 80
```

```bash
kubectl apply -f main-app-ingress.yml
```

![](https://i.imgur.com/kQ9eBQy.png)

`139.59.193.116` is the load balancer external IP, create a DNS record (using Cloudflare):

![](https://i.imgur.com/fIwyHCD.png)

now http://popkube.pastleo.me/ is publicly accessible:

![](https://i.imgur.com/qb6omsD.png)

### 6. setup secret generator

> from https://github.com/mittwald/kubernetes-secret-generator

```bash
helm repo add mittwald https://helm.mittwald.de
helm repo update
helm upgrade --install kubernetes-secret-generator mittwald/kubernetes-secret-generator
```

![](https://i.imgur.com/7pWe7M3.png)

### 7. setup scalable SQL database -- postgresql

> from https://www.kubegres.io/doc/getting-started.html

```bash
kubectl apply -f https://raw.githubusercontent.com/reactive-tech/kubegres/v1.14/kubegres.yaml
```

![](https://i.imgur.com/Fjd7aXT.png)

```yaml
# main-postgres-secrets.yml
apiVersion: v1
kind: Secret
metadata:
  name: main-postgres-super-secret
  annotations:
    secret-generator.v1.mittwald.de/autogenerate: password
data: {}
---
apiVersion: v1
kind: Secret
metadata:
  name: main-postgres-replication-secret
  annotations:
    secret-generator.v1.mittwald.de/autogenerate: password
data: {}
```

```bash
kubectl apply -f main-postgres-secrets.yml
```

![](https://i.imgur.com/yHCVtwz.png)

```yaml
# main-postgres.yml
apiVersion: kubegres.reactive-tech.io/v1
kind: Kubegres
metadata:
  name: main-postgres
spec:
  replicas: 3
  image: postgres:14.1
  database:
    size: 1Gi # volume size is claimed by Gi in digital ocean 
  env:
    - name: POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: main-postgres-super-secret
          key: password
    - name: POSTGRES_REPLICATION_PASSWORD
      valueFrom:
        secretKeyRef:
          name: main-postgres-replication-secret
          key: password
```

```bash
kubectl apply -f main-postgres.yml
```

![](https://i.imgur.com/4sOnuRz.png)

![](https://i.imgur.com/lTmWUVW.png)

![](https://i.imgur.com/80TZIeU.png)

### 8. setup app database

```yaml
# main-app-secrets.yml
apiVersion: v1
kind: Secret
metadata:
  name: main-postgres-app-secret
  annotations:
    secret-generator.v1.mittwald.de/autogenerate: password
    secret-generator.v1.mittwald.de/encoding: base64url # prevent slash breaking DATABASE_URL
data: {}
```

```bash
kubectl apply -f main-app-secrets.yml
```

we will be needing raw password of `main-postgres-super-secret` and `main-postgres-app-secret`, which can be copied from:

![](https://i.imgur.com/0AJv4AS.png)

then create a `port forwarding` to postgres service:

![](https://i.imgur.com/1D3rrBw.png)

![](https://i.imgur.com/hNng3gN.png)

which means port forwarding is created on `46019`, use `psql` to connect to postgres:

```bash
psql -h localhost -U postgres -p 46019
```

password will be asked, use the value copied from `main-postgres-super-secret`.

after login into postgres, create user and database for app:

```sql
CREATE USER app WITH PASSWORD 'value-copied-from-main-postgres-app-secret';
CREATE DATABASE pop_kube_prod OWNER app;
\l
# should see a database with name: pop_kube_prod, owner: app
\q
```

### 9. setup `PopKube` app shell for tasks like migration

```diff
--- a/main-app-secrets.yml
+++ b/main-app-secrets.yml
@@ -5,3 +5,11 @@ metadata:
   annotations:
     secret-generator.v1.mittwald.de/autogenerate: password
     secret-generator.v1.mittwald.de/encoding: base64url # prevent slash breaking DATABASE_URL
 data: {}
+---
+apiVersion: v1
+kind: Secret
+metadata:
+  name: main-app-key-base-secret
+  annotations:
+    secret-generator.v1.mittwald.de/autogenerate: password
+    secret-generator.v1.mittwald.de/length: "64" # phoenix require SECRET_KEY_BASE to to be at least 64 bytes
+data: {}
```

```bash
kubectl apply -f main-app-secrets.yml
```

> from https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/

```yaml
# main-app-shell.yml
apiVersion: v1
kind: Pod
metadata:
  name: main-app-shell
spec:
  containers:
  - name: phoenix-pop-kube-shell
    image: chgu82837/phoenix-pop-kube:0.1.1
    command: ["tail", "-f", "/dev/null"]
    env:
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: main-postgres-app-secret
          key: password
    - name: DATABASE_URL
      value: "postgres://app:$(DATABASE_PASSWORD)@main-postgres.default.svc.cluster.local/pop_kube_prod"
    - name: SECRET_KEY_BASE
      valueFrom:
        secretKeyRef:
          name: main-app-key-base-secret
          key: password
```

```bash
kubectl apply -f main-app-shell.yml
kubectl exec --stdin --tty main-app-shell -- /bin/bash

# inside container:
./bin/migrate # ...create table clicks...Migrated 20211211145654 in 0.0s
exit
```

### 10. setup `PopKube` webapp

```diff
--- a/main-app-svc.yml
+++ b/main-app-svc.yml
@@ -8,4 +8,4 @@ spec:
   ports:
     - protocol: TCP
       port: 80
-      targetPort: 80
+      targetPort: 4000
--- a/main-app.yml
+++ b/main-app.yml
@@ -13,7 +13,28 @@ spec:
         app: main-app
     spec:
       containers:
-      - name: main-app-nginx # as stateless application
-        image: nginx:latest
-        ports:
-        - containerPort: 80
+      #- name: main-app-nginx # as stateless application
+        #image: nginx:latest
+        #ports:
+        #- containerPort: 80
+      - name: phoenix-pop-kube
+        image: chgu82837/phoenix-pop-kube:0.1.1
+        ports:
+        - containerPort: 4000
+        env:
+        - name: PHX_HOST
+          value: "popkube.pastleo.me"
+        - name: PORT
+          value: "4000"
+        - name: DATABASE_PASSWORD
+          valueFrom:
+            secretKeyRef:
+              name: main-postgres-app-secret
+              key: password
+        - name: DATABASE_URL
+          value: "postgres://app:$(DATABASE_PASSWORD)@main-postgres.default.svc.cluster.local/pop_kube_prod"
+        - name: SECRET_KEY_BASE
+          valueFrom:
+            secretKeyRef:
+              name: main-app-key-base-secret
+              key: password
```

```bash
kubectl apply -f main-app.yml
kubectl apply -f main-app-svc.yml
```

![](https://i.imgur.com/sZCha2w.png)

![](https://i.imgur.com/r9LPSoy.png)

Now `main-app` is running `PopKube`! let's create first few clicks:

![](https://i.imgur.com/U5heV9u.gif)

### 11. setup https using Letsencrypt

> from https://cert-manager.io/docs/installation/helm/

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.6.1 --set installCRDs=true
```

![](https://i.imgur.com/KozWoFo.png)

```yaml
# main-letsencrypt-issuer.yml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: main-letsencrypt-issuer
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: user@example.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: main-letsencrypt-secret
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
```

```bash
kubectl apply -f main-letsencrypt-issuer.yml
```

![](https://i.imgur.com/J78HuXf.png)

```diff
--- a/main-app-ingress.yml
+++ b/main-app-ingress.yml
@@ -4,6 +4,9 @@ metadata:
   name: main-app-ingress
   annotations:
     kubernetes.io/ingress.class: nginx
+
+    # https:
+    cert-manager.io/cluster-issuer: main-letsencrypt-issuer
 spec:
   rules:
   - host: "popkube.pastleo.me"
@@ -16,3 +19,9 @@ spec:
             name: main-app-svc
             port:
               number: 80
+
+  # https:
+  tls:
+  - hosts:
+    - popkube.pastleo.me
+    secretName: main-letsencrypt-secret-popkube.pastleo.me
```

```bash
kubectl apply -f main-app-ingress.yml
```

![](https://i.imgur.com/oFqHuvd.png)

Go back to http://popkube.pastleo.me and refresh, here we have secure website:

![](https://i.imgur.com/x7c8t1F.png)

That's it! a complete scalable SQL database and scalable webapp is deployed at:

### https://popkube.pastleo.me/

## Clicks syncing with [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)

despite inserting a click into database, one click will be immediately broadcasted to connected users within the same `PopKube` web server only. in the following screencast we can see left 2 windows are accessing the same web server while the other is not:

![](https://i.imgur.com/PM1NVrX.gif)
