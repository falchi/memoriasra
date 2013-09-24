#!/usr/bin/env bash
cat <<-EOF | psql -U bansia -d postgres
SELECT pg_terminate_backend(pg_stat_activity.procpid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'bansia';
EOF
rake db:drop db:create db:migrate db:seed