# Kubernetes Horizontal Pod Autoscaler (HPA) Project

## 📋 Deskripsi Project

Project ini merupakan implementasi **Horizontal Pod Autoscaler (HPA)** pada Kubernetes untuk aplikasi nginx. HPA akan secara otomatis melakukan scaling pod berdasarkan penggunaan memory dengan threshold 75%.

## 🏗️ Struktur Project

```
homework-15/
├── manifests/              # Kubernetes manifest files
│   ├── deployment.yaml     # Nginx deployment configuration
│   ├── hpa.yaml           # Horizontal Pod Autoscaler configuration
│   ├── service.yaml       # Service untuk expose nginx
│   └── load-test.yaml     # Load testing pods
├── scripts/               # Automation scripts
│   ├── deploy.sh         # Script untuk deployment
│   └── cleanup.sh        # Script untuk cleanup
└── README.md             # Dokumentasi project
```

## 🎯 Requirements

Project ini memenuhi requirements berikut:

### 1. Deployment Requirements
- ✅ Menggunakan image nginx
- ✅ Konfigurasi resource requests dan limits untuk memory
- ✅ Minimal 2 pod

### 2. HPA Requirements
- ✅ Minimum replica: 2
- ✅ Maximum replica: 5
- ✅ Target resource: memory utilization
- ✅ Target threshold: 75%

## 📁 Penjelasan File Manifest

### 1. deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 2  # Minimal 2 pod sesuai requirement
```

**Penjelasan setiap bagian:**

- **apiVersion: apps/v1**: Menggunakan API version apps/v1 untuk Deployment
- **kind: Deployment**: Mendefinisikan resource type sebagai Deployment
- **metadata.name**: Nama deployment adalah "nginx-deployment"
- **metadata.labels**: Label untuk identifikasi resource
- **spec.replicas: 2**: Jumlah pod awal adalah 2 (sesuai requirement minimum)

```yaml
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
```

- **selector.matchLabels**: Selector untuk menentukan pod mana yang dikelola deployment
- **template.metadata.labels**: Label yang akan diberikan ke setiap pod

```yaml
    spec:
      containers:
      - name: nginx
        image: nginx:latest  # Menggunakan image nginx
        ports:
        - containerPort: 80
```

- **containers.name**: Nama container adalah "nginx"
- **containers.image**: Menggunakan image nginx:latest sesuai requirement
- **containers.ports**: Expose port 80 untuk HTTP traffic

```yaml
        resources:
          requests:
            memory: "64Mi"   # Memory request untuk HPA calculation
            cpu: "250m"      # CPU request untuk stabilitas
          limits:
            memory: "128Mi"  # Memory limit untuk mencegah overconsumption
            cpu: "500m"      # CPU limit untuk mencegah overconsumption
```

- **resources.requests.memory**: Memory yang diminta pod (64Mi) - **PENTING untuk HPA**
- **resources.requests.cpu**: CPU yang diminta pod (250m)
- **resources.limits.memory**: Batas maksimal memory (128Mi)
- **resources.limits.cpu**: Batas maksimal CPU (500m)

```yaml
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

- **livenessProbe**: Health check untuk memastikan container masih hidup
- **readinessProbe**: Health check untuk memastikan container siap menerima traffic

### 2. hpa.yaml

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
```

- **apiVersion: autoscaling/v2**: Menggunakan HPA API version v2 (terbaru)
- **kind: HorizontalPodAutoscaler**: Resource type HPA

```yaml
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx-deployment  # Target deployment yang akan di-scale
```

- **scaleTargetRef**: Menentukan target resource yang akan di-scale (nginx-deployment)

```yaml
  minReplicas: 2            # Minimum replica sesuai requirement
  maxReplicas: 5            # Maximum replica sesuai requirement
```

- **minReplicas: 2**: Jumlah minimum pod (sesuai requirement)
- **maxReplicas: 5**: Jumlah maksimum pod (sesuai requirement)

```yaml
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 75  # Target threshold 75% memory usage
```

- **metrics.type: Resource**: Menggunakan resource metrics (memory/CPU)
- **resource.name: memory**: Metric yang digunakan adalah memory
- **target.averageUtilization: 75**: Target threshold 75% sesuai requirement

```yaml
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Tunggu 5 menit sebelum scale down
      policies:
      - type: Percent
        value: 50             # Scale down maksimal 50% dari current replicas
        periodSeconds: 60     # Dalam periode 1 menit
```

- **behavior.scaleDown**: Mengatur perilaku saat scale down
- **stabilizationWindowSeconds: 300**: Tunggu 5 menit untuk stabilisasi sebelum scale down
- **policies**: Aturan scaling (maksimal 50% dalam 1 menit)

### 3. service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx          # Selector untuk mengarahkan traffic ke pods dengan label app: nginx
  ports:
  - name: http
    port: 80            # Port yang akan diekspos oleh service
    targetPort: 80      # Port di container yang akan menerima traffic
  type: ClusterIP       # Service type ClusterIP untuk akses internal cluster
```

- **Service ClusterIP**: Untuk akses internal dalam cluster
- **Service NodePort**: Untuk akses eksternal (testing purposes)

## 🔍 Penjelasan Detail HPA

### Apa itu Horizontal Pod Autoscaler (HPA)?

**Horizontal Pod Autoscaler (HPA)** adalah fitur Kubernetes yang secara otomatis melakukan scaling jumlah pod dalam deployment, replica set, atau stateful set berdasarkan penggunaan resource (CPU, memory) atau custom metrics.

**Fungsi dan Kegunaan:**
- **Otomatisasi Scaling**: Menambah atau mengurangi pod secara otomatis
- **Optimasi Resource**: Menggunakan resource cluster secara efisien
- **High Availability**: Memastikan aplikasi dapat menangani beban yang berubah-ubah
- **Cost Optimization**: Mengurangi biaya dengan scaling down saat beban rendah

### Cara Kerja HPA Berdasarkan Memory Metric

1. **Monitoring**: HPA secara berkala (default 15 detik) mengecek penggunaan memory dari semua pod
2. **Calculation**: Menghitung rata-rata penggunaan memory dari semua pod
3. **Decision**: Membandingkan dengan target threshold (75%)
4. **Action**: 
   - Jika > 75%: Scale up (tambah pod)
   - Jika < 75%: Scale down (kurangi pod)
5. **Stabilization**: Menunggu periode stabilisasi sebelum scaling berikutnya

**Formula Calculation:**
```
desiredReplicas = ceil[currentReplicas * (currentMetricValue / desiredMetricValue)]
```

### Pentingnya Resource Requests dan Limits

#### Resource Requests
- **Untuk HPA**: HPA menggunakan `resources.requests` sebagai baseline untuk menghitung persentase penggunaan
- **Untuk Scheduler**: Kubernetes scheduler menggunakan requests untuk menentukan node placement
- **Contoh**: Jika request memory 64Mi dan usage 48Mi, maka utilization = 48/64 = 75%

#### Resource Limits
- **Untuk Container**: Mencegah container menggunakan resource berlebihan
- **Untuk Node**: Melindungi node dari resource exhaustion
- **Untuk Stability**: Mencegah OOMKilled dan crash

### Skenario Scaling

#### Ketika Memory Usage > 75%
1. HPA mendeteksi penggunaan memory di atas threshold
2. Menghitung jumlah replica yang dibutuhkan
3. Melakukan scale up (menambah pod)
4. Menunggu stabilization window sebelum scaling berikutnya
5. Load terdistribusi ke pod baru
6. Memory usage per pod menurun

#### Ketika Memory Usage < 75%
1. HPA mendeteksi penggunaan memory di bawah threshold
2. Menunggu stabilization window (5 menit untuk scale down)
3. Melakukan scale down (mengurangi pod)
4. Load terdistribusi ke pod yang tersisa
5. Memastikan tidak kurang dari minReplicas (2)

### Contoh Kasus Nyata

#### E-commerce Website
**Skenario**: Website e-commerce dengan traffic yang berfluktuasi

**Normal Hours (08:00-17:00)**:
- Traffic rendah: 100 concurrent users
- Memory usage: 40% per pod
- HPA maintains: 2 pods (minimum)

**Peak Hours (18:00-22:00)**:
- Traffic tinggi: 1000 concurrent users
- Memory usage: 85% per pod
- HPA scales up: 2 → 3 → 4 → 5 pods
- Memory usage turun: 85% → 68% → 51% → 40%

**Late Night (23:00-07:00)**:
- Traffic sangat rendah: 20 concurrent users
- Memory usage: 20% per pod
- HPA scales down: 5 → 4 → 3 → 2 pods (minimum)

**Benefits**:
- **Cost Savings**: 60% pengurangan biaya di off-peak hours
- **Performance**: Response time tetap optimal di peak hours
- **Reliability**: Tidak ada downtime karena overload

## 🚀 Cara Menjalankan Project

### Prerequisites

1. **Kubernetes Cluster** yang sudah running
2. **kubectl** sudah terinstall dan terkonfigurasi
3. **Metrics Server** sudah terinstall di cluster

```bash
# Install metrics server jika belum ada
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Step-by-Step Deployment

#### 1. Clone/Download Project
```bash
git clone https://github.com/mdafaardiansyah/ds-hw14-kubernetes-2-hpa
```

#### 2. Deploy menggunakan Script
```bash
# Jalankan script deployment
./scripts/deploy.sh
```

#### 3. Manual Deployment (Alternative)
```bash
# Deploy deployment
kubectl apply -f manifests/deployment.yaml

# Deploy service
kubectl apply -f manifests/service.yaml

# Deploy HPA
kubectl apply -f manifests/hpa.yaml
```

### 🧪 Testing HPA

#### 1. Monitor HPA Status
```bash
# Monitor HPA secara real-time
kubectl get hpa -w

# Lihat detail HPA
kubectl describe hpa nginx-hpa
```

#### 2. Load Testing
```bash
# Deploy load test pod
kubectl apply -f manifests/load-test.yaml

# Monitor pods
kubectl get pods -w
```

#### 3. Manual Load Testing
```bash
# Akses nginx untuk generate traffic
kubectl port-forward service/nginx-service 8080:80

# Di terminal lain, generate load
for i in {1..1000}; do curl http://localhost:8080; done
```

### 📊 Monitoring Commands

```bash
# Lihat status semua resources
kubectl get all

# Monitor HPA
kubectl get hpa nginx-hpa -w

# Lihat metrics pods
kubectl top pods

# Lihat logs deployment
kubectl logs -f deployment/nginx-deployment

# Describe HPA untuk troubleshooting
kubectl describe hpa nginx-hpa
```

### 🧹 Cleanup

```bash
# Menggunakan script cleanup
./scripts/cleanup.sh

# Atau manual
kubectl delete -f manifests/
```

## 🔧 Troubleshooting

### HPA Tidak Berfungsi

1. **Check Metrics Server**
```bash
kubectl get deployment metrics-server -n kube-system
```

2. **Check Resource Requests**
```bash
kubectl describe deployment nginx-deployment
```

3. **Check HPA Events**
```bash
kubectl describe hpa nginx-hpa
```

### Pod Tidak Scaling

1. **Check Current Metrics**
```bash
kubectl top pods
```

2. **Check HPA Status**
```bash
kubectl get hpa nginx-hpa -o yaml
```

## 📚 Referensi

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

## 👥 Author

**Muhammad Dafa Ardiansyah - Digital Skola DevOps Engineer Batch 7**
- Project: Homework 15 - Kubernetes HPA
