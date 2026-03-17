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

# Copy everything at once (simpler, avoids path issues)
COPY src/backend/ .

# Restore and publish only the API project
RUN dotnet restore SupplierManagement.Api/SupplierManagement.Api.csproj
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
