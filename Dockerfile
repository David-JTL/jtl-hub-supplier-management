# ============================================
# Stage 1: Build Frontend (React + Vite)
# ============================================
FROM node:22-alpine AS frontend-build
WORKDIR /app/frontend

COPY src/frontend/package.json src/frontend/package-lock.json ./
RUN npm ci

COPY src/frontend/ .
RUN npm run build

# ============================================
# Stage 2: Build Backend (ASP.NET Core)
# ============================================
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS backend-build
WORKDIR /src

COPY src/backend/SupplierManagement.sln .
COPY src/backend/SupplierManagement.Api/SupplierManagement.Api.csproj SupplierManagement.Api/
COPY src/backend/SupplierManagement.Core/SupplierManagement.Core.csproj SupplierManagement.Core/
COPY src/backend/SupplierManagement.Infrastructure/SupplierManagement.Infrastructure.csproj SupplierManagement.Infrastructure/
COPY src/backend/SupplierManagement.Tests/SupplierManagement.Tests.csproj SupplierManagement.Tests/

RUN dotnet restore

COPY src/backend/ .
RUN dotnet publish SupplierManagement.Api/SupplierManagement.Api.csproj -c Release -o /app/publish --no-restore

# ============================================
# Stage 3: Runtime (Backend serves Frontend)
# ============================================
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

COPY --from=backend-build /app/publish .
COPY --from=frontend-build /app/frontend/dist ./wwwroot

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

ENTRYPOINT ["dotnet", "SupplierManagement.Api.dll"]
