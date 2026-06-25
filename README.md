# 🚀 EKS Cluster via Terraform — Projet ESGI 5ASRCB

> Projet académique réalisé dans le cadre du cursus Master Ingénierie des Systèmes, Réseaux & Cloud Computing (ESGI 5ASRCB).
> Déploiement d'un cluster Amazon EKS complet sur AWS, 100 % codé à la main en Terraform.

---

## 📐 Architecture déployée

```
Internet
    │
    ▼
Internet Gateway
    │
    ├──────────────────────────────────┐
    ▼                                  ▼
Application Load Balancer         NAT Gateway
  (subnets publics ×3 AZ)          (subnets publics)
    │                                  │
    ▼                                  ▼
EC2 Bastion (AL2023, t3.micro)   Subnets privés ×3 AZ
  (subnet public AZ-a)                 │
                                       ├── EKS Control Plane
                                       │     Addons : vpc-cni · coredns · kube-proxy
                                       └── EKS Node Group (t3.micro ×1-3)
```

Le schéma complet se trouve dans `docs/architecture.svg`.

---

## 📁 Structure du projet

```
eks-terraform-5asrcb/
├── main.tf              # Provider AWS + appel du module core-compute
├── variables.tf         # Toutes les variables avec description et défauts
├── iam.tf               # Rôles IAM pour EKS cluster + node group
├── eks.tf               # Cluster EKS, node group, addons obligatoires
├── alb.tf               # Application Load Balancer, target group, listener
├── outputs.tf           # Outputs utiles (IP EC2, endpoint EKS, DNS ALB…)
│
└── modules/
    └── core-compute/    # Module local requis par le sujet
        ├── main.tf      # Commentaire de présentation du module
        ├── variables.tf # Variables du module (project_name, vpc_cidr…)
        ├── data.tf      # Data sources : AMI AL2023 + AZs disponibles
        ├── vpc.tf       # VPC + IGW + route table publique
        ├── subnets_public.tf   # 3 subnets publics (map_public_ip, tags EKS)
        ├── subnets_private.tf  # 3 subnets privés + NAT GW + EIP
        ├── sg.tf        # Security groups EC2 et EKS
        ├── ec2.tf       # Instance EC2 Amazon Linux 2023
        ├── user_data.sh # Bootstrap Apache httpd
        └── outputs.tf   # Exports : vpc_id, subnet_ids, ec2_id, sg_ids
```

---

## ✅ Ressources déployées

| Ressource | Description |
|---|---|
| **VPC** | CIDR configurable (`10.2.0.0/16` par défaut) |
| **3 subnets publics** | 1 par AZ, IP publique auto, tags EKS ALB |
| **3 subnets privés** | 1 par AZ, tags EKS internal-LB, via NAT |
| **Internet Gateway** | Accès Internet pour les subnets publics |
| **NAT Gateway + EIP** | Accès Internet sortant pour les nœuds EKS |
| **EC2 bastion** | Amazon Linux 2023, t3.micro, Apache httpd |
| **Security Group EC2** | SSH + HTTP + HTTPS depuis 0.0.0.0/0 |
| **EKS Cluster** | Kubernetes 1.31, endpoint public + privé |
| **EKS Node Group** | t3.micro, scaling 1→3, subnets privés |
| **Addon vpc-cni** | Réseau pod-to-pod natif AWS |
| **Addon coredns** | DNS interne Kubernetes |
| **Addon kube-proxy** | Règles iptables pour les services |
| **IAM Role cluster** | `AmazonEKSClusterPolicy` + `AmazonEKSVPCResourceController` |
| **IAM Role node** | `AmazonEKSWorkerNodePolicy` + `AmazonEKS_CNI_Policy` + `AmazonEC2ContainerRegistryReadOnly` |
| **Application Load Balancer** | Externe, HTTP:80, subnets publics |
| **Target Group + Listener** | Health check `/`, forward → EC2 |

---

## 🏆 Bonnes pratiques Terraform appliquées

### Variabilisation du code
Toutes les valeurs configurables sont dans `variables.tf` avec `description`, `type` et `default`. Aucune valeur hardcodée dans les ressources.

### Utilisation de data sources
- `data.aws_ami.amazon_linux_2023` — récupère dynamiquement la dernière AMI AL2023 (compatible multi-région)
- `data.aws_availability_zones.available` — liste les AZ de la région courante (compatible multi-région)
- `data.aws_iam_policy_document` — génère les policies IAM en HCL natif

### Module local `core-compute`
Encapsule tout le réseau et le compute de base :
- VPC · IGW · Route tables
- 3 subnets publics + 3 subnets privés (via `count = 3` + `cidrsubnet()`)
- NAT Gateway + Elastic IP
- Security groups
- EC2 bastion

Le module expose ses outputs (`vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `ec2_id`, `eks_cluster_sg_id`) consommés par la racine.

### Compatibilité multi-région
- Aucune AZ hardcodée : utilisation de `data.aws_availability_zones.available`
- Aucune AMI hardcodée : utilisation de `data.aws_ami` avec filtres génériques
- CIDRs des subnets calculés via `cidrsubnet(var.vpc_cidr, 8, N)` — s'adapte si `vpc_cidr` change
- Le provider AWS reçoit la région via variable

### Sécurité
- Les nœuds EKS sont dans les **subnets privés** (non accessibles depuis Internet)
- Le NAT Gateway permet les sorties mais bloque les entrées vers les nœuds
- Séparation des rôles IAM : un rôle pour le control plane, un pour les nœuds
- `sensitive = true` sur l'output du certificate authority EKS
- Backend S3 préconfiguré (commenté, voir section Bonus)
- `default_tags` sur le provider : tous les tags centralisés, aucun doublon

### Tags Kubernetes sur les subnets ⚠️ (correction majeure)
Les tags suivants sont **obligatoires** pour qu'EKS fonctionne correctement :

```hcl
# Subnets publics
"kubernetes.io/role/elb" = "1"

# Subnets privés
"kubernetes.io/role/internal-elb" = "1"

# Les deux
"kubernetes.io/cluster/<nom-cluster>" = "shared"
```

Sans ces tags, les Load Balancers Kubernetes ne trouvent pas leurs subnets.

---

## 🛠️ Prérequis

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configuré (`aws configure`)
- Compte AWS avec droits suffisants (IAM, VPC, EKS, EC2, ELB)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (pour interagir avec le cluster après déploiement)

---

## 🚀 Déploiement

### 1. Cloner le dépôt

```bash
git clone https://github.com/Whitedukecmr/eks-terraform-5asrcb.git
cd eks-terraform-5asrcb
```

### 2. Configurer les credentials AWS

```bash
aws configure
# ou avec un profil spécifique
export AWS_PROFILE=mon-profil
```

### 3. Initialiser Terraform

```bash
terraform init
```

### 4. Vérifier le plan

```bash
terraform plan
```

### 5. Déployer l'infrastructure

```bash
terraform apply
```

> ⏱️ Le cluster EKS prend ~15-20 minutes à se créer.

### 6. Configurer kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-5asrcb
kubectl get nodes
```

### 7. Vérifier les addons

```bash
kubectl get pods -n kube-system
```

### 8. Détruire l'infrastructure (obligatoire après la soutenance !)

```bash
terraform destroy
```

---

## ⚙️ Variables configurables

| Variable | Description | Défaut |
|---|---|---|
| `region` | Région AWS | `us-east-1` |
| `environment` | Environnement (dev/prod) | `dev` |
| `project_name` | Préfixe des ressources | `5asrcb` |
| `vpc_cidr` | CIDR du VPC | `10.2.0.0/16` |
| `ec2_type` | Type d'instance EC2 | `t3.micro` |
| `eks_cluster_name` | Nom du cluster EKS | `eks-5asrcb` |
| `eks_version` | Version Kubernetes | `1.31` |
| `node_instance_type` | Type des nœuds EKS | `t3.micro` |
| `node_desired_size` | Nœuds souhaités | `2` |
| `node_min_size` | Nœuds minimum | `1` |
| `node_max_size` | Nœuds maximum | `3` |

Exemple de surcharge via `terraform.tfvars` :

```hcl
region           = "eu-west-3"
project_name     = "mon-projet"
eks_cluster_name = "mon-cluster-eks"
node_desired_size = 2
```

---

## 🎁 Bonus — Backend S3

Pour stocker le `terraform.tfstate` de manière sécurisée sur S3 :

**1. Créer le bucket S3 manuellement sur la console AWS** (ou via CLI) :

```bash
aws s3 mb s3://mon-bucket-tfstate-5asrcb --region us-east-1
aws s3api put-bucket-versioning \
  --bucket mon-bucket-tfstate-5asrcb \
  --versioning-configuration Status=Enabled
```

**2. Décommenter le bloc backend dans `main.tf`** et renseigner le nom du bucket :

```hcl
backend "s3" {
  bucket = "mon-bucket-tfstate-5asrcb"
  key    = "eks-5asrcb/terraform.tfstate"
  region = "us-east-1"
}
```

**3. Réinitialiser Terraform** (migration du state) :

```bash
terraform init -migrate-state
```

---

## 🎁 Bonus — Déploiement Nginx sur EKS

Après `terraform apply`, déployer Nginx sur le cluster :

```bash
# Configurer kubectl
aws eks update-kubeconfig --region us-east-1 --name eks-5asrcb

# Déployer Nginx
kubectl create deployment nginx --image=nginx --replicas=2

# Exposer via un service LoadBalancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Récupérer l'URL du LB Kubernetes
kubectl get svc nginx
```

---

## 📊 Outputs disponibles après `terraform apply`

| Output | Description |
|---|---|
| `vpc_id` | ID du VPC |
| `public_subnet_ids` | IDs des 3 subnets publics |
| `private_subnet_ids` | IDs des 3 subnets privés |
| `ec2_public_ip` | IP publique de l'EC2 bastion |
| `eks_cluster_name` | Nom du cluster |
| `eks_cluster_endpoint` | URL de l'API Kubernetes |
| `eks_cluster_version` | Version Kubernetes déployée |
| `alb_dns_name` | DNS de l'ALB (accès HTTP) |
| `kubeconfig_command` | Commande `aws eks update-kubeconfig` prête à l'emploi |

---

## 🧠 Compétences acquises

### Infrastructure as Code avec Terraform
- Structuration d'un projet Terraform avec **module local** (`core-compute`)
- Utilisation des **data sources** pour une configuration dynamique et multi-région
- Maîtrise des **outputs** inter-modules pour composer des ressources dépendantes
- Utilisation de `count` et `cidrsubnet()` pour créer des ressources répétitives sans duplication
- Configuration d'un **backend distant S3** pour sécuriser le tfstate
- Application des **default_tags** provider pour une gestion centralisée des tags

### Réseau AWS
- Conception d'un VPC multi-AZ avec **subnets publics et privés**
- Configuration d'une **Internet Gateway** et de **route tables** différenciées
- Mise en place d'un **NAT Gateway** pour permettre l'accès Internet sortant des nœuds
- Sécurisation par **Security Groups** avec le principe du moindre privilège

### Amazon EKS
- Déploiement d'un cluster EKS avec **control plane managé AWS**
- Configuration d'un **node group** (EC2 managées par l'utilisateur)
- Installation des addons obligatoires : **vpc-cni**, **coredns**, **kube-proxy**
- Compréhension des **tags Kubernetes** obligatoires sur les subnets pour les Load Balancers
- Configuration de l'accès `kubectl` via `aws eks update-kubeconfig`

### IAM & Sécurité
- Création de **rôles IAM** distincts pour le control plane et les nœuds
- Utilisation de `aws_iam_policy_document` (data source) pour les assume role policies
- Attachement des **AWS managed policies** nécessaires à EKS

### Load Balancing
- Déploiement d'un **Application Load Balancer** (ALB) sur les subnets publics
- Configuration d'un **target group** avec health check HTTP
- Mise en place d'un **listener HTTP:80** avec règle de forward

---

## 👨‍💻 Auteur

**Frédéric Junior EPESSE PRISO** — ESGI 5ASRCB (5SRC2)
Promotion 2025-2026 | Spécialisation Systèmes, Réseaux & Cloud Computing

GitHub : [github.com/Whitedukecmr](https://github.com/Whitedukecmr)

---

## 📚 Références

- [Documentation officielle Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Amazon EKS — Getting started](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Terraform EKS module pattern](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks)
