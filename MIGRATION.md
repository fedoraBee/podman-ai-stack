# Upgrading & Migration Guide

## Upgrading from v0.4.x to v0.5.x

Version 0.5.x introduces optional support for PostgreSQL to handle Open WebUI
state, providing better scalability compared to the default SQLite database.

**⚠️ Important: PostgreSQL is strictly OPT-IN.** If you are upgrading an
existing v0.4.x installation, **no action is required**. Your existing SQLite
database will remain intact, untouched, and will continue to function normally.
We do not silently break existing user setups.

### Migrating from SQLite to PostgreSQL (Optional)

If your deployment has grown and you explicitly wish to transition your existing
SQLite data to PostgreSQL, follow these steps:

1. **Export Existing Data:** Log into your current Open WebUI instance as an
   Administrator. Navigate to **Admin Panel > Settings > Workspace > Data** and
   click **Export All Data**. This will download a JSON file containing your
   users, chats, prompts, and configurations.

2. **Backup Volumes (Safety First):** Run the included disaster recovery script
   to snapshot your data before making changes:

   ```bash
   ./scripts/backup-ai-stack.sh
   ```

3. **Enable PostgreSQL:** Edit `/etc/sysconfig/podman-ai-stack` (or your local
   configuration) and set the `DATABASE_URL` variable as documented in the
   README. Ensure you have the `postgres.container` quadlet enabled.

4. **Restart the Stack:** Reload your systemd daemon and restart the pod. Open
   WebUI will detect the new `DATABASE_URL` and initialize a fresh, empty
   PostgreSQL database.

   ```bash
   systemctl --user daemon-reload
   systemctl --user restart podman-ai-stack-pod
   ```

5. **Import Data:** Create an initial admin account on the fresh
   PostgreSQL-backed instance. Navigate back to **Admin Panel > Settings >
   Workspace > Data** and click **Import Data**, uploading the JSON file you
   exported in Step 1.
