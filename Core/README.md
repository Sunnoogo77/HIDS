# HIDS - Host-based Intrusion Detection System (Phase 1 - PowerShell Edition)

> **Suivez en temps réel les modifications critiques de votre système avec un outil léger, simple et redoutablement efficace.**

## **Présentation**

Ce projet est la **phase 1** d’un système de détection d’intrusion local (HIDS), écrit en **PowerShell** et entièrement autonome.

Il permet de surveiller :
- Les **fichiers sensibles**
- Les **dossiers critiques**
- Les **connexions IP établies**
- Et d’envoyer des **alertes mail automatisées ou manuelles**

Le tout est orchestré via des fichiers `.json`, sans dépendance à une base de données, pour une **gestion simple, lisible et portable**.

---

## **Fonctionnalités clés**

### ✅ Surveillance de fichiers (`monitor_files.ps1`)
- Calcul de hash SHA256
- Alerte en cas de modification, suppression ou déplacement

### ✅ Surveillance de dossiers (`monitor_folders.ps1`)
- Hash basé sur l’arborescence et le contenu
- Détection des ajouts, suppressions ou modifications

### ✅ Surveillance de connexions IP (`monitor_ips.ps1`)
- Détection des connexions TCP actives vers des IPs surveillées

### ✅ Envoi d’alertes mail (`alerts.ps1`)
- Envoi périodique d’un rapport (HTML) complet par email

### ✅ Envoi manuel d’alerte (`send_alert_now.ps1`)
- Envoie immédiat de toutes les alertes en attente

---

## **Structure du dossier**

```plaintext
Core/
├── data/
│   ├── alerts.json           # Toutes les alertes en attente
│   ├── config.json           # Configuration (fichiers, dossiers, IPs, mails)
│   ├── history.json          # Historique des événements
│   ├── hashes.json           # Sauvegarde des hashes initiaux
│   ├── monitored_ips.json    # IPs déjà détectées
│   ├── status.json           # État des scripts en cours
│   └── users.json            # Authentification (facultatif)
│
├── logs/
│   ├── hids.json             # Log JSON
│   └── hids.log              # Log texte
│
├── scripts/
│   ├── alerts.ps1
│   ├── configs.ps1
│   ├── logs.ps1
│   ├── monitor_files.ps1
│   ├── monitor_folders.ps1
│   ├── monitor_ips.ps1
│   └── send_alerts_now.ps1
```

---

## **Installation & Exécution**

### 1. **Pré-requis**

- Windows 10/11 avec **PowerShell 5.1 ou supérieur**
- Accès admin pour certaines fonctions réseau
- Module [MailKit](https://www.nuget.org/packages/MailKit) installé dans `C:\Program Files\PackageManagement\NuGet\Packages\`

### 2. **Configuration**

Modifiez le fichier `Core/data/config.json` pour :

- Ajouter des fichiers :
```json
"files": [
  "C:\\Users\\...\\document.txt",
  "C:\\Windows\\System32\\important.ini"
]
```

- Ajouter des dossiers :
```json
"folders": [
  "C:\\Logs",
  "D:\\Sécurité\\Suivi"
]
```

- Ajouter des IPs à surveiller :
```json
"ips": [
  "192.168.1.100",
  "10.10.0.5"
]
```

- Configurer les emails :
```json
"email": {
  "interval": 300,
  "recipients": [
    "admin@example.com",
    "security@example.com"
  ]
}
```

### 3. **Lancer les scripts**

Depuis PowerShell (en mode Admin) :

#### Fichiers :
```powershell
.\monitor_files.ps1
```

#### Dossiers :
```powershell
.\monitor_folders.ps1
```

#### IPs :
```powershell
.\monitor_ips.ps1
```

#### Envoi automatique par mail :
```powershell
.\alerts.ps1
```

#### Envoi immédiat :
```powershell
.\send_alerts_now.ps1 -EmailRecipients "admin@example.com" -ClearAfterSend $true
```

---

## **Personnalisation**

### ⏱ Modifier la fréquence d’analyse :
- Modifier `"interval"` dans `config.json`
- Ou passer en paramètre (si script supporte les paramètres, ex : `-Interval 30`)

### ✉️ Ajouter/Retirer des emails :
- Modifier la clé `"recipients"` dans la section `"email"`

### 📁 Ajouter/Retirer des chemins :
- Modifiez simplement les tableaux `"files"` ou `"folders"`

### ✅ Reset manuel du système :
```powershell
.\configs.ps1
```

---

## **Logs et Historique**

- Tous les logs sont écrits dans :
  - `logs/hids.log` (lisible)
  - `logs/hids.json` (parseable)
- Historique des événements dans `data/history.json`

---

## **FAQ**

### Que se passe-t-il si un fichier/dossier surveillé est supprimé ?
> L’alerte est enregistrée et loguée. Le fichier est retiré de la surveillance jusqu’à nouvelle mise à jour.

### Peut-on recevoir les mails automatiquement toutes les X minutes ?
> Oui, via `alerts.ps1` et la clé `"interval"`.

### Et si je veux vider les alertes après envoi ?
> Utilisez `send_alerts_now.ps1 -ClearAfterSend $true`.

### Et si je veux programmer l’exécution automatiquement ?
> Ajoutez les scripts `.ps1` dans le planificateur de tâches Windows (Task Scheduler).

---

## **Contribution**

Ce projet est **modulaire et extensible**. Vous pouvez :

- Ajouter de nouvelles catégories (e.g. registry, services, etc.)
- Ajouter de la visualisation (Power BI, web interface)
- Écrire une interface en Python ou Flask (c’est la phase 2)

---

## **Crédits**

Développé par [Sunnogo Caleb] avec l’aide de ChatGPT  
Projet réalisé dans un objectif pédagogique, défensif et professionnel.

---

## **Licence**

Open Source - Utilisation libre à but pédagogique ou professionnel non-commercial.

---

**Bon monitoring à vous !**
```

