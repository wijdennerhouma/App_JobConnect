# Documentation Technique Complète - Application de Recrutement

Ce document fournit une vue d'ensemble détaillée de l'architecture technique, des fonctionnalités, et des instructions de déploiement pour l'Application de Recrutement (Frontend & Backend).

---

## 1. Vue d'Ensemble du Projet

Le projet est une solution complète de recrutement permettant aux candidats de postuler à des offres d'emploi et aux entreprises de gérer leurs recrutements.

**Stack Technique :**
*   **Frontend :** Flutter (Dart) - Application mobile et web responsive.
*   **Backend :** NestJS (TypeScript) - API RESTful robuste et modulaire.
*   **Base de Données :** MongoDB - Base de données NoSQL pour la flexibilité des données.
*   **Conteneurisation :** Docker - Pour faciliter le déploiement de la base de données et du backend.

---

## 2. Prérequis Système

Pour exécuter ce projet sur une nouvelle machine, assurez-vous d'avoir installé :

*   **Node.js** (v16 ou supérieur)
*   **Flutter SDK** (Dernière version stable)
*   **Docker Desktop** (Pour MongoDB et le Backend conteneurisé)
*   **Git** (Pour cloner le projet)
*   **Un IDE** (VS Code)

---

## 3. Architecture Backend (NestJS)

Le backend est structuré autour de modules fonctionnels clairs.

### Structure des Dossiers
```
src/
├── app.module.ts          # Module racine
├── main.ts                # Point d'entrée de l'application
├── auth/                  # Authentification & Gestion Utilisateurs
├── job/                   # Gestion des Offres d'Emploi
├── application/           # Gestion des Candidatures
├── chat/                  # Système de Messagerie
├── notification/          # Système de Notifications
└── resume/                # Gestion des CVs (Upload/Download)
```

### API Routes (Endpoints Principaux)

#### **Authentification (`/auth`)**
*   `POST /auth/login` : Connecter un utilisateur.
*   `POST /auth/register` : Inscrire un nouvel utilisateur (Candidat ou Entreprise).
*   `GET /auth/profile` : Récupérer le profil de l'utilisateur connecté.
*   `PATCH /auth/profile` : Mettre à jour le profil.
*   `POST /auth/upload-avatar` : Téléverser une photo de profil.

#### **Offres d'Emploi (`/jobs`)**
*   `GET /jobs` : Lister toutes les offres (avec filtres).
*   `GET /jobs/:id` : Détails d'une offre spécifique.
*   `POST /jobs` : Créer une nouvelle offre (Entreprise uniquement).
*   `PUT /jobs/:id` : Modifier une offre.
*   `DELETE /job/:id` : Supprimer une offre (Fonctionnalité entreprise).

#### **Candidatures (`/applications`)**
*   `POST /applications` : Postuler à une offre.
*   `GET /applications/my-applications` : Voir l'historique de ses candidatures (Candidat).
*   `GET /applications/job/:jobId` : Voir les candidats pour une offre (Entreprise).
*   `PATCH /applications/:id/status` : Accepter ou Refuser une candidature.

#### **Chat (`/chat`)**
*   `POST /chat/send` : Envoyer un message.
*   `GET /chat/conversations` : Récupérer la liste des conversations.
*   `GET /chat/messages/:userId` : Récupérer les messages avec un utilisateur spécifique.

---

## 4. Architecture Frontend (Flutter)

L'application Flutter utilise une architecture basée sur **Provider** pour la gestion d'état.

### Structure des Dossiers (`lib/src/`)
```
lib/src/
├── core/                  # Configuration globale (Thème, AuthState, Traductions)
├── models/                # Modèles de données (User, Job, Application)
├── services/              # Services API (Appels HTTP vers le Backend)
├── screens/               # Écrans de l'application
│   ├── auth/              # Login, Signup
│   ├── employee/          # Écrans Candidat (Home, Job Details, Apply)
│   ├── entreprise/        # Écrans Entreprise (Dashboard, Post Job)
│   ├── search/            # Recherche de profils
│   ├── chat/              # Messagerie
│   └── onboadring/        # Écran d'accueil
└── widgets/               # Composants UI réutilisables
```

### Fonctionnalités Clés
*   **Gestion d'État :** Utilisation de `Provider` pour injecter `AuthState` et `AppSettings` dans toute l'application.
*   **Navigation :** Système de navigation natif de Flutter.
*   **Internationalisation (i18n) :** Support complet multilingue (Français, Anglais, Arabe) pour toutes les interfaces et dialogues (y compris les confirmations de suppression).
*   **Stockage Local :** `SharedPreferences` pour persister le token d'authentification et les préférences.

### Nouvelles Fonctionnalités (Mise à jour)
*   **Suppression d'Offres :** Les entreprises peuvent désormais supprimer leurs propres offres d'emploi via une interface sécurisée avec confirmation.
*   **Gestion des Traductions :** Amélioration de la couverture des traductions pour les actions critiques.

---

## 5. Guide de Démarrage (Run Project)

Suivez ces étapes pour lancer le projet sur un nouvel ordinateur.

### Étape 1 : Initialiser le Backend et la Base de Données

1.  Ouvrez un terminal dans le dossier du backend (`recruitment-app-backend-main`).
2.  Assurez-vous que Docker est lancé.
3.  Exécutez la commande suivante pour lancer MongoDB et le serveur Backend :
    ```bash
    docker-compose up --build
    ```
    *   Cela va créer les conteneurs nécessaires.
    *   L'API sera accessible sur `http://localhost:3000`.
    *   La base de données MongoDB sera accessible sur le port `27017`.

### Étape 2 : Configurer et Lancer le Frontend

1.  Ouvrez un nouveau terminal dans le dossier du frontend (`application_de_recrutement`).
2.  Récupérez les dépendances Flutter :
    ```bash
    flutter pub get
    ```
3.  Vérifiez l'adresse IP de l'API :
    *   Ouvrez `lib/src/core/api_config.dart`.
    *   Si vous testez sur un émulateur Android, utilisez `10.0.2.2`.
    *   Si vous testez sur le Web ou iOS Simulator, utilisez `localhost` ou `127.0.0.1`.
    *   Si vous testez sur un appareil physique, utilisez l'adresse IP locale de votre machine (ex: `192.168.1.x`).
    
    ```dart
    // Exemple de configuration dans api_config.dart
    static const String baseUrl = 'http://localhost:3000'; 
    ```

4.  Lancez l'application :
    *   **Pour le Web (Chrome) :**
        ```bash
        flutter run -d chrome
        ```
    *   **Pour Mobile (Android/iOS) :**
        Connectez votre appareil ou lancez un émulateur, puis :
        ```bash
        flutter run
        ```

---

## 6. Dépannage Courant

*   **Erreur de connexion (SocketException) :** Vérifiez que l'URL dans `api_config.dart` correspond bien à l'adresse de votre serveur backend. Sur Android, `localhost` ne fonctionne pas, utilisez `10.0.2.2`.
*   **Images non chargées :** Assurez-vous que le dossier `uploads` existe dans le backend et que les permissions sont correctes.
*   **MongoDB ne démarre pas :** Vérifiez qu'aucun autre service n'utilise le port 27017.

---


