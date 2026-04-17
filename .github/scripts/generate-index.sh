#!/bin/bash

# Directory to scan for repositories
SCAN_DIR=${1:-"rpmbuild/repo"}
# Output directory for index.html and where gpg.key should be
DEST_DIR=${2:-"."}

# Output file
OUTPUT_FILE="$DEST_DIR/index.html"
GPG_KEY_FILE="gpg.key"

echo "Generating index.html..."
echo "  Scanning: $SCAN_DIR"
echo "  Output:   $OUTPUT_FILE"

# Start the HTML file
cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Podman AI Stack Repository</title>
    <style>
        body { font-family: sans-serif; line-height: 1.6; max-width: 800px; margin: 2rem auto; padding: 0 1rem; }
        pre { background: #f4f4f4; padding: 1rem; overflow-x: auto; border-radius: 4px; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>Podman AI Stack Repository</h1>
    <p>This is the official DNF repository for the Podman AI Stack.</p>
    
    <h2>Browse Repository</h2>
    <ul>
EOF

# Add links for each subdirectory in the SCAN_DIR
# Links must point to 'rpms/dir_name/' because DEST_DIR is the root
for dir in "$SCAN_DIR"/*/; do
    [ -d "$dir" ] || continue
    dir_name=$(basename "$dir")
    [ "$dir_name" == "repodata" ] && continue
    echo "        <li><a href=\"rpms/$dir_name/\">$dir_name</a></li>" >> "$OUTPUT_FILE"
done

# End the repository links section
cat <<EOF >> "$OUTPUT_FILE"
    </ul>
EOF

# Add GPG key content if the file exists
if [ -f "$GPG_KEY_FILE" ]; then
    echo "    <h2>GPG Key</h2>" >> "$OUTPUT_FILE"
    echo "    <p>Download the GPG key: <a href=\"gpg.key\">gpg.key</a></p>" >> "$OUTPUT_FILE"
    echo "    <pre>" >> "$OUTPUT_FILE"
    cat "$GPG_KEY_FILE" >> "$OUTPUT_FILE"
    echo "    </pre>" >> "$OUTPUT_FILE"
fi

# End the HTML file
cat <<EOF >> "$OUTPUT_FILE"
</body>
</html>
EOF
