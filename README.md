# Starter App - Pipeline CI

[![CI Pipeline](https://github.com/LouisBertin40/CoursDevOps/actions/workflows/ci.yml/badge.svg)](https://github.com/LouisBertin40/CoursDevOps/actions/workflows/ci.yml)

## Description du pipeline CI
Ce dépôt intègre un pipeline GitHub Actions automatisé déclenché lors de chaque `push` sur la branche `main` et à chaque `pull request` :
- **Linting** : validation du style avec `flake8` (conformité PEP 8, longueur max 100 caractères).
- **Tests unitaires** : exécution de la suite `pytest` avec matrice multi-versions (Python 3.10, 3.11, 3.12).
- **Optimisation & Artefacts** : mise en cache du dossier pip pour réduire les temps de build et génération automatique du rapport de couverture HTML (`pytest-cov`), archivé en artefact de build.
- **Protection de branche** : les checks CI sont requis avant toute fusion vers `main`.