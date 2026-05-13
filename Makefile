.DEFAULT_GOAL := help

.PHONY: help build up down restart logs ps health init update \
        up-back up-middle up-front \
        logs-back logs-middle logs-front

COMPOSE := docker compose

# ── Aide ─────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "ARIA — Orchestration Docker"
	@echo "════════════════════════════════════════"
	@echo "  Stack complète"
	@echo "    make build      Construire toutes les images"
	@echo "    make up         Démarrer tous les services"
	@echo "    make down       Arrêter tous les services"
	@echo "    make restart    Redémarrer tous les services"
	@echo "    make ps         État des containers"
	@echo "    make health     Vérifier la santé des 3 services"
	@echo "    make logs       Logs de tous les services (live)"
	@echo "    make init       Initialiser et cloner les submodules (premier clone)"
	@echo "    make update     Pull git + mise à jour des submodules"
	@echo ""
	@echo "  Services individuels"
	@echo "    make up-back    Démarrer aria_back (vLLM GPU)"
	@echo "    make up-middle  Démarrer aria_middle (FastAPI)"
	@echo "    make up-front   Démarrer aria_front (nginx)"
	@echo "    make logs-back  Logs aria_back"
	@echo "    make logs-middle Logs aria_middle"
	@echo "    make logs-front Logs aria_front"
	@echo "════════════════════════════════════════"
	@echo "  Prérequis : nvidia-container-toolkit installé sur Debian"
	@echo "  Ports : back=8001  middle=8000  front=3000"
	@echo ""

# ── Stack complète ────────────────────────────────────────────────────────────
build: ## Construire toutes les images Docker
	$(COMPOSE) build

up: ## Démarrer tous les services en arrière-plan
	$(COMPOSE) up -d

down: ## Arrêter et supprimer les containers
	$(COMPOSE) down

restart: ## Redémarrer tous les services
	$(COMPOSE) restart

ps: ## État des containers
	$(COMPOSE) ps

logs: ## Suivre les logs de tous les services
	$(COMPOSE) logs -f

# ── Services individuels ──────────────────────────────────────────────────────
up-back: ## Démarrer aria_back uniquement (vLLM + GPU)
	$(COMPOSE) up -d aria_back

up-middle: ## Démarrer aria_middle uniquement (FastAPI)
	$(COMPOSE) up -d aria_middle

up-front: ## Démarrer aria_front uniquement (nginx)
	$(COMPOSE) up -d aria_front

logs-back: ## Logs aria_back (live)
	$(COMPOSE) logs -f aria_back

logs-middle: ## Logs aria_middle (live)
	$(COMPOSE) logs -f aria_middle

logs-front: ## Logs aria_front (live)
	$(COMPOSE) logs -f aria_front

# ── Santé ─────────────────────────────────────────────────────────────────────
health: ## Vérifier la santé des 3 services
	@echo "── aria_back (vLLM) ──"
	@curl -sf --max-time 5 http://localhost:8001/health \
		&& echo " ✓ ok" || echo " ✗ non joignable"
	@echo "── aria_middle (FastAPI) ──"
	@curl -sf --max-time 5 http://localhost:8000/health \
		&& echo " ✓ ok" || echo " ✗ non joignable"
	@echo "── aria_front (nginx) ──"
	@curl -sf --max-time 5 http://localhost:3000 > /dev/null \
		&& echo " ✓ ok" || echo " ✗ non joignable"

# ── Mise à jour ───────────────────────────────────────────────────────────────
init: ## Initialiser et cloner les submodules (premier clone)
	git submodule update --init --recursive

update: ## Pull git + mise à jour des submodules
	git pull
	git submodule update --init --remote --merge
