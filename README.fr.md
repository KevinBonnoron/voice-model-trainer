# Entraînement d’un Modèle Vocal - Guide de Démarrage

Ce projet vous permet d’entraîner votre propre modèle de voix à partir de données audio personnalisées.

## 🚀 Pour bien démarrer

### 1. Construire l’image Docker

Avant toute chose, vous devez construire l’image Docker qui contient tous les outils nécessaires.

Depuis la racine du projet, exécutez :

```bash
./build.sh
```

Ce script va créer une image Docker (ex. : `voice-model-trainer`) utilisée pour l’entraînement.

---

### 2. Lancer le pipeline d'entraînement

Une fois l’image construite, utilisez le script `run.sh` pour exécuter les étapes principales du pipeline d'entraînement dans le conteneur Docker.

Le script accepte les sous-commandes suivantes :

#### Prétraitement

Prépare vos données audio et texte avant l'entraînement :

```bash
./run.sh preprocess -i /chemin/vers/les/données -o /chemin/vers/le/répertoire-de-sortie
```

- `-i`, `--input` : Chemin vers le jeu de données brut (obligatoire)
- `-o`, `--output` : Répertoire où seront sauvegardées les données prétraitées (obligatoire)

#### Entraînement

Démarre l'entraînement du modèle vocal :

```bash
./run.sh train [options]
```

Exemple :

```bash
./run.sh train -d ./data -a gpu --devices 1 -b 32 -m 10000 -p 32
```

Options disponibles :

- `-d`, `--dataset-dir PATH`         : Chemin vers le répertoire du jeu de données (obligatoire)
- `-a`, `--accelerator`              : Matériel à utiliser : `cpu` ou `gpu` (par défaut : `gpu`)
- `--devices`                        : Nombre d'appareils à utiliser (ex. : nombre de GPUs) (par défaut : `1`)
- `-v`, `--validation-split FLOAT`   : Pourcentage des données utilisées pour la validation (par défaut : `0.0`)
- `-b`, `--batch-size INT`           : Taille des lots d'entraînement (par défaut : `32`)
- `-m`, `--max-epochs INT`           : Nombre maximal d'époques d'entraînement (par défaut : `10000`)
- `-p`, `--precision PRECISION`      : Précision numérique : `16`, `32`, `64`, `bf16`, ou `mixed` (par défaut : `32`)
- `-r`, `--resume-from-checkpoint`   : Chemin vers un checkpoint pour reprendre l'entraînement
- `-h`, `--help`                     : Afficher l'aide et quitter

---

## 📁 Structure des données

Organisation recommandée du répertoire :

```
/votre-dataset/
├── audio.wav
├── transcript.txt
└── ...
```

Les chemins peuvent être absolus ou relatifs à la racine du projet.

---

## 🛠 Prérequis

- Docker
- Shell compatible Bash (bash, zsh…)

Aucune installation locale de Python n’est nécessaire : tout est exécuté dans le conteneur.

---

## ❓ Besoin d’aide ?

Utilisez :

```bash
./run.sh preprocess --help
./run.sh train --help
```

pour afficher toutes les options disponibles.
