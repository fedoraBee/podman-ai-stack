#!/bin/bash

# Directory to scan (e.g., rpmbuild/repo or the destination directory)
DEPLOY_DIR="rpmbuild/repo"

# Output file (place index.html in the repo directory)
OUTPUT_FILE="$DEPLOY_DIR/index.html"
GPG_KEY_FILE="gpg.key"

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
# Note: Since this index.html will be inside 'rpms/' on the web server, 
# and it scans 'rpmbuild/repo/' which is the same as 'rpms/', 
# the links should be relative or absolute from root.
for dir in "$DEPLOY_DIR"/*/; do
    dir_name=$(basename "$dir")
    [ "$dir_name" == "repodata" ] && continue
    echo "        <li><a href=\"$dir_name/\">$dir_name</a></li>" >> "$OUTPUT_FILE"
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