## 🏗 **Présentation du répertoire `scripts/`**  
Le dossier `scripts/` contient tous les **scripts PowerShell** qui assurent le fonctionnement du **système de détection d'intrusion HIDS**. Ces scripts sont responsables du **monitoring des fichiers, dossiers et adresses IP**, ainsi que de la **gestion des alertes et de l'envoi des notifications par email**.

---

## 📜 **Liste des scripts et leur rôle**  

### 1️⃣ **`configs.ps1` - Gestion de la configuration**  
📌 **Objectif :** Ce script permet de **configurer** le HIDS, d'ajouter/supprimer des fichiers, dossiers, IPs à surveiller, et de modifier les destinataires des alertes email.

🔹 **Fonctionnalités :**  
- **Lister** la configuration actuelle.  
- **Ajouter/Supprimer** des fichiers, dossiers ou IPs à surveiller.  
- **Définir** l'intervalle de monitoring.  
- **Ajouter/Supprimer** les adresses email qui recevront les alertes.  

⚙ **Commande d'exemple :**  
```powershell
# Ajouter un fichier à surveiller
.\configs.ps1 -Action ADD -Type File -Value "C:\chemin\vers\fichier.txt"

# Modifier l'intervalle de monitoring
.\configs.ps1 -Action SET-INTERVAL -Value 60

# Ajouter un destinataire email
.\configs.ps1 -Action SET-EMAIL -Type ADD-Recipient -Value "email@example.com"
```

---

### 2️⃣ **`logs.ps1` - Gestion des logs**  
📌 **Objectif :** Enregistre tous les événements et alertes détectés par le système.  

🔹 **Fonctionnalités :**  
- Stocke les logs dans **deux formats** :  
  - **hids.log** → Fichier texte lisible.  
  - **hids.json** → Fichier JSON structuré pour exploitation.  
- Permet de **tracer toutes les activités** pour analyse ultérieure.  

---

### 3️⃣ **`alerts.ps1` - Gestion des alertes et envoi d'emails**  
📌 **Objectif :** Ce script regroupe les alertes détectées par le système et les envoie par email aux destinataires configurés.

🔹 **Fonctionnalités :**  
- Vérifie l’intégrité du fichier `alerts.json` avant envoi.  
- Agrège les alertes en **un seul mail toutes les X minutes** (par défaut : **1h**).  
- Évite que le fichier `alerts.json` devienne trop volumineux.  
- Envoie des alertes **au format HTML** pour une meilleure lisibilité.  
- Sécurisé avec des **mesures anti-corruption** des logs.  

⚙ **Sécurité et robustesse :**  
✅ Vérification automatique du fichier `alerts.json`.  
✅ Réinitialisation automatique en cas de corruption.  
✅ Envoi de mail en batch pour éviter le spam.  

---

### 4️⃣ **`monitor_files.ps1` - Surveillance des fichiers**  
📌 **Objectif :** Ce script surveille les **modifications** des fichiers spécifiés dans `config.json` et génère une alerte en cas de changement.  

🔹 **Fonctionnalités :**  
- Vérifie les **modifications de contenu** en comparant les **hashs SHA-256**.  
- Identifie **qui a modifié le fichier** et **à quel moment**.  
- Enregistre les changements dans `alerts.json` et les logs.  

---

### 5️⃣ **`monitor_folders.ps1` - Surveillance des dossiers**  
📌 **Objectif :** Ce script surveille les **changements dans les dossiers** (ajout, suppression, modification de fichiers).  

🔹 **Fonctionnalités :**  
- Génère un **hash unique pour tout le dossier** pour détecter les modifications.  
- Identifie les fichiers **ajoutés, supprimés et modifiés**.  
- Enregistre les événements dans `alerts.json`.  

---

### 6️⃣ **`monitor_ips.ps1` - Surveillance des connexions réseau**  
📌 **Objectif :** Ce script surveille les connexions établies avec les IPs définies dans `config.json`.  

🔹 **Fonctionnalités :**  
- Vérifie **si une connexion avec une IP surveillée est établie**.  
- Détecte **les changements de ports ou de processus** liés à la connexion.  
- Ajoute une alerte dans `alerts.json` en cas d'événement suspect.  

---

## 🛡 **💪 Robustesse et Sécurité du Système**  

🔒 **1. Intégrité des logs et alertes**  
✅ Vérification de `alerts.json` avant chaque utilisation.  
✅ Réinitialisation automatique en cas de corruption.  

📩 **2. Gestion intelligente des alertes email**  
✅ Regroupement des alertes pour éviter l'envoi de multiples mails.  
✅ Format **HTML** clair et structuré.  
✅ Possibilité de configurer la **fréquence d’envoi**.  

⚙ **3. Optimisation des performances**  
✅ Surveillance efficace avec **hashing SHA-256** pour les fichiers et dossiers.  
✅ Traitement optimisé des connexions IP pour éviter la surcharge.  

---

## 📝 **💡 Comment utiliser le système ?**  

### **1️⃣ Lancer la surveillance**  
```powershell
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList ".\monitor_files.ps1"
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList ".\monitor_folders.ps1"
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList ".\monitor_ips.ps1"
Start-Process -NoNewWindow -FilePath "powershell.exe" -ArgumentList ".\alerts.ps1"
```

### **2️⃣ Vérifier les logs**  
```powershell
Get-Content ..\logs\hids.log -Tail 20
```

### **3️⃣ Modifier la configuration**  
```powershell
.\configs.ps1 -Action ADD -Type File -Value "C:\Users\test\document.txt"
```
---

## 📌 **Conclusion**
Le système est conçu pour **être robuste, sécurisé et performant**. Avec cette architecture, nous avons :  
✅ Un **HIDS fonctionnel** et **configurable**.  
✅ Une gestion des logs et alertes **optimisée**.  
✅ Une **protection contre les fichiers corrompus** et une **prévention des envois de mails excessifs**.  

---

💡 **Si des améliorations sont nécessaires ou que des bugs sont détectés, il suffit de modifier les scripts ici en conséquence !** 🚀