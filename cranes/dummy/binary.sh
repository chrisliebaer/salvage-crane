#!/bin/sh

# Display a fancy header for the crane info
cat << EOF
╔════════════════════════════════════════════════════════════════╗
║                       SALVAGE CRANE INFO                       ║
╚════════════════════════════════════════════════════════════════╝
EOF

echo "🏗️  I'm crane ${SALVAGE_CRANE_NAME} supposed to be backing up ${SALVAGE_VOLUME_NAME} on ${SALVAGE_MACHINE_NAME}"

# Environment variables section
cat << EOF

╔════════════════════════════════════════════════════════════════╗
║                     ENVIRONMENT VARIABLES                      ║
╚════════════════════════════════════════════════════════════════╝
EOF
env

# Current directory section
cat << EOF

╔════════════════════════════════════════════════════════════════╗
║                     EXECUTION ENVIRONMENT                      ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo "📂 I'm currently running in: $(pwd)"

# Meta information section
cat << EOF

╔════════════════════════════════════════════════════════════════╗
║                       META INFORMATION                         ║
╚════════════════════════════════════════════════════════════════╝
EOF
cat "/salvage/meta/meta.json"; echo

# Backup information section
cat << EOF

╔════════════════════════════════════════════════════════════════╗
║                      BACKUP INFORMATION                        ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo "📊 Contents of backup volume:"
ls -lA "/salvage/volume"

# Processing section
cat << EOF

╔════════════════════════════════════════════════════════════════╗
║                       PROCESSING BACKUP                        ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo "⏳ Now I will wait 2 minutes so it feels like I'm actually doing any work..."
sleep 2m
echo "✅ Backup process completed!"
