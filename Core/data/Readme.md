### 📌 **README.md pour le dossier `data/`**  

Ce fichier **README.md** décrit le contenu du dossier `data/`, son rôle dans le fonctionnement du système HIDS et les fichiers qu'il contient.  

---

## 📂 **Présentation du répertoire `data/`**  
Le dossier `data/` contient **les fichiers de configuration et de stockage** des alertes. Il est crucial pour le bon fonctionnement du système, car il regroupe les paramètres de surveillance et les alertes détectées.

---

## 📜 **Liste des fichiers et leur rôle**  

### 1️⃣ **`config.json` - Configuration principale**  
📌 **Objectif :** Ce fichier stocke **les paramètres de surveillance** du HIDS, notamment :  
- **Les fichiers, dossiers et IPs à surveiller.**  
- **L’intervalle de surveillance.**  
- **Les adresses e-mail pour l’envoi des alertes.**  

🔹 **Exemple de structure :**  
```json
{
    "folders": [
        "C:\\Users\\Sunnoogo77\\OneDrive\\Documents\\Presentation"
    ],
    "ips": [
        "8.8.8.8",
        "20.148.162.46",
        "127.10.0.1",
        "192.164.1.1"
    ],
    "interval": 3600,
    "files": [
        "C:\\Users\\Sunnoogo77\\OneDrive\\Documents\\resuktat.txt",
        "C:\\Users\\Sunnoogo77\\OneDrive\\Documents\\Nouveau Document texte.txt"
    ],
    "email": {
        "smtpServer": "smtp.office365.com",
        "smtpPort": 587,
        "recipients": ["email1@example.com", "email2@example.com"]
    }
}
```

🔹 **Détails :**  
- `folders` → Liste des **dossiers surveillés**.  
- `ips` → Liste des **adresses IP à surveiller**.  
- `interval` → Intervalle (en secondes) pour les vérifications et alertes.  
- `files` → Liste des **fichiers surveillés**.  
- `email` → **Configuration de l’envoi d’alertes par e-mail**.  

⚙ **Ce fichier est modifiable via `configs.ps1`**. Exemple de modification :
```powershell
.\configs.ps1 -Action SET-INTERVAL -Value 1800  # Change l'intervalle de surveillance à 30 minutes
```

---

### 2️⃣ **`alerts.json` - Stockage des alertes**  
📌 **Objectif :** Ce fichier enregistre toutes les **alertes détectées** en attente d'envoi.  
📩 Il est utilisé par `alerts.ps1` pour regrouper les alertes et envoyer un mail en batch.  

🔹 **Exemple de structure :**  
```json
{
    "files": [
        {
            "Timestamp": "2025-03-13T14:20:00Z",
            "Message": "File changed! C:\\Users\\Sunnoogo77\\Documents\\resuktat.txt || By: Admin"
        }
    ],
    "folders": [
        {
            "Timestamp": "2025-03-13T14:25:00Z",
            "Message": "Folder changed! C:\\Users\\Sunnoogo77\\Documents\\Presentation || By: UserX"
        }
    ],
    "ips": [
        {
            "Timestamp": "2025-03-13T14:30:00Z",
            "Message": "ALERT: Connection to 8.8.8.8 lost!"
        }
    ]
}
```

🔹 **Détails :**  
- `files` → Contient les **modifications détectées sur les fichiers surveillés**.  
- `folders` → Enregistre les **changements détectés dans les dossiers surveillés**.  
- `ips` → Liste des **événements liés aux adresses IP surveillées**.  

⚙ **Ce fichier est géré automatiquement par le système**. Il est réinitialisé après l’envoi des alertes.

---

### 3️⃣ **`alerts.lock` (optionnel) - Protection contre les accès concurrents**  
📌 **Objectif :** Ce fichier temporaire est utilisé pour **éviter que plusieurs processus modifient `alerts.json` en même temps**.  

🔹 **Pourquoi ?**  
- Si plusieurs **scripts** (ex: `monitor_files.ps1`, `monitor_ips.ps1`) écrivent dans `alerts.json` **simultanément**, il y a un risque de **corruption des données**.  
- `alerts.lock` permet d'assurer qu'un seul processus accède au fichier à la fois.

🔹 **Fonctionnement :**  
- Lorsqu'un script veut écrire dans `alerts.json`, il **crée `alerts.lock`** pour indiquer qu’il est en train de modifier le fichier.  
- Une fois l’écriture terminée, il **supprime `alerts.lock`** pour que les autres processus puissent écrire à leur tour.  

⚙ **Gestion automatique** par `monitor_ips.ps1`, `monitor_folders.ps1`, et `monitor_files.ps1`.

---

## 🛡 **💪 Robustesse et Sécurité du Système**  

🔒 **1. Vérification automatique de `alerts.json` avant toute utilisation**  
✅ Si `alerts.json` est corrompu, il est **réinitialisé automatiquement**.  
✅ Structure validée avant chaque ajout d’alerte.  

📩 **2. Protection contre les accès concurrents**  
✅ **`alerts.lock`** empêche les écritures simultanées pour éviter la corruption.  

📏 **3. Contrôle de la taille des fichiers**  
✅ `alerts.json` est **réduit si trop volumineux** pour éviter qu'il ne devienne inutilisable.  

📧 **4. Gestion intelligente des alertes email**  
✅ **Agrégation des alertes** → Un seul mail toutes les **X minutes** (configurable).  
✅ **Format HTML clair** → Facile à lire pour l'utilisateur.  

---

## 🚀 **🎯 Comment utiliser ce répertoire ?**  

### **1️⃣ Modifier la configuration manuellement**  
Ouvrir `config.json` et ajouter/supprimer des fichiers, dossiers ou IPs.  

### **2️⃣ Modifier la configuration via `configs.ps1`**  
```powershell
# Ajouter un fichier à surveiller
.\configs.ps1 -Action ADD -Type File -Value "C:\Users\test\document.txt"

# Ajouter une adresse IP à surveiller
.\configs.ps1 -Action ADD -Type IP -Value "192.168.1.100"

# Modifier l'intervalle de surveillance
.\configs.ps1 -Action SET-INTERVAL -Value 300
```

### **3️⃣ Vérifier les alertes en attente**  
```powershell
Get-Content alerts.json | ConvertFrom-Json
```

### **4️⃣ Forcer l’envoi des alertes par mail**  
```powershell
.\alerts.ps1
```

---

## 📝 **💡 Notes Importantes**  
⚠ **Ne pas modifier `alerts.json` manuellement**.  
⚠ **Si `alerts.json` est supprimé, il sera recréé automatiquement.**  
⚠ **Les logs sont enregistrés dans `../logs/` et ne sont pas stockés ici.**  

---

## 📌 **Conclusion**
Le dossier `data/` joue un rôle crucial dans le **bon fonctionnement du HIDS**.  
✅ Il centralise **les paramètres de configuration**.  
✅ Il stocke **les alertes en attente** avant leur envoi.  
✅ Il garantit **la sécurité et la cohérence des données**.  

---

💡 **Si vous souhaitez améliorer le système ou ajouter de nouvelles fonctionnalités, modifiez `config.json` et testez vos changements !** 🚀  
