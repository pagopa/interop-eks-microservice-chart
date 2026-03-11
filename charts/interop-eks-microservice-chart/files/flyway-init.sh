if [ "$INTERNAL_DOWNLOAD_REDSHIFT_DRIVER" = "true" ]; then
  echo "Downloading Redshift JDBC driver..."
  curl -L -o /flyway/drivers/RedshiftJDBC.jar https://s3.amazonaws.com/redshift-downloads/drivers/jdbc/2.1.0.32/redshift-jdbc42-2.1.0.32.jar
else
  echo "Skip Redshift JDBC driver download."
fi

# Function to resolve a path that can be either a single file or a directory.
# If it's a file, it copies it to a temp directory and returns the temp directory path.
# If it's a directory, it returns the directory path as is.
resolve_location() {
  path="$1"
  if [ -f "$path" ]; then
      # Single file: copy into a temp dir and return that
      dirname "$path"
  elif [ -d "$path" ]; then
      echo "$path"
  else
      echo "ERROR: path does not exist or is not accessible: $path" >&2
      exit 1
  fi
}

LOCATIONS_ARG=""
if [ -n "$INTERNAL_FLYWAY_MIGRATIONS_PATHS" ]; then
  echo "INTERNAL_FLYWAY_MIGRATIONS_PATHS found: $INTERNAL_FLYWAY_MIGRATIONS_PATHS"
  locations="$INTERNAL_FLYWAY_MIGRATIONS_PATHS"
  #tmplist=$(mktemp)
  #echo "$INTERNAL_FLYWAY_MIGRATIONS_PATHS" | tr ',' '\n' > "$tmplist"

  #while IFS= read -r path; do
  #  path=$(echo "$path" | tr -d '[:space:]')
  #  [ -z "$path" ] && continue
  #  location=$(resolve_location "$path")
  #  locations="${locations:+$locations,}filesystem:$location"
  #done < "$tmplist"

  #rm -f "$tmplist"
  LOCATIONS_ARG="-locations=$locations"
  echo "Resolved locations: $locations"
else
  echo "INTERNAL_FLYWAY_MIGRATIONS_PATHS not set — using default Flyway locations."
fi

case "$INTERNAL_FLYWAY_ACTION" in
  "repair")
    echo "Starting Flyway repair..."
    flyway repair $LOCATIONS_ARG
    ;;
  "repair-and-migrate")
    echo "Starting Flyway repair && migration..."
    flyway repair $LOCATIONS_ARG && flyway migrate $LOCATIONS_ARG
    ;;
  "migrate")
    echo "Starting Flyway migration..."
    flyway migrate $LOCATIONS_ARG
    ;;
  *)
    echo "ERROR: Unknown flyway action: $INTERNAL_FLYWAY_ACTION"
    exit 1
    ;;
esac