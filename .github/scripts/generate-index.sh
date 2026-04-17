#!/bin/bash

# Directory to scan (e.g., rpmbuild/repo or the destination directory)
DEPLOY_DIR="rpmbuild/repo"

# Output file (place index.html in the root directory)
OUTPUT_FILE="index.html"

# Start the HTML file
cat <<EOF > "$OUTPUT_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Podman AI Stack Repository</title>
</head>
<body>
    <h1>Podman AI Stack Repository</h1>
    <p>Browse the repository:</p>
    <ul>
EOF

# Add links for each subdirectory
for dir in "$DEPLOY_DIR"/*/; do
    dir_name=$(basename "$dir")
    echo "        <li><a href=\"rpms/$dir_name/\">$dir_name</a></li>" >> "$OUTPUT_FILE"
done

# End the HTML file
cat <<EOF >> "$OUTPUT_FILE"
    </ul>
</body>
</html>
EOF