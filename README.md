# 🚀 JobConnect - Application de Recrutement Multiplateforme

JobConnect est une solution complète de recrutement développée avec **Flutter** (Frontend) et **NestJS** (Backend), conçue pour connecter efficacement les candidats à la recherche d'opportunités et les entreprises en quête de talents.

Cette application offre une expérience utilisateur fluide sur mobile et web, avec une gestion complète du processus de recrutement, de la publication d'offres à la gestion des candidatures.

---

## ✨ Fonctionnalités Principales

### 👤 Pour les Candidats
*   **Recherche d'Emploi** : Parcourez les offres avec des filtres avancés (ville, type de contrat, etc.).
*   **Profil Complet** : Gérez votre CV, ajoutez vos expériences, formations et compétences.
*   **Candidature Simplifiée** : Postulez aux offres en un clic et suivez le statut de vos candidatures (En attente, Accepté, Refusé).
*   **Messagerie** : Discutez directement avec les recruteurs.

### 🏢 Pour les Entreprises
*   **Publication d'Offres** : Créez et publiez des offres d'emploi détaillées.
*   **Gestion des Candidatures** : Consultez les profils des candidats, téléchargez leurs CVs et mettez à jour le statut de leur candidature.
*   **Gestion des Offres** : Modifiez ou **supprimez** vos offres d'emploi directement depuis l'application.
*   **Tableau de Bord** : Vue d'ensemble de vos activités de recrutement.

### 🌍 Fonctionnalités Globales
*   **Multi-langues** : Support complet du **Français 🇫🇷**, **Anglais 🇬🇧** et **Arabe 🇹🇳**.
*   **Mode Sombre / Clair** : Thème adaptatif pour un confort visuel optimal.
*   **Authentification Sécurisée** : Inscription et connexion sécurisées pour tous les utilisateurs.
*   **Chat Intégré** : Système de messagerie temps réel entre candidats et recruteurs.

---

## 🛠️ Stack Technique

Le projet repose sur une architecture moderne et robuste :

*   **Frontend :** [Flutter](https://flutter.dev/) (Dart) - Pour une interface native et performante sur iOS, Android et Web.
*   **Backend :** [NestJS](https://nestjs.com/) (TypeScript) - API RESTful modulaire et scalable.
*   **Base de Données :** [MongoDB](https://www.mongodb.com/) - Stockage flexible des données (NoSQL).
*   **Conteneurisation :** [Docker](https://www.docker.com/) - Pour faciliter le déploiement de l'environnement backend et base de données.

---

## 🚀 Installation et Démarrage

### Prérequis
*   Flutter SDK
*   Docker Desktop
*   Node.js (optionnel si utilisation de Docker)

### 1. Démarrer le Backend (API & Base de Données)
Le backend est conteneurisé pour une installation rapide. Assurez-vous que Docker est lancé.

```bash
cd recruitment-app-backend-main
docker-compose up --build
```
L'API sera accessible sur `http://localhost:3000`.

### 2. Démarrer le Frontend (Application Flutter)

```bash
cd application_de_recrutement
flutter pub get
flutter run
```
*   **Web** : `flutter run -d chrome`
*   **Mobile** : Connectez votre appareil ou lancez un émulateur.

---

## 📂 Structure du Code

*   `application_de_recrutement/` : Code source de l'application Flutter.
    *   `lib/src/screens/` : Interfaces utilisateurs (Auth, Candidat, Entreprise).
    *   `lib/src/services/` : Communication avec l'API Backend.
    *   `lib/src/core/` : Configuration, Thèmes et Traductions.
*   `recruitment-app-backend-main/` : Code source de l'API NestJS.
    *   `src/modules/` : Modules fonctionnels (Auth, Job, Application, Chat).

---

## 📝 Licence

Ce projet est sous licence MIT. N'hésitez pas à l'utiliser et à l'améliorer.

---

*Développé avec ❤️ par [Votre Nom / Équipe]*
