# ARIA — Analyse et Retour Intelligent sur l'Allure
## Spécifications Générales — MVP v2.0

---

## 1. Contexte et problématique

La course à pied est l'une des pratiques sportives les plus répandues, mais aussi l'une des plus exposées aux blessures de surcharge. On estime qu'entre 50 % et 80 % des coureurs réguliers se blessent au moins une fois par an, la majorité de ces blessures étant directement liées à des anomalies biomécaniques de la foulée.

Lorsqu'un coureur blessé consulte un professionnel de santé du sport, l'évaluation biomécanique repose encore largement sur l'observation clinique directe. Cette approche est subjective, non reproductible et chronophage. Le praticien ne dispose pas d'un outil capable de quantifier objectivement les anomalies de foulée, de les corréler à la pathologie diagnostiquée, et de générer automatiquement un protocole de rééducation structuré et ancré dans la littérature médicale récente.

ARIA répond à ce besoin en proposant un système intelligent installé en cabinet médical. Le coureur blessé court sur le tapis de course du cabinet, filmé par une caméra sagittale fixe. ARIA analyse la foulée, corrèle les anomalies détectées à la pathologie déclarée, et génère un protocole de rééducation personnalisé, produit par un LLM fine-tuné sur des données cliniques.

---

## 2. Présentation du projet

**ARIA** (Analyse et Retour Intelligent sur l'Allure) est un système multi-agents de rééducation biomécanique déployé en cabinet médical. Il combine vision par ordinateur, analyse biomécanique automatisée et génération de protocoles cliniques par un LLM spécialisé.

Le système est développé dans le cadre d'un PFE sous forme de **MVP (Minimum Viable Product)**, avec une architecture split entre deux machines :

- **Mac M3** : orchestration des agents (LangGraph), interface utilisateur
- **PC RTX 4060 Ti** : inférence LLM (vLLM), fine-tuning SFT + DPO

ARIA ne remplace pas le professionnel de santé. Il lui fournit un outil d'aide à la décision objectif, reproductible et ancré dans la littérature médicale récente.

---

## 3. Objectifs du projet

**Objectif principal** : concevoir et prototyper un système multi-agents capable d'analyser la foulée d'un coureur blessé sur tapis de course, et de générer un protocole de rééducation biomécanique personnalisé via un LLM fine-tuné par SFT + DPO sur des données cliniques validées par la littérature médicale.

**Objectifs secondaires** :

- Construire un dataset clinique synthétique (SFT + DPO) couvrant les principales pathologies du coureur, validé par la littérature médicale de référence (PubMed, guidelines ACSM).
- Fine-tuner MedGemma 1.5 4B-it (Google DeepMind, janvier 2026 — pré-entraîné sur données médicales, EHRQA +22 pts vs version précédente) avec QLoRA (SFT) puis aligner avec DPO pour spécialiser le modèle sur la génération de protocoles de rééducation biomécanique en français clinique. Le modèle est servi en inférence via vLLM ≥ 0.19 sur le PC RTX 4060 Ti.
- Ingérer et traiter la vidéo sagittale d'un coureur sur tapis pour extraire des métriques biomécaniques fiables (YOLO26 Pose + ByteTrack).
- Implémenter un pipeline RAG (ChromaDB + sentence-transformers) pour la recherche sémantique dans un corpus de 300 à 600 abstracts PubMed indexés localement, enrichissant le contexte de ARIA-ft avec les articles les plus pertinents pour la combinaison pathologie + anomalies biomécaniques du patient.
- Croiser les anomalies détectées avec le profil de chaussure du patient via web grounding temps réel (Tavily / RunRepeat).
- Intégrer optionnellement les données d'entraînement du coureur (Strava / Garmin) pour contextualiser l'analyse.
- Proposer une interface de restitution exploitable directement par le praticien en cabinet.

---

## 4. Périmètre du projet (MVP)

### Ce que le projet couvre

- Analyse biomécanique de la foulée sur tapis de course en cabinet médical, plan sagittal uniquement.
- Pathologies du coureur prises en charge (6 pathologies MVP) :
  - Lombalgie (douleur lombaire à l'effort)
  - Tendinite rotulienne (syndrome fémoro-patellaire)
  - Syndrome de la bandelette ilio-tibiale (SBIT)
  - Périostite tibiale (shin splints)
  - Tendinite du tendon d'Achille
  - Fasciite plantaire
- Métriques biomécaniques extraites (plan sagittal) : cadence, attaque du pied, angle tibial à l'impact, oscillation verticale, penchée du tronc, longueur de foulée, flexion du genou.
- Construction d'un dataset SFT (60 paires) + DPO (42 triplets) et fine-tuning de MedGemma 4B-it via QLoRA/LoRA sur RTX 4060 Ti.
- Web grounding : PubMed API pour les protocoles de rééducation, Tavily/RunRepeat pour les specs chaussures en temps réel.
- Intégration optionnelle Strava / Garmin (historique d'entraînement, cadence, FC, charge hebdomadaire).
- Interface praticien : rapport biomécanique + protocole de rééducation + alerte équipement.

### Ce que le projet ne couvre pas (hors MVP)

- L'analyse frontale (symétrie gauche/droite, valgus dynamique, drop pelvien) — version ultérieure.
- La course en extérieur / sur route — hors contexte clinique MVP.
- La validation clinique formelle du système (études contrôlées, certification médicale).
- L'intégration dans un dossier médical électronique ou logiciel cabinet.
- Les pathologies hors liste des 6 MVP.
- Le déploiement multi-sites ou en environnement hospitalier.
- La planification automatique des séances de rééducation (voir section Perspectives v2.0).

### Perspectives v2.0 — Planification des séances de rééducation

Le protocole ARIA-ft définit déjà pour chaque patient les 3 phases de rééducation, les exercices associés et les durées recommandées. La v2.0 exploitera ces données structurées pour générer automatiquement un calendrier de séances personnalisé et envoyer des rappels au patient (SMS ou email).

Cette fonctionnalité est visible dans l'interface MVP sous forme de bloc verrouillé `[v2.0 🔒]`, permettant au praticien d'en percevoir la valeur sans qu'elle soit opérationnelle. Elle nécessitera en v2.0 une intégration avec un système de messagerie (ex : Twilio, SendGrid) et idéalement une connexion au logiciel agenda du cabinet.

---

## 5. Parties prenantes

| Partie prenante | Rôle | Attente principale |
|---|---|---|
| Kinésithérapeute / Podologue sportif | Utilisateur principal | Analyse biomécanique objective + protocole de rééducation structuré |
| Coureur blessé | Patient / sujet analysé | Comprendre l'origine biomécanique de sa blessure et recevoir un protocole adapté |
| Médecin du sport | Utilisateur secondaire | Complément de diagnostic par des données biomécaniques objectives |
| Tuteur académique | Encadrant PFE | Valider la rigueur méthodologique, technique et scientifique |
| Jury de soutenance | Évaluateur | Comprendre la valeur ajoutée, la faisabilité et la maîtrise technique |

---

## 6. Cas d'usage principaux (MVP)

**CU-01 — Analyse d'une session sur tapis**
Le praticien saisit la pathologie du patient et lance une session ARIA. Le coureur court sur le tapis à son allure habituelle pendant 2 à 3 minutes, filmé par la caméra sagittale fixe. Si le patient a connecté son compte Strava, ARIA récupère automatiquement son historique. ARIA analyse la foulée, corrèle les anomalies à la pathologie déclarée et produit un rapport structuré.

**CU-02 — Génération du protocole de rééducation et export PDF**
Sur la base de l'analyse biomécanique, de la pathologie déclarée et du profil de chaussure, ARIA génère un protocole de rééducation personnalisé via le LLM ARIA-ft (MedGemma 4B-it fine-tuné SFT + DPO). Le protocole est ancré dans la littérature médicale récente récupérée via PubMed API. Le LLM produit un rapport structuré au format Markdown, immédiatement converti en PDF par WeasyPrint. L'interface NiceGUI affiche la progression de l'analyse en temps réel via WebSocket, puis propose l'export PDF au praticien. Le document est imprimable et archivable dans le dossier patient sans manipulation supplémentaire.

**CU-03 — Suivi de l'évolution du patient**
À chaque nouvelle session, ARIA compare les métriques avec les sessions précédentes et mesure la progression vers les objectifs biomécaniques définis dans le protocole.

**CU-04 — Alerte équipement**
ARIA croise le profil de chaussure du patient (récupéré en temps réel via web grounding) avec les anomalies détectées. Si la chaussure aggrave la pathologie (ex : drop élevé + attaque talon + lombalgie), une alerte est générée avec une recommandation de transition vers une chaussure mieux adaptée.

---

## 7. Architecture technique (vue générale)

| Couche                 | Rôle                                                                                  | Technologies                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Couche 0 — Fine-tuning | Construction dataset + SFT + DPO                                                      | MedGemma 4B-it, QLoRA, LoRA, TRL, RTX 4060 Ti                                                           |
| Couche 1 — Ingestion   | Traitement vidéo sagittale, extraction clips                                          | YOLO26 Pose, ByteTrack, OpenCV, Python                                                                  |
| Couche 2 — Analyse     | Extraction métriques biomécaniques                                                    | YOLO26 keypoints, calculs angulaires                                                                    |
| Couche 3 — Agents      | Orchestration, RAG médical, web grounding, raisonnement                               | LangGraph (Mac M3), vLLM (RTX 4060 Ti), ChromaDB, sentence-transformers, Tavily, PubMed API, Strava API |
| Couche 4 — Outputs     | Interface praticien SPA, rapport Markdown généré par le LLM, export PDF patient       | Vue.js 3 + Vite (frontend SPA), FastAPI (backend REST + WebSocket), WeasyPrint (rendu PDF), Markdown   |

---

## 8. Contraintes du projet

**Contraintes de périmètre** : le MVP se concentre exclusivement sur l'analyse de foulée sur tapis en cabinet médical, pour les 6 pathologies définies. Toute extension est hors scope.

**Contraintes dataset** : en l'absence de partenariat clinique, le dataset SFT + DPO est construit de façon synthétique et validé par la littérature médicale de référence (PubMed, guidelines ACSM, études biomécaniques publiées). Cette limitation est explicitement reconnue et constitue la principale perspective d'évolution du système.

**Contraintes matérielles** : le système s'appuie sur deux machines personnelles (Mac M3 + PC RTX 4060 Ti). Aucune infrastructure cloud n'est utilisée.

**Contraintes temporelles** : le projet est réalisé dans le cadre d'un PFE. Le livrable est un prototype fonctionnel, non un produit certifié.

**Contraintes médicales** : le système ne revendique aucune certification médicale. Les recommandations générées sont des suggestions soumises à la validation du praticien.

---

## 9. Livrables attendus

- **Dataset clinique ARIA** : 60 paires SFT + 42 triplets DPO, documentés et versionnés (`aria_dataset_sft.jsonl`, `aria_dataset_dpo.jsonl`).
- **Modèle ARIA-ft** : MedGemma 4B-it fine-tuné (SFT + DPO), évalué contre le modèle MedGemma 4B-it de base non fine-tuné.
- **Prototype fonctionnel** : pipeline complet de la vidéo tapis au protocole de rééducation.
- **Rapport de PFE** : documentation complète du projet, des choix techniques et des résultats.
- **Présentation de soutenance** : support destiné au jury.

---

## 10. Critères de succès

- Le pipeline vidéo extrait des métriques biomécaniques cohérentes avec les données de référence MoCap issues de Ferber et al. 2024 (Nature Scientific Data, 1 798 sujets dont blessés, protocole tapis de course).
- Le modèle ARIA-ft produit des protocoles cliniquement supérieurs au modèle MedGemma 4B-it de base (non fine-tuné) sur un jeu d'évaluation humain (évaluation comparée sur 20 cas).
- Le système complet (vidéo → rapport + protocole) s'exécute en moins de 60 secondes sur les deux machines.
- Le prototype est stable et démontrable en conditions de soutenance.
- Le système génère un rapport PDF complet (métriques + protocole + sources) directement imprimable et archivable par le praticien.
- Les recommandations générées sont intelligibles et directement exploitables par un praticien non expert en IA.

---

*ARIA MVP v2.0 — Contexte : Cabinet médical / Tapis de course / Plan sagittal — SFT + DPO — Avril 2026*
