Rapport Technique - HIDS Phase 1 - PowerShell Monitoring

---

## **1. Introduction**

### **Contexte**
Dans un monde de plus en plus exposé aux menaces numériques, il est crucial pour toute machine connectée — personnelle ou professionnelle — d’avoir un œil sur son propre environnement. Les attaques, modifications non autorisées, connexions suspectes et fuites de données peuvent survenir à tout moment.

Dans ce contexte, le projet **HIDS (Host Intrusion Detection System)** a pour vocation de proposer une solution légère mais efficace permettant de **surveiller en temps réel** :
- L’intégrité des fichiers sensibles
- L’état des dossiers critiques
- Les connexions réseau actives vers des adresses IP ciblées
- La génération et la diffusion d’alertes automatiques

### **Objectifs**
Le projet s’est fixé comme objectifs principaux :
- **Détecter les modifications** non prévues sur des fichiers/dossiers définis.
- **Repérer les connexions réseau anormales** ou imprévues à des IPs sensibles.
- **Informer l’utilisateur** en temps réel par le biais de fichiers `alerts.json` et par **e-mail automatique ou manuel**.
- Fournir une base entièrement **autonome en PowerShell**, sans dépendre d’applications tierces lourdes.
- Faciliter l’exploitation via une interface web (dans une seconde phase).

### **Initiatives**
Ce projet s’est construit sur une logique incrémentale :
- Définir un **fichier de configuration** simple (`config.json`) listant les éléments à surveiller.
- Utiliser des scripts PowerShell individuels pour chaque aspect du monitoring.
- Centraliser les logs, les alertes, et les états dans des fichiers JSON bien définis.
- Assurer un **lancement modulaire** (script par script), avec gestion de statut, PID, journalisation, etc.

### **Outils et technologies utilisés**
- **PowerShell** : Langage principal pour les scripts de surveillance.
- **JSON** : Pour la configuration (`config.json`), les logs (`hids.log`), les statuts (`status.json`) et les alertes (`alerts.json`).
- **MailKit + MimeKit (.NET)** : Pour l’envoi des e-mails.
- **Visual Studio Code** : Environnement de développement.
- **Outlook** : Serveur SMTP pour les notifications e-mail.

---

## **2. Architecture du projet**

Le projet est organisé autour d’un dossier principal nommé `Core`, contenant 3 sous-dossiers principaux : `data`, `logs`, et `scripts`.

### **Structure générale de `Core`**
```plaintext
Core/
│
├── data/              # Données du système HIDS
│   ├── alerts.json        → Contient les alertes actives
│   ├── config.json        → Contient les éléments à surveiller (fichiers, dossiers, IPs, emails)
│   ├── hashes.json        → Historique des hachages (non utilisé dans tous les scripts)
│   ├── history.json       → Journal des actions et alertes passées
│   ├── monitored_ips.json → Liste des IPs surveillées
│   ├── status.json        → Statut en temps réel de chaque script
│   ├── users.json         → Utilisateurs (authentification éventuelle)
│   └── Readme.md
│
├── logs/              # Journaux
│   ├── hids.json          → Format JSON des logs pour traitement machine
│   └── hids.log           → Version texte des logs (pour lecture humaine)
│
├── scripts/           # Scripts PowerShell
│   ├── configs.ps1         → Initialise la configuration de base
│   ├── logs.ps1            → Utilitaires de journalisation
│   ├── monitor_files.ps1   → Surveille les modifications de fichiers
│   ├── monitor_folders.ps1 → Surveille les changements dans les dossiers
│   ├── monitor_ips.ps1     → Surveille les connexions IP suspectes
│   ├── alerts.ps1          → Envoie des alertes périodiques par mail
│   ├── send_alerts_now.ps1 → Envoie immédiat des alertes existantes
│   └── Readme.md
│
├── tests/             # Données de test (fichiers SMTP et autres)
│   ├── email_password.txt  → Fichier temporaire pour mot de passe mail (dev)
│   ├── outlook.xml         → Clé d’authentification mail Outlook
│   └── README.md
│
└── run.ps1            # Script de démarrage global (optionnel)
```

### **Interaction entre les composants**
Chaque script est **autonome** mais utilise les mêmes fichiers `config.json`, `alerts.json`, `status.json`, etc. Cela permet de :
- Mutualiser les données entre scripts.
- Centraliser l’information pour une interface web (ou future API).
- Faciliter le débogage, la maintenance, et la lecture humaine.

---

## **3. Scripts de surveillance**

Chaque aspect de la surveillance repose sur un **script PowerShell dédié**. Ces scripts fonctionnent de manière indépendante, mais utilisent tous une structure commune : lecture de la configuration, exécution du scan, détection des anomalies, mise à jour du `status.json`, et écriture des alertes.

### **3.1 `monitor_files.ps1`**
- **Rôle** : Surveille l’intégrité de fichiers spécifiques (hash SHA-256).
- **Fonctionnement** :
  - Lit les chemins de fichiers depuis `config.json`.
  - Calcule le hachage initial de chaque fichier.
  - Vérifie à intervalles réguliers si le hachage a changé.
  - Détecte les modifications et alerte (message + enregistrement dans `alerts.json`).
  - Journalise chaque événement dans `hids.log`.

### **3.2 `monitor_folders.ps1`**
- **Rôle** : Surveille les ajouts, suppressions et modifications de fichiers dans des dossiers.
- **Fonctionnement** :
  - Liste les fichiers présents dans un dossier et leur hachage.
  - Compare cette "empreinte" à l’empreinte précédente.
  - Détecte les changements : nouveaux fichiers, fichiers supprimés ou modifiés.
  - Génère une alerte détaillée avec les noms de fichiers concernés.

### **3.3 `monitor_ips.ps1`**
- **Rôle** : Analyse les connexions TCP/IP actives pour détecter les connexions vers des adresses IP surveillées.
- **Fonctionnement** :
  - Compare les connexions établies à une liste d’IP sensibles (`config.json`).
  - Détecte l’apparition ou la disparition d’une IP cible dans les connexions réseau.
  - Note les ports et processus associés à chaque connexion.

### **3.4 Commun à tous les scripts**
- Chaque script :
  - Met à jour son propre statut dans `status.json` (`Running`, `Stopped`, `PID`, etc.).
  - Enregistre des logs détaillés avec le PID, l’heure de détection, les éléments modifiés.
  - Fonctionne en boucle infinie avec une pause (`Start-Sleep`) basée sur un intervalle configurable.
  - Est stoppable manuellement ou via l’interface/API.

---

## **4. Alertes et notifications**

Le système HIDS ne se limite pas à détecter des anomalies : il **informe activement** l’utilisateur à travers deux mécanismes principaux.

### **4.1 `alerts.json`**
- C’est le **centre de collecte** de toutes les anomalies détectées.
- Organisé en 3 catégories :
  - `files` → alertes liées à des fichiers
  - `folders` → alertes liées aux dossiers
  - `ips` → connexions réseau suspectes
- Chaque alerte contient :
  - Un horodatage (`Timestamp`)
  - Un message descriptif (`Message`)
- Ce fichier est mis à jour **par les scripts de surveillance eux-mêmes**.

### **4.2 `alerts.ps1` – envoi périodique par e-mail**
- Script qui lit les alertes depuis `alerts.json` à intervalles réguliers.
- Utilise les bibliothèques `.NET` (MailKit, MimeKit) pour envoyer des **e-mails formatés**.
- Crée un **rapport HTML** contenant les alertes classées.
- Après envoi :
  - Vide ou conserve les alertes selon la configuration.
  - Met à jour `status.json` (fréquence, nombre d'e-mails envoyés, etc.).
- Nécessite un fichier `outlook.xml` contenant les identifiants mail sécurisés.

### **4.3 `send_alerts_now.ps1` – envoi manuel immédiat**
- Permet d’envoyer un e-mail **manuellement**, sans attendre la fréquence du `alerts.ps1`.
- Même structure HTML.
- Peut vider ou non les alertes après l’envoi selon le paramètre `-ClearAfterSend`.

---

## **5. Fichiers de configuration & données**

Le projet repose sur plusieurs fichiers `.json` stockés dans le répertoire `Core/data`, chacun jouant un rôle spécifique dans la configuration et le fonctionnement du système.

### **5.1 `config.json`**
- Contient les **données de configuration initiales**.
- Géré via le script `configs.ps1`.
- Structure :
```json
{
  "files": ["C:\\Users\\...\\file1.txt", ...],
  "folders": ["C:\\Users\\...\\folder1", ...],
  "ips": ["192.168.1.10", "10.0.0.5"],
  "interval": 10,
  "email": {
    "recipients": ["admin@example.com"],
    "interval": 60
  }
}
```
- Permet de centraliser les fichiers, dossiers et IPs à surveiller ainsi que les paramètres de notification.

### **5.2 `status.json`**
- **Mis à jour automatiquement** par chaque script de surveillance.
- Indique l’état de chaque service :
  - `Status`: `Running` / `Stopped`
  - `PID`, `StartTime`, `Interval`
  - Liste des éléments surveillés (`monitoredFiles`, `monitoredFolders`, etc.)
- Permet à l’utilisateur ou à une interface web/API de savoir ce qui tourne en temps réel.

### **5.3 `alerts.json`**
- Base de données temporaire des **alertes détectées** par les scripts.
- Séparées en trois catégories (`files`, `folders`, `ips`) pour une meilleure lisibilité.
- Sert de source aux scripts `alerts.ps1` et `send_alert_now.ps1`.

### **5.4 `hashes.json`**
- Utilisé par `monitor_files.ps1` pour enregistrer les **empreintes de hachage SHA256** des fichiers.
- Permet la détection précise des changements.

### **5.5 `users.json`**
- Contient les utilisateurs autorisés à interagir avec l’interface web/API.
- Utilisé pour l’authentification JWT.

---

## **6. Journalisation (Logs)**

Le système est conçu pour offrir une **traçabilité complète** des événements, pour analyse, audits ou simplement debug.

### **6.1 `hids.log`**
- Fichier principal de log textuel.
- Chaque script PowerShell utilise la fonction `Write-Log` pour enregistrer :
  - Les événements critiques : démarrage, arrêt, erreur, alerte.
  - L’heure, le PID, la source et la nature de l’événement.
- Format clair pour une lecture humaine ou traitement automatisé.

### **6.2 `logs.ps1`**
- Fournit les fonctions standard de journalisation utilisées par les autres scripts.
- Fonction principale :
```powershell
function Write-Log {
    param (
        [string]$Message,
        [string]$Category = "General"
    )
    ...
}
```
- Enregistre les logs dans un format structuré dans `hids.log`, mais aussi dans `logs/hids.json` pour un traitement JSON.


## **7. Résultats & démonstration**

Cette section vise à illustrer le **comportement du système** en situation réelle, à travers des démonstrations, tests et captures d’écran.

### **7.1 Exécution des scripts de surveillance**

Lorsqu’un script comme `monitor_files.ps1` est lancé, voici ce qui se passe :

- Le fichier `config.json` est lu pour récupérer la liste des fichiers à surveiller.
- Les fichiers sont hachés (SHA256) et enregistrés dans `hashes.json`.
- Un log est généré indiquant le début de la surveillance, avec le PID et l'heure.
- Le fichier `status.json` est mis à jour avec les métadonnées du processus (`StartTime`, `Status`, `PID`, etc.).

#### **Détection de modification**

Lorsqu’un fichier est modifié :

- Un nouveau hash est généré et comparé à l’ancien.
- Si différent :
  - Une entrée est ajoutée dans `alerts.json`.
  - Une ligne est ajoutée dans `hids.log`.
  - Une alerte est visible depuis l'interface utilisateur (ou envoyée par email via `alerts.ps1`).

Idem pour la surveillance des **dossiers** (fichiers ajoutés/supprimés) ou des **IPs** (connexion TCP).

### **7.2 Visualisation dans les fichiers JSON**

- **`status.json`** : permet de savoir ce qui tourne en live.
- **`alerts.json`** : enregistre toutes les alertes générées.
- **`hids.log`** : journal texte chronologique.

### **7.3 Capture d’écran de la structure du projet**

Une capture de l’arborescence du dossier `Core/` a été incluse dans le rapport pour illustrer la structure et faciliter la compréhension.

---

## **8. Difficultés rencontrées & solutions**

### **8.1 Exécution depuis une interface Python (Flask)**

- **Problème :** Lorsqu’un script est lancé via une route Flask, la communication avec les fichiers JSON n’était pas toujours correcte (problèmes de PID, de statut non mis à jour, ou de fichiers vides).
- **Solution :**
  - Centralisation de la gestion de l'état via `status.json`.
  - Exécution des scripts depuis leur répertoire via `cwd`.
  - Utilisation de `psutil` pour arrêter proprement les scripts via leur PID.

### **8.2 Problème de performances**

- La charge de travail (fréquence élevée de scan) pouvait ralentir le système.
- Réglé en paramétrant des **fréquences de scan ajustables** (intervalle configurable par l’utilisateur dans `config.json`).

### **8.3 Migration vers une version 100% Python**

- **Constat :** l’exécution de PowerShell via Python posait trop de limites.
- **Décision :** migrer progressivement les scripts `.ps1` vers des scripts `.py` équivalents, pour une meilleure intégration.

---

## **9. Conclusion & perspectives**

Ce projet représente une **première version réussie** d’un système HIDS (Host-based Intrusion Detection System) simple mais efficace, réalisé uniquement avec PowerShell, JSON et un soupçon de Python pour l’interface web.

### **Accomplissements**
- Surveillance des fichiers, dossiers et IPs.
- Génération et journalisation d’alertes.
- Envoi automatique ou manuel d’emails d’alerte.
- Interface web pour démarrer / arrêter les services.
- Gestion de la configuration et des utilisateurs via fichiers JSON.

### **Perspectives**
- Migration vers une architecture full Python (plus portable, plus contrôlable).
- Ajout d’un dashboard avec historique, visualisation des logs et alertes.
- Intégration dans un environnement client (Windows Services, Task Scheduler...).
- Support multiplateforme à travers Python (Linux/macOS).

---