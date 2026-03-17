# JTL Hub — Lieferantenverwaltung App

Eigenständige JTL Hub App für die vollständige Verwaltung von Lieferantenstammdaten, Ansprechpartnern, Zahlungsinformationen und Dokumenten.

## Tech-Stack

| Layer | Technologie |
|-------|------------|
| Backend | C# / ASP.NET Core 8, EF Core, FluentValidation |
| Frontend | React 18 + TypeScript, `@jtl-software/platform-ui-react` |
| Datenbank | PostgreSQL 16 (Database-per-Tenant) |
| Events | Apache Kafka (Confluent.Kafka) |
| Infrastruktur | Azure Container Apps, Terraform |
| CI/CD | GitHub Actions |

## Storybook

JTL Component Library: https://storybook.jtl-cloud.com/release/

## Projektstruktur

```
src/
├── backend/                    # C# ASP.NET Core Solution
│   ├── SupplierManagement.Api/
│   ├── SupplierManagement.Core/
│   ├── SupplierManagement.Infrastructure/
│   └── SupplierManagement.Tests/
├── frontend/                   # React + TypeScript
│   └── src/
│       ├── features/           # Feature-basierte Module
│       ├── components/         # Shared Components
│       ├── hooks/              # React Query Hooks
│       └── api/                # API Client
infra/                          # Terraform IaC
.github/workflows/              # CI/CD Pipelines
```

## Lokale Entwicklung

```bash
# Backend
cd src/backend
dotnet restore
dotnet run --project SupplierManagement.Api

# Frontend
cd src/frontend
npm install
npm run dev

# Alles via Docker
docker-compose up
```

## Linear Projekt

https://linear.app/jtl-supplier-management/project/jtl-hub-lieferantenverwaltung-app-c98b6af30f98
