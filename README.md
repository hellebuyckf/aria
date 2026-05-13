# ARIA — Analyse et Retour Intelligent sur l'Allure

Système multi-agents de rééducation biomécanique pour la course à pied. ARIA analyse la foulée d'un coureur blessé sur tapis de course (caméra sagittale fixe), corrèle les anomalies détectées à la pathologie déclarée, et génère un protocole de rééducation personnalisé via un LLM fine-tuné sur données cliniques.

> MVP v2.0 — PFE IA & Santé 2025-2026

---

## Architecture

Tous les composants tournent sur **alpha-server (Linux)** via Docker Compose.

| Service | Rôle | Port |
|---|---|---|
| `aria_back` | Inférence LLM — vLLM (MedGemma 4B-it fine-tuné SFT + DPO) | 8001 |
| `aria_middle` | Orchestration LangGraph, pipeline vidéo, RAG, API FastAPI + WebSocket | 8000 |
| `aria_front` | Interface praticien (Vue.js 3, nginx) | 3000 |

### Pipeline vidéo → protocole

```
Vidéo sagittale tapis
  └─ MediaPipe Pose (BlazePose GHUM, 33 keypoints)
       └─ Métriques biomécaniques JSON
            └─ LangGraph (video_agent → rag_agent → report_agent)
                 ├─ RAG ChromaDB (300–600 abstracts PubMed)
                 ├─ Web grounding Tavily / PubMed API
                 └─ ARIA-ft (vLLM) → rapport Markdown → PDF WeasyPrint
```

### Pathologies couvertes (MVP)

Lombalgie · Tendinite rotulienne · SBIT · Périostite tibiale · Tendinite d'Achille · Fasciite plantaire

---

## Démarrage rapide

```zsh
# Premier clone
git clone --recurse-submodules <repo>
make init

# Lancer la stack complète
make build
make up

# Vérifier la santé des 3 services
make health
```

Ports exposés : `back=8001` · `middle=8000` · `front=3000`

**Prérequis** : Docker avec `nvidia-container-toolkit` installé (GPU requis pour aria_back).

---

## Structure du monorepo

```
aria/
├── aria_back/          ← vLLM + modèle ARIA-ft (submodule)
├── aria_middle/        ← FastAPI + LangGraph + MediaPipe (submodule)
├── aria_front/         ← Vue.js 3 + Vite (submodule)
├── docker-compose.yml  ← Orchestration des 3 services
├── Makefile            ← Commandes de gestion de la stack
└── ARIA_specs_generales.md
```

---

*ARIA MVP v2.0 — Cabinet médical / Tapis de course / Plan sagittal — Avril 2026*
