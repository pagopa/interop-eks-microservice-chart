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
  input_path="$1"

  if [ "${input_path#filesystem:}" != "$input_path" ]; then
    input_path="${input_path#filesystem:}"
  fi

  if [ -f "$input_path" ]; then
      dirname "$input_path"
  elif [ -d "$input_path" ]; then
      echo "$input_path"
  else
      echo "ERROR: path does not exist or is not accessible: $input_path" >&2
      exit 1
  fi
}

LOCATIONS_ARG=""
if [ -n "$INTERNAL_FLYWAY_MIGRATIONS_PATHS" ]; then
  echo "INTERNAL_FLYWAY_MIGRATIONS_PATHS found: $INTERNAL_FLYWAY_MIGRATIONS_PATHS"
  locations=""
  tmplist=$(mktemp)
  echo "$INTERNAL_FLYWAY_MIGRATIONS_PATHS" | tr ',' '\n' > "$tmplist"

  # Temporary workaround: assume INTERNAL_FLYWAY_MIGRATIONS_PATHS contains only one path (either file or directory) and resolve it directly without looping.
  first_path=$(head -n 1 "$tmplist" | tr -d '[:space:]')
  if [ -n "$first_path" ]; then
    location=$(resolve_location "$first_path")
    locations="filesystem:$location"
  fi


  #while IFS= read -r path; do
  #  path=$(echo "$path" | tr -d '[:space:]')
  #  [ -z "$path" ] && continue
  #  location=$(resolve_location "$path")
  #  locations="${locations:+$locations,}filesystem:$location"
  #done < "$tmplist"

  rm -f "$tmplist"
  if [ -n "$locations" ]; then
    LOCATIONS_ARG="-locations=$locations"
    echo "Resolved locations: $locations"
  else
    echo "Resolved locations: No valid paths found in INTERNAL_FLYWAY_MIGRATIONS_PATHS."
  fi
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