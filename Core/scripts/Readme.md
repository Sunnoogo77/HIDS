## 📂 **Présentation du répertoire `scripts/`**  
Le dossier `scripts/` contient tous les **scripts PowerShell** nécessaires au fonctionnement du HIDS (**Host Intrusion Detection System**).  

📌 **Objectifs principaux :**  
1️⃣ **Surveiller les fichiers et dossiers sensibles** 🔍  
2️⃣ **Contrôler les connexions réseau suspectes** 📡  
3️⃣ **Gérer la configuration du système** ⚙  
4️⃣ **Envoyer des alertes par e-mail** 📩  
5️⃣ **Enregistrer les événements de sécurité** 📝  

---

## 📜 **Liste des fichiers et leur rôle**  

### **1️⃣ `configs.ps1` → Gestion de la configuration**  
📌 **Objectif :** Ajouter, supprimer ou modifier les fichiers/dossiers/IPs surveillés et configurer la fréquence de surveillance.  

🔹 **Actions possibles :**  
| Action            | Type       | Valeur            | Exemple d'utilisation |
|------------------|-----------|------------------|----------------------|
| `ADD`           | `File`    | `C:\test.txt`   | `.\configs.ps1 -Action ADD -Type File -Value "C:\test.txt"` |
| `ADD`           | `Folder`  | `C:\Users\Docs` | `.\configs.ps1 -Action ADD -Type Folder -Value "C:\Users\Docs"` |
| `ADD`           | `IP`      | `192.168.1.1`   | `.\configs.ps1 -Action ADD -Type IP -Value "192.168.1.1"` |
| `REMOVE`        | `File`    | `C:\test.txt`   | `.\configs.ps1 -Action REMOVE -Type File -Value "C:\test.txt"` |
| `SET-INTERVAL`  | `-`       | `3600` (en sec) | `.\configs.ps1 -Action SET-INTERVAL -Value 3600` |
| `SET-EMAIL`     | `ADD-Recipient` | `user@example.com` | `.\configs.ps1 -Action SET-EMAIL -Type ADD-Recipient -Value "user@example.com"` |

---

### **2️⃣ `logs.ps1` → Enregistrement des événements**  
📌 **Objectif :** Stocker toutes les alertes détectées sous forme de **logs texte et JSON**.  

📂 **Fichiers générés :**  
- `../logs/hids.log` → Historique brut des alertes.  
- `../logs/hids.json` → Version JSON structurée des alertes.  

🔹 **Exemple de log :**  
```
[2025-03-14 14:30:00] ALERT: File changed! C:\Users\test\file.txt
```

🛡 **Sécurité :**  
✅ **Les logs sont stockés séparément** pour garantir la traçabilité même en cas d’attaque.  
✅ **Les logs sont horodatés** pour faciliter l’analyse.  

---

### **3️⃣ `monitor_files.ps1` → Surveillance des fichiers**  
📌 **Objectif :** Détecter **les modifications sur les fichiers critiques**.  

📌 **Actions détectées :**  
✅ **Modification du contenu**  
✅ **Suppression d’un fichier**  
✅ **Ajout d’un fichier**  

🔹 **Exemple d’alerte détectée :**  
```
ALERT: File changed! C:\Users\test\document.txt | Modified at: 2025-03-14 14:30:00
```

---

### **4️⃣ `monitor_folders.ps1` → Surveillance des dossiers**  
📌 **Objectif :** Détecter **les changements dans les dossiers surveillés**.  

📌 **Actions détectées :**  
✅ **Ajout de fichiers**  
✅ **Suppression de fichiers**  
✅ **Modification d’un fichier existant**  

🔹 **Exemple d’alerte détectée :**  
```
ALERT: Folder changed! C:\Users\test\Documents || By: UserX || Added files: new.docx || Removed files: old.txt
```

---

### **5️⃣ `monitor_ips.ps1` → Surveillance des connexions réseau**  
📌 **Objectif :** Détecter **les connexions suspectes** vers/depuis les IPs surveillées.  

📌 **Actions détectées :**  
✅ **Connexion à une IP suspecte**  
✅ **Changement du port d’une connexion existante**  
✅ **Perte de connexion avec une IP surveillée**  

🔹 **Exemple d’alerte détectée :**  
```
ALERT: Connection to 192.168.1.1 lost!
```

🛡 **Sécurité :**  
✅ Utilise **`Get-NetTCPConnection`** pour récupérer les connexions réseau actives.  
✅ Identifie les **Processus (PIDs)** responsables des connexions.  

---

### **6️⃣ `alerts.ps1` → Envoi des alertes par e-mail**  
📌 **Objectif :** Envoyer un **résumé des alertes** sous forme de **mail HTML**.  

📌 **Fonctionnalités :**  
✅ **Regroupe les alertes** avant envoi (évite le spam).  
✅ **Format HTML** pour une lecture claire.  
✅ **Envoi automatique toutes les `X` minutes** (paramétrable).  

🔹 **Exemple de mail reçu :**  
📩 *Objet:* **HIDS Security Alerts - 2025-03-14 14:30:00**  
📝 *Contenu HTML :*  
```
Files:
- File changed! C:\Users\test\document.txt | By: Admin
Folders:
- Folder changed! C:\Users\test\Documents | Added: new.txt | Removed: old.docx
IPs:
- ALERT: Connection to 192.168.1.1 lost!
```

🛡 **Sécurité :**  
✅ **Utilisation de `MailKit` pour un envoi sécurisé via SMTP.**  
✅ **Prise en charge d’Outlook et Gmail avec authentification.**  

---

## 🛡 **💪 Robustesse et Sécurité du Système**  

🔒 **1. Vérification automatique de `alerts.json`**  
✅ Si `alerts.json` est corrompu, il est **réinitialisé automatiquement**.  
✅ **Les structures de données sont validées** avant l’envoi.  

📩 **2. Protection contre les accès concurrents**  
✅ `alerts.lock` empêche **plusieurs écritures simultanées** pour éviter la corruption.  

📏 **3. Contrôle de la taille des fichiers**  
✅ `alerts.json` est **réduit si trop volumineux** pour éviter des lenteurs.  

📧 **4. Gestion intelligente des alertes email**  
✅ **Agrégation des alertes** → Un seul mail toutes les **X minutes**.  
✅ **Format HTML clair** → Facile à lire et analyser.  

---

## 🚀 **🎯 Comment utiliser ce répertoire ?**  

### **1️⃣ Lancer les scripts de surveillance**  
```powershell
Start-Process PowerShell -ArgumentList "-File .\monitor_files.ps1" -WindowStyle Hidden
Start-Process PowerShell -ArgumentList "-File .\monitor_folders.ps1" -WindowStyle Hidden
Start-Process PowerShell -ArgumentList "-File .\monitor_ips.ps1" -WindowStyle Hidden
```
💡 *Ces commandes lancent les scripts en arrière-plan !*  

### **2️⃣ Vérifier les alertes en attente**  
```powershell
Get-Content ..\data\alerts.json | ConvertFrom-Json
```

### **3️⃣ Forcer l’envoi des alertes par mail**  
```powershell
.\alerts.ps1
```

---

## 📌 **Conclusion**
Le dossier `scripts/` contient **le cœur du HIDS**.  
✅ Il surveille **fichiers, dossiers et connexions réseau**.  
✅ Il **stocke les logs et envoie les alertes**.  
✅ Il garantit **la sécurité et la traçabilité des événements**.  
