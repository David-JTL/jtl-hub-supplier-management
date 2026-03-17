# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files first (for layer caching)
COPY SupplierManagement.sln .
COPY SupplierManagement.Api/SupplierManagement.Api.csproj SupplierManagement.Api/
COPY SupplierManagement.Core/SupplierManagement.Core.csproj SupplierManagement.Core/
COPY SupplierManagement.Infrastructure/SupplierManagement.Infrastructure.csproj SupplierManagement.Infrastructure/

RUN dotnet restore

# Copy everything and build
COPY . .
RUN dotnet publish SupplierManagement.Api/SupplierManagement.Api.csproj -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

COPY --from=build /app/publish .

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

ENTRYPOINT ["dotnet", "SupplierManagement.Api.dll"]
