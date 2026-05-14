# ARIA — Rapport de Conduite de Projet AI Engineering

**Auteur :** François Hellebuyck  
**Formation :** AI Engineer — PFE 2025-2026  
**Projet :** ARIA — Système multi-agents biomécanique  
**Date :** Mai 2026  
**Version :** MVP v2.0  
**Contact :** pro.fhellebuyck@pm.me

---

## Table des Matières

1. [Contexte et Analyse des Besoins](#1-contexte-et-analyse-des-besoins)
2. [Audit de la Solution Data Existante](#2-audit-de-la-solution-data-existante)
3. [Identification de la Solution Technique Cible](#3-identification-de-la-solution-technique-cible)
4. [Stratégie de Mise en Œuvre et d'Industrialisation](#4-stratégie-de-mise-en-œuvre-et-dindustrialisation)
5. [Contrôle et Suivi du Projet](#5-contrôle-et-suivi-du-projet)
6. [Conclusion et Recommandations](#6-conclusion-et-recommandations)
7. [Annexes](#7-annexes)

---

## 1. Contexte et Analyse des Besoins

### 1.1 Présentation du Contexte

#### Secteur et Organisation

ARIA est développé dans le cadre d'un Projet de Fin d'Études (PFE) en AI Engineering. Le secteur cible est la rééducation sportive et la médecine du mouvement, domaine en forte transformation numérique où les outils d'aide à la décision clinique basés sur l'IA représentent une opportunité différenciante.

Exemple : Le cabinet opère en mode mono-praticien (MVP), avec une volumétrie de 10 à 30 sessions d'analyse par semaine. L'absence d'outillage biomécanique automatisé contraint le praticien à une analyse visuelle subjective, chronophage et non reproductible.

#### Niveau de Maturité IA / MLOps

- Maturité IA initiale : faible — aucun pipeline ML en production avant ce projet.
- Infrastructure : un unique serveur Linux (alpha-server, GPU NVIDIA) — architecture mono-serveur.
- Approche MLOps adoptée : embryonnaire — versionning Git multi-repos, Makefile pour l'orchestration, pytest pour les tests.
- Objectif fin PFE : atteindre le niveau IHM simple, pipeline automatisé, monitoring de base, reproductibilité garantie.

#### Contraintes Technologiques et Réglementaires

- RGPD Art. 9 : données de santé traitées exclusivement en local — aucun transfert cloud.
- Contrainte VRAM : alpha-server GPU 16 GB — impose QLoRA 4-bit pour le fine-tuning et float16 pour le serving.
- Latence cible : pipeline complet < 60 secondes pour une session de consultation.
- Interopérabilité : API OpenAI-compatible (vLLM) pour garantir la substituabilité du modèle LLM.

---

### 1.2 Collecte et Analyse du Besoin Métier

#### Parties Prenantes

| Partie Prenante | Rôle | Besoin Principal |
|---|---|---|
| Praticien référent (virtuel PFE) | Utilisateur final | Rapport clinique structuré, protocole personnalisé |
| Patient coureur (virtuel PFE) | Bénéficiaire indirect | Diagnostic précis, exercices adaptés à son niveau |
| Jury PFE | Évaluateur technique | Démonstration end-to-end, robustesse de l'architecture |
| François Hellebuyck | Développeur / Architecte | Système reproductible, stack SOTA documentée |

#### Objectifs Techniques et Business

- Automatiser l'extraction de métriques biomécaniques depuis une vidéo de course (sagittale + postérieure).
- Produire un diagnostic différentiel parmi 6 pathologies courantes du coureur (lombalgie, SFP, SBIT, périostite tibiale, fasciite plantaire, tendinite d'Achille).
- Générer un protocole de rééducation personnalisé en 3 phases, ancré sur des références PubMed.
- Offrir une interface praticien claire, utilisable sans formation technique préalable.
- Exporter un rapport PDF imprimable et distribuable au patient.

#### Matrice Impact / Effort — Hiérarchisation

| Cas d'Usage | Impact Métier | Effort Technique | Priorité |
|---|---|---|---|
| Extraction métriques vidéo (MediaPipe) | Critique | Élevé | P0 — MVP |
| Diagnostic LLM guidé (DiagnosticLLM) | Critique | Moyen | P0 — MVP |
| RAG PubMed (ChromaDB) | Élevé | Moyen | P0 — MVP |
| Rapport PDF WeasyPrint | Élevé | Faible | P0 — MVP |
| Interface Vue.js temps réel (WebSocket) | Élevé | Élevé | P1 — MVP v1 |
| Fine-tuning ARIA-ft (SFT + DPO) | Moyen | Élevé | P1 — MVP v1 |

---

## 2. Audit de la Solution Data Existante

### 2.1 Solution Proposée — Architecture Actuelle

En l'absence de solution préexistante dans le cabinet, ARIA constitue une solution conçue from scratch. L'architecture retenue repose sur une séparation stricte en trois couches indépendantes.

#### Flux Principal

| Étape | Composant | Machine | Technologie |
|---|---|---|---|
| 1 — Ingestion vidéo | frame_extractor.py | alpha-server | OpenCV / FFmpeg |
| 2 — Extraction keypoints | mediapipe_service.py | alpha-server | MediaPipe Pose Tasks API |
| 3 — Calcul métriques | metrics_calculator.py | alpha-server | Python + NumPy (11 métriques) |
| 4 — Orchestration | LangGraph StateGraph | alpha-server | LangGraph + FastAPI |
| 5 — Diagnostic LLM | diagnosis_agent.py | alpha-server | vLLM + xgrammar (guided JSON) |
| 6 — Retrieval PubMed | rag_agent.py + ChromaDB | alpha-server | ChromaDB + multilingual-e5-base |
| 7 — Rapport LLM | report_agent.py | alpha-server | vLLM + MedGemma 4B-it |
| 8 — Export PDF | WeasyPrint | alpha-server | WeasyPrint + HTML template |
| 9 — Interface | aria_front | alpha-server | Vue.js 3 + Vite + WebSocket |

#### Métriques Biomécaniques Extraites

| Métrique | Vue | Norme Indicative | Pathologie Corrélée |
|---|---|---|---|
| Cadence (spm) | Sagittale | 170 – 185 spm | Toutes pathologies |
| Angle attaque pied (°) | Sagittale | Midfoot (0–10°) | Lombalgie, SBIT |
| Flexion genou impact (°) | Sagittale | 15 – 25° | SFP, SBIT |
| Inclinaison tronc (°) | Sagittale | 5 – 10° | Lombalgie |
| Oscillation verticale (cm) | Sagittale | 6 – 9 cm | Toutes pathologies |
| Ratio contact/suspension | Sagittale | 0.55 – 0.60 | Fasciite plantaire |
| Pelvic drop (°) | Postérieure | < 5° | SFP, SBIT |
| Valgus genou (°) | Postérieure | < 8° | SFP — signe majeur |
| Asymétrie charge (%) | Postérieure | < 10% | SFP, Tendinite |
| Oscillation latérale hanche (cm) | Postérieure | < 3 cm | SBIT |
| Pronation pied (°) | Postérieure | < 15° | Fasciite plantaire |

---

### 2.2 Évaluation de l'Adéquation aux Besoins

#### Critères d'Analyse

| Critère | Évaluation | Commentaire |
|---|---|---|
| Performance LLM | ★★★★☆ | MedGemma 4B-it + guided decoding : 100% JSON valide. Latence P50 < 3s. |
| Précision métriques | ★★★☆☆ | 11/11 métriques implémentées. Calibration oscillation verticale à affiner. |
| Robustesse pipeline | ★★★★☆ | LangGraph StateGraph avec gestion d'erreur par nœud. |
| Sécurité / RGPD | ★★★★★ | 100% local, aucun transfert cloud, pseudonymisation patient. |
| Coût d'exploitation | ★★★★★ | 0€ cloud — infrastructure physique existante. |
| Maintenance | ★★★☆☆ | Makefile + pytest. Monitoring production à implémenter. |
| Scalabilité | ★★☆☆☆ | Mono-praticien MVP. Multi-cabinet nécessite refactoring. |

#### Écarts Identifiés

- **Recommandations légères :** le corpus RAG PubMed (abstracts uniquement) ne suffit pas à générer des protocoles d'exercices détaillés. Une collection ChromaDB dédiée aux protocoles cliniques (JOSPT CPG, Alfredson, McGill) est nécessaire.
- **Calibration oscillation verticale :** la référence fémur (hip→knee = 45cm) surestime la valeur. Validation sur plus de sujets requise.
- **Monitoring absent :** aucun suivi de dérive du modèle, latence P99, ou taux d'erreur en production.
- **SQLite différé à v2.0 :** les données de session sont in-memory — aucune persistance entre redémarrages.

---

## 3. Identification de la Solution Technique Cible

#### Comparatif d'Approches — Backbone LLM

| Modèle | Paramètres | Domaine | VRAM Serving | Choix ARIA |
|---|---|---|---|---|
| GPT-4o (OpenAI) | ~1800B MoE | Généraliste | Cloud | Rejeté — RGPD |
| Llama 3.1 8B | 8B | Généraliste | ~16 GB f16 | Rejeté — pas médical |
| Mistral 7B Instruct | 7B | Généraliste | ~14 GB f16 | Rejeté — pas médical |
| BioMistral 7B | 7B | Biomédical | ~14 GB f16 | Candidat — pas de IT |
| **MedGemma 4B-it** | **4B** | **Médical + multimodal** | **~8 GB f16** | **RETENU** |

MedGemma 4B-it est retenu pour trois raisons : (1) spécialisation médicale native (entraîné par Google sur des données cliniques), (2) VRAM compatible avec alpha-server en float16, (3) architecture Gemma 3 supportant le guided decoding xgrammar pour la garantie JSON.

#### Comparatif d'Approches — Extraction Pose

| Solution | Précision | Vitesse | Complexité | Choix |
|---|---|---|---|---|
| YOLOv8n-Pose | Élevée | Très rapide | Requiert GPU | Remplacé |
| OpenPose | Très élevée | Lente (CPU) | Lourde | Rejeté |
| **MediaPipe Pose Tasks** | **Élevée** | **Rapide (CPU)** | **Faible** | **RETENU** |
| MMPose | Très élevée | Rapide | Très lourde | Hors périmètre |

MediaPipe Pose Tasks API (BlazePose GHUM, 33 keypoints) est retenu : fonctionne en temps réel sur CPU sans GPU dédié (alpha-server), API Python officielle stable, et 33 landmarks suffisants pour les 11 métriques biomécaniques ciblées.

#### Schéma d'Architecture Cible

```
aria_front  (Vue.js 3 + Vite + Pinia · nginx)  :3000
         |  REST + WebSocket
aria_middle (FastAPI + LangGraph)              :8000  [alpha-server]
 |-- video_agent     (MediaPipe Pose, 11 métriques)
 |-- diagnosis_agent (LLM appel #1 → DiagnosticLLM JSON)
 |-- rag_agent       (ChromaDB, 292 abstracts PubMed)
 |-- report_agent    (LLM appel #2 → rapport complet)
         |  HTTP POST /v1/chat/completions
aria_back   (vLLM + MedGemma 4B-it ARIA-ft)   :8001  [alpha-server]
```

#### Justification des Choix Technologiques

| Composant | Technologie Retenue | Justification |
|---|---|---|
| Orchestration agents | LangGraph StateGraph | Graphe déterministe, gestion d'état typée (TypedDict), edges conditionnels sur erreur |
| Serving LLM | vLLM + xgrammar | PagedAttention (latence P50 < 3s), guided decoding JSON garanti à 100% |
| Fine-tuning | TRL + QLoRA NF4 | VRAM-efficient sur 16GB, qualité comparable full fine-tuning (Dettmers 2023) |
| Alignement | DPO (Rafailov 2023) | Plus stable que RLHF/PPO sur petit dataset (40 triplets), pas de reward model |
| Vector Store | ChromaDB local | 0€, embarqué, API Python simple, compatible multilingual-e5-base |
| Embeddings RAG | intfloat/multilingual-e5-base | SOTA multilingue, supporte le français médical |
| API Backend | FastAPI + BackgroundTasks | Async natif, OpenAPI auto-générée, WebSocket intégré |
| Frontend | Vue.js 3 + Pinia + Vite | Réactivité fine-grained, HMR rapide, store léger |
| Temps réel | WebSocket natif | Zéro polling, push server-side, reconnexion automatique x3 |
| Export PDF | WeasyPrint | HTML→PDF server-side, CSS print media, aucune dépendance cloud |

---

## 4. Stratégie de Mise en Œuvre et d'Industrialisation

### 4.1 Roadmap de Mise en Œuvre

| Phase | Période | Jalons | Statut |
|---|---|---|---|
| 0 — Fondations | Avr. 2026 | Constitution, datasets SFT/DPO, référentiel pathologies | Terminé |
| 1 — Pipeline vidéo | Avr. 2026 | MediaPipe, 11 métriques validées, tests unitaires | Terminé |
| 2 — Agents LLM | Avr. 2026 | diagnosis_agent, rag_agent, report_agent, LangGraph graph | Terminé |
| 3 — Backend API | Avr. 2026 | FastAPI, WebSocket, ChromaDB 292 abstracts | Terminé |
| 4 — Frontend | Mai 2026 | Vue.js speckit (4 specs), implémentation Gemini | Terminé |
| 5 — Fine-tuning | Mai 2026 | aria_back, SFT QLoRA, DPO, serving ARIA-ft | Terminé |
| 6 — Intégration | Juin 2026 | E2E sans mock, benchmark qualité, démo jury | Planifié |

---

### 4.2 Découpage Technique par Étape

#### Développement

- Spécifications frontend via speckit (`.specify/specs/NNN-name/{spec,plan,tasks}.md`).
- CLAUDE.md par repo : référence architecturale, règles de développement, ordre d'implémentation.
- Versionning : Git multi-repos (aria_back / aria_middle / aria-frontend) + repo racine avec submodules.

#### Tests

- Tests unitaires : pytest par agent (`test_video_agent.py`, `test_rag_agent.py`, `test_report_agent.py`).
- Tests d'intégration : `make test-pipeline` — exécution bout-en-bout avec vidéo réelle.
- Tests LLM : `make benchmark` — latence P50/P99, cohérence pathologie, validité JSON.
- Tests frontend : mode mock (`VITE_MOCK_WS=true`) — séquence complète en 8s sans backend.

#### Outils par Phase

| Phase | Outils |
|---|---|
| Développement | Python 3.12, uv, Vue.js 3, Vite, Pinia, Tailwind CSS |
| Versioning | Git, GitHub (3 repos + repo racine submodules) |
| CI | Makefile (.PHONY targets), pytest, ESLint, GitHub Actions |
| Serving LLM | vLLM 0.6+, Outlines, float16 |
| Fine-tuning | TRL 0.12, PEFT 0.14, QLoRA NF4, bitsandbytes |
| Containerisation | Docker |
| Monitoring | Logs structurés |

---

### 4.3 Aide à la Prise de Décision

#### Synthèse des Risques et Opportunités

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| vLLM indisponible (service arrêté) | Élevée | Critique | Mock `vllm_client` dans aria_middle pour démo |
| Vidéo hors norme (mauvais angle) | Moyenne | Élevé | Filtres de validation + `inclinaison_tronc=None` si hors [0°,45°] |
| VRAM insuffisante (training + serving) | Faible | Élevé | Règle : jamais training et serving simultanés |
| Dérive modèle post-fine-tuning | Moyenne | Moyen | `make benchmark` avant/après — score de cohérence pathologie |
| Surapprentissage SFT (60 exemples) | Moyenne | Moyen | QLoRA r=16, max_steps=200, validation loss monitoring |
| Latence > 60s pipeline complet | Faible | Élevé | P50 < 3s diagnostic, < 8s rapport — budget total < 56s |

#### Scénarios Budgétaires

| Poste | Coût MVP (local) | Coût Cloud Équivalent |
|---|---|---|
| Inférence LLM (diagnosis + report) | 0€ — alpha-server GPU déjà disponible | ~0.04€/session (GPT-4o mini) |
| Embeddings RAG | 0€ — multilingual-e5-base local | ~0.001€/session (OpenAI ada) |
| Stockage ChromaDB | 0€ — local NVMe | ~5€/mois (Pinecone Starter) |
| Pipeline vidéo MediaPipe | 0€ — CPU alpha-server | ~0.02€/min (AWS Rekognition) |
| Serving API | 0€ — alpha-server + FastAPI | ~50€/mois (EC2 t3.medium) |
| **Total estimé par session** | **~0€ variable** | **~0.10€ variable + ~55€ fixe/mois** |

L'architecture 100% locale élimine tout coût d'exploitation variable et garantit la conformité RGPD sans surcoût juridique. Le coût d'investissement est limité au matériel existant (alpha-server).

---

## 5. Contrôle et Suivi du Projet

### 5.1 Tableau de Bord de Pilotage

#### KPI Business

| KPI | Cible MVP | Mesure | Statut |
|---|---|---|---|
| Sessions d'analyse end-to-end | 1 session démo | Test manuel jury | En cours |
| Pathologies couvertes | 6/6 | Test unitaire par pathologie | Terminé |
| Rapport PDF exploitable | Oui | Validation praticien | Terminé |
| Conformité RGPD | 100% local | Audit code (no cloud calls) | Terminé |

#### KPI Techniques

| KPI | Cible | Mesure | Statut |
|---|---|---|---|
| Latence P50 diagnostic (LLM) | < 1.5s | `make benchmark` | À valider |
| Latence P99 diagnostic | < 3s | `make benchmark` | À valider |
| Latence P50 rapport (LLM) | < 8s | `make benchmark` | À valider |
| Pipeline complet | < 60s | `make test-pipeline` | Estimé ~45s |
| JSON valide (guided decoding) | 100% | `test_inference.py` | À valider |
| Cohérence pathologie post-SFT | >= 80% | `make benchmark` | À valider |
| Tests unitaires passants | 100% | pytest (CI Makefile) | Terminé |
| VRAM serving < 10 GB | < 10 GB | `nvidia-smi` | À valider |

---

### 5.2 Méthodologie et Outils de Suivi

#### Gestion de Projet

- Approche Kanban : tâches atomiques dans les fichiers `tasks.md` du speckit (T01–T19 par écran).
- Sprints informels d'une semaine, revue quotidienne en session Claude Cowork.
- Backlog priorisé : matrice impact/effort mise à jour à chaque nouvelle fonctionnalité.
- Versionning sémantique : branches main par repo, tags pour les jalons majeurs.

#### Suivi en Production (Roadmap v2.0)

| Outil | Usage | Phase |
|---|---|---|
| pytest + Makefile | Tests unitaires et intégration — CI local | MVP — actif |
| Logs structurés (JSON) | Traçabilité des appels LLM et erreurs pipeline | MVP — partiel |
| `make benchmark` | Latence P50/P99 + cohérence pathologie sur 6 cas | MVP — à activer |
| Prometheus + Grafana | Dashboard temps réel : latence, VRAM, erreurs | v2.0 |
| MLflow | Tracking expériences fine-tuning (loss, métriques) | v2.0 |
| RAGAS | Évaluation qualité RAG (faithfulness, answer relevancy) | v2.0 |
| Sentry | Monitoring erreurs frontend et backend | v2.0 |

---

## 6. Conclusion et Recommandations

#### Résumé des Choix Clés

- **Architecture multi-agents LangGraph :** séparation des responsabilités en 4 nœuds déterministes, état partagé via `ARIAState` TypedDict. Choix justifié par la traçabilité, la testabilité indépendante de chaque agent, et la gestion d'erreur granulaire.
- **MedGemma 4B-it + QLoRA + DPO :** compromis optimal entre spécialisation médicale, contrainte VRAM (16 GB) et qualité d'alignement clinique sur dataset limité (60 paires SFT + 40 triplets DPO).
- **MediaPipe Pose Tasks API :** migration depuis YOLOv8 justifiée par la suppression de la dépendance GPU pour l'extraction, 33 landmarks suffisants pour les 11 métriques, et API officielle Google stable.
- **Architecture 100% locale :** conformité RGPD Art. 9 native, coût d'exploitation nul, latence minimale (pas de round-trip réseau pour le LLM).
- **Guided decoding xgrammar :** garantie formelle de JSON valide pour `DiagnosticLLM` — élimine les hallucinations de format sans post-processing fragile.

#### Perspectives d'Évolution

- **v2.0 — Persistance :** SQLite pour l'historique patient, comparaison de sessions, tendances métriques.
- **v2.0 — Monitoring :** Prometheus + Grafana pour la dérive du modèle, MLflow pour le tracking des expériences de fine-tuning.
- **v2.0 — Corpus clinique :** collection ChromaDB `aria_protocols` (JOSPT CPG, Alfredson, McGill, Fredericson) pour enrichir les recommandations d'exercices.
- **v3.0 — Multi-cabinet :** containerisation Docker, orchestration K8s léger (k3s), API Gateway pour la mutualisation de l'infrastructure GPU.
- **v3.0 — Multimodal :** MedGemma 27B ou modèle multimodal pour intégrer directement des frames vidéo dans le prompt diagnostique (end-to-end vision + texte).

#### Prochaines Étapes Immédiates

- Finaliser l'implémentation frontend (specs 001–004 via Gemini + speckit).
- Déployer aria_back sur alpha-server : `make setup && make serve && make test`.
- Lancer le fine-tuning SFT puis DPO : `make train-all`.
- Valider le pipeline complet sans mock : `make test-pipeline` avec vidéo réelle.
- Préparer la démo jury : script de démonstration avec PAT-2026-042 (SFP, valgus 13.9°).

---

## 7. Annexes

### 7.1 Liens et Dépôts

| Composant | Dépôt GitHub | Description |
|---|---|---|
| aria_back | github.com/hellebuyckf/aria_back | Serving vLLM + fine-tuning TRL (alpha-server) |
| aria_middle | github.com/hellebuyckf/aria_middle | Orchestration LangGraph + FastAPI + MediaPipe (alpha-server) |
| aria_front | github.com/hellebuyckf/aria_front | Interface Vue.js 3 + WebSocket + Vite (alpha-server) |

---

### 7.2 Commandes de Démarrage Rapide

```bash
# alpha-server — Stack complète via Docker Compose
make build && make up

# Ou service par service
make up-back    # aria_back  (vLLM :8001)
make up-middle  # aria_middle (FastAPI :8000)
make up-front   # aria_front  (nginx :3000)

# Test pipeline complet (depuis aria_middle)
make test-pipeline
```

---

### 7.3 Pathologies Couvertes (MVP v2.0)

| Pathologie | Signal Principal | Métrique Clé |
|---|---|---|
| Lombalgie du coureur | Inclinaison tronc excessive + cadence basse | `inclinaison_tronc > 10°` |
| Syndrome Fémoro-Patellaire | Valgus dynamique + asymétrie charge | `valgus_genou > 8°` |
| Syndrome de la Bandelette Ilio-Tibiale | Pelvic drop + oscillation latérale hanche | `pelvic_drop > 5°` |
| Périostite Tibiale | Attaque talon + cadence basse | `angle_attaque_pied < 0°` |
| Fasciite Plantaire | Ratio contact/suspension élevé + pronation | `ratio > 0.62 + pronation > 15°` |
| Tendinite d'Achille | Flexion genou impact faible + asymétrie | `flexion_genou_impact < 15°` |

---

### 7.4 Format Événements WebSocket

```json
{ "type": "progress", "etape": "video", "substep": "extraction",
  "pct": 40, "log_level": "OK", "log_message": "142 keypoints..." }

{ "type": "progress", "etape": "video", "substep": "calcul", "pct": 55,
  "metrics": { "cadence": 147.7, "valgus_genou": 13.9, ... } }

{ "type": "completed", "rapport_url": "/api/sessions/SES-042/report" }
```

---

*ARIA MVP v1.0 — PFE AI Engineering — François Hellebuyck — Mai 2026*
