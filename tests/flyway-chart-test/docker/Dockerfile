FROM flyway/flyway:latest

# Copy migration files into well-known paths inside the image.
# These paths are what INTERNAL_FLYWAY_MIGRATIONS_PATHS will reference at runtime.
COPY migrations/tenant/  /migrations/tenant/
COPY migrations/product/ /migrations/product/
COPY migrations/account/ /migrations/account/
