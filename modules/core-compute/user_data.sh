#!/bin/bash
set -e

# Mise à jour du système
dnf update -y

# Installation d'Apache (httpd)
dnf install -y httpd

# Page d'accueil personnalisée
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <title>5ASRCB - EKS Project</title>
  <style>
    body { font-family: Arial, sans-serif; background: #1a1a2e; color: #eee; text-align: center; padding: 60px; }
    h1 { color: #00d4ff; }
    p  { color: #aaa; }
  </style>
</head>
<body>
  <h1>✅ EKS Cluster 5ASRCB</h1>
  <p>Instance EC2 bastion opérationnelle — Terraform déployé avec succès.</p>
  <p>Projet ESGI 5ASRCB | Cloud Computing</p>
</body>
</html>
EOF

# Démarrage et activation d'Apache
systemctl enable --now httpd
