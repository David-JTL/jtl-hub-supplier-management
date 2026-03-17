# CLAUDE.md — JTL Hub Lieferantenverwaltung App

## Projekt-Übersicht

JTL Hub App für die Verwaltung von Lieferantenstammdaten, Ansprechpartnern, Zahlungsinformationen und Dokumenten. Die App integriert sich in das JTL ERP-System über das JTL Hub App Manifest.

**Linear Projekt:** https://linear.app/jtl-supplier-management/project/jtl-hub-lieferantenverwaltung-app-c98b6af30f98
**JTL Storybook:** https://storybook.jtl-cloud.com/release/
**JTL App Manifest Docs:** https://developer.jtl-software.com/products/appregistration/manifest

## Tech-Stack

### Backend
- **Sprache:** C# / .NET 8
- **Framework:** ASP.NET Core Web API
- **ORM:** Entity Framework Core 8 + Npgsql
- **Validation:** FluentValidation
- **Mapping:** AutoMapper
- **Events:** Confluent.Kafka (Producer + Consumer)
- **Cache:** IDistributedCache (Redis)
- **Blob:** Azure.Storage.Blobs
- **Auth:** JWT Bearer (perspektivisch JTL IDP)

### Frontend
- **Framework:** React 18 + TypeScript
- **Component Library:** `@jtl-software/platform-ui-react`
  - Layout: Box, Grid, Stack, Layout, LayoutSection, Card
  - Forms: Button, Checkbox, Input, InputOTP, Radio, Select, Textarea, Switch, Toggle, ToggleGroup, FormGroup, Form
  - Display: Text, Badge, Avatar, Table, DataTable, Progress
  - Navigation: Link, Breadcrumb, Tab, Dropdown
  - Feedback: Alert, Dialog, AlertDialog, Tooltip, Skeleton
  - Utility: Icon, Separator, ScrollArea, Collapsible, Popover, Sheet
- **State:** React Query (TanStack Query) für Server-State
- **Forms:** React Hook Form + Zod

### Infrastruktur
- **Cloud:** Azure (Container Apps, PostgreSQL Flexible Server, Blob Storage, Redis Cache)
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Container:** Docker (Frontend: node→nginx, Backend: .NET SDK→runtime)
- **Events:** Apache Kafka (Azure Event Hubs kompatibel)
- **Tunnel:** VPN/WireGuard für On-Premise JTL-Wawi Anbindung

### Datenbank
- **Engine:** PostgreSQL 16
- **Strategie:** Database-per-Tenant (jeder Mandant hat eigene DB)
- **Management-DB:** Zentrale DB für Tenant-Registry

## Architektur

```
JTL Cloud / Hub (IDP, Cloud API, ERP Shell)
    │
    ▼
┌─────────────────────────────────────────────┐
│  Beschaffungs-App (Azure Container Apps)    │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │ Frontend  │  │ Backend  │  │ Auth/     │ │
│  │ React +   │  │ ASP.NET  │  │ Multi-    │ │
│  │ JTL UI    │  │ Core API │  │ Tenant    │ │
│  └──────────┘  └──────────┘  └───────────┘ │
│  ┌─────────────────┐ ┌───────────────────┐  │
│  │ Event-System    │ │ Business Rules    │  │
│  │ Kafka Producer  │ │ Engine + AI Agent │  │
│  └─────────────────┘ └───────────────────┘  │
└─────────────────────────────────────────────┘
    │              │              │
    ▼              ▼              ▼
PostgreSQL      Azure Blob    Redis Cache
(per Tenant)    (Dokumente)   (Sessions)
    │
    ▼ (Tunnel)
JTL-Wawi (On-Premise)
```

## Multi-Tenant-Architektur

- Zentrale `tenants` Tabelle in Management-DB
- ASP.NET Core Middleware extrahiert `tenant_id` aus JWT
- `TenantDbContextFactory` erzeugt DbContext mit Tenant-spezifischem Connection String
- Tenant-Config gecached in Redis (TTL 5 Min)
- Blob Storage Pfad: `{tenantId}/{supplierId}/{category}/{fileName}`
- Kafka Topic: `supplier-events.{tenantId}`

## Projektstruktur (empfohlen)

```
/
├── src/
│   ├── backend/
│   │   ├── SupplierManagement.Api/          # ASP.NET Core Web API
│   │   │   ├── Controllers/
│   │   │   ├── Middleware/                   # TenantMiddleware, etc.
│   │   │   └── Program.cs
│   │   ├── SupplierManagement.Core/         # Domain Models, Interfaces
│   │   │   ├── Entities/
│   │   │   ├── Interfaces/
│   │   │   └── DTOs/
│   │   ├── SupplierManagement.Infrastructure/ # EF Core, Kafka, Blob
│   │   │   ├── Data/                        # DbContext, Migrations
│   │   │   ├── Services/                    # VIES, IBAN, Kafka, Blob
│   │   │   └── Interceptors/               # LifecycleEventInterceptor
│   │   └── SupplierManagement.Tests/
│   └── frontend/
│       ├── src/
│       │   ├── components/                  # Shared UI Components
│       │   ├── features/
│       │   │   ├── search/                  # Lieferantensuche
│       │   │   ├── supplier-detail/         # Detailansicht
│       │   │   │   ├── MasterDataTab/
│       │   │   │   ├── ContactsTab/
│       │   │   │   ├── FinanceTab/
│       │   │   │   └── DocumentsTab/
│       │   │   ├── rules-admin/             # BRE Administration
│       │   │   └── agent/                   # KI-Agent Chat
│       │   ├── hooks/                       # React Query hooks
│       │   ├── api/                         # API Client
│       │   └── types/                       # TypeScript Types
│       └── package.json
├── infra/                                   # Terraform
│   ├── main.tf
│   ├── modules/
│   └── environments/
├── docker-compose.yml
├── .github/workflows/
└── manifest.json                            # JTL Hub App Manifest
```

## DB-Schema (Kern-Entitäten)

### suppliers
id (UUID PK), tenant_id, name, short_name, number, legal_form, street, house_number, postal_code, city, country, hrb, court, tax_number, vat_id, vat_verified, industry_code, status (active/inactive), supplier_type, created_at, updated_at, created_by, updated_by

### contacts
id, supplier_id (FK), salutation, first_name, last_name, position, phone, mobile, email, is_primary, is_default, has_custom_address, street, postal_code, city, country

### bank_accounts
id, supplier_id (FK), iban, bic, bank_name, account_holder, currency, is_default, iban_verified

### payment_terms
id, supplier_id (FK), term_type (skonto/netto/valuta/netto_kasse), percentage, days

### supplier_locks
id, supplier_id (FK), lock_type (order_lock/payment_lock), reason, comment, locked_by, locked_at, unlocked_by, unlocked_at

### documents
id, supplier_id (FK), category, subcategory, title, file_name, blob_path, file_size, uploaded_by, uploaded_at, metadata (JSONB)

### audit_log
id, supplier_id (FK), entity_type, entity_id, action, previous_state (JSONB), current_state (JSONB), changed_fields[], user_id, created_at

### business_rules
id, tenant_id, name, event_type, entity_type, condition (JSONB), action_type, action_config (JSONB), severity, infopane_text, rule_prompt, validation_prompt, message_prompt, priority, is_active

## API-Endpoints (Übersicht)

```
# Suppliers
GET    /api/suppliers                        # Liste (Pagination, Filter)
GET    /api/suppliers/search?q=              # Volltextsuche
GET    /api/suppliers/favorites              # Favoriten
GET    /api/suppliers/recent                 # Zuletzt bearbeitet
POST   /api/suppliers                        # Erstellen
GET    /api/suppliers/{id}                   # Detail
PUT    /api/suppliers/{id}                   # Aktualisieren
DELETE /api/suppliers/{id}                   # Löschen
POST   /api/suppliers/{id}/favorite          # Favorit setzen
DELETE /api/suppliers/{id}/favorite          # Favorit entfernen
POST   /api/suppliers/{id}/verify-vat        # VIES Validierung

# Contacts
GET    /api/suppliers/{id}/contacts
POST   /api/suppliers/{id}/contacts
PUT    /api/suppliers/{id}/contacts/{cId}
DELETE /api/suppliers/{id}/contacts/{cId}
PUT    /api/suppliers/{id}/contacts/{cId}/set-primary
PUT    /api/suppliers/{id}/contacts/{cId}/set-default

# Bank Accounts
GET    /api/suppliers/{id}/bank-accounts
POST   /api/suppliers/{id}/bank-accounts
PUT    /api/suppliers/{id}/bank-accounts/{baId}
DELETE /api/suppliers/{id}/bank-accounts/{baId}
PUT    /api/suppliers/{id}/bank-accounts/{baId}/set-default
POST   /api/bank/validate-iban

# Payment Terms
GET    /api/suppliers/{id}/payment-terms
POST   /api/suppliers/{id}/payment-terms
PUT    /api/suppliers/{id}/payment-terms/{ptId}
DELETE /api/suppliers/{id}/payment-terms/{ptId}

# Locks
GET    /api/suppliers/{id}/locks
POST   /api/suppliers/{id}/locks
PUT    /api/suppliers/{id}/locks/{lockId}/release
GET    /api/suppliers/{id}/locks/history

# Documents
GET    /api/suppliers/{id}/documents
POST   /api/suppliers/{id}/documents/upload
GET    /api/suppliers/{id}/documents/{docId}/download
DELETE /api/suppliers/{id}/documents/{docId}

# Audit Log
GET    /api/suppliers/{id}/audit-log
POST   /api/suppliers/{id}/audit-log         # Manueller Eintrag

# InfoPane
GET    /api/suppliers/{id}/infopane-messages

# Business Rules Admin
GET    /api/admin/rules
POST   /api/admin/rules
PUT    /api/admin/rules/{id}
DELETE /api/admin/rules/{id}
PUT    /api/admin/rules/{id}/toggle
PUT    /api/admin/rules/reorder

# Tunnel Health
GET    /api/tunnel/health

# Custom Fields
GET    /api/admin/custom-fields
POST   /api/admin/custom-fields
PUT    /api/admin/custom-fields/{id}
DELETE /api/admin/custom-fields/{id}
```

## Lifecycle-Events

Bei jeder CRUD-Operation auf Geschäftsobjekten werden automatisch Events gefeuert:

- `onCreating` / `onCreated` — vor/nach Anlage
- `onUpdating` / `onUpdated` — vor/nach Aktualisierung
- `onDeleting` / `onDeleted` — vor/nach Löschung
- `onStatusChanging` / `onStatusChanged` — vor/nach Statuswechsel

**Event-Payload:**
```json
{
  "eventType": "onUpdated",
  "entityType": "supplier",
  "entityId": "uuid",
  "tenantId": "uuid",
  "userId": "uuid",
  "timestamp": "2026-03-17T12:00:00Z",
  "previousState": { ... },
  "currentState": { ... },
  "changedFields": ["name", "vat_id"]
}
```

## Milestones (Umsetzungsreihenfolge)

1. **M1 — Infrastruktur & Plattform-Integration** (Voraussetzung für alles)
2. **M2 — Lieferantensuche & Navigation**
3. **M3 — Tab Stammdaten** (Kern-CRUD)
4. **M4 — Tab Kontakte**
5. **M5 — Tab Finanzen**
6. **M6 — Tab Dokumente & Historie**
7. **M7 — Kafka Events & InfoPane**
8. **M8 — Business Rules Engine**
9. **M9 — KI-Agent & Automatisierung**

## Konventionen für Claude Code

- **Branch-Naming:** `feature/JTL-{nr}-kurzbeschreibung`
- **Commit-Messages:** `feat(JTL-{nr}): Kurzbeschreibung` oder `fix(JTL-{nr}): ...`
- **Issue-Status nach Abschluss:** `Done` setzen
- **Tests:** Jeder Task soll Unit-Tests beinhalten (xUnit für C#, Vitest für React)
- **JTL Components first:** Immer zuerst prüfen ob eine JTL Component Library Komponente existiert, bevor eine eigene gebaut wird
