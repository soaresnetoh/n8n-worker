#!/bin/bash
set -e

echo "=== PostgreSQL Init: n8n_app (PRODUCTION READY) ==="

export POSTGRES_NON_ROOT_USER
export POSTGRES_NON_ROOT_PASSWORD
export POSTGRES_DB

psql -v ON_ERROR_STOP=1 \
     -U "$POSTGRES_USER" \
     -d "$POSTGRES_DB" << EOF

-- ===============================
-- 1️⃣ Criação idempotente da role
-- ===============================

DO \$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = '${POSTGRES_NON_ROOT_USER}'
   ) THEN
      CREATE ROLE ${POSTGRES_NON_ROOT_USER}
         LOGIN
         NOSUPERUSER
         NOCREATEDB
         NOCREATEROLE
         NOINHERIT
         NOREPLICATION;
   END IF;
END
\$\$;

-- ===============================
-- 2️⃣ Garante senha atualizada
-- ===============================

ALTER ROLE ${POSTGRES_NON_ROOT_USER}
   WITH PASSWORD '${POSTGRES_NON_ROOT_PASSWORD}';

-- ===============================
-- 3️⃣ Permissões no banco
-- ===============================

GRANT CONNECT ON DATABASE ${POSTGRES_DB}
   TO ${POSTGRES_NON_ROOT_USER};

GRANT TEMPORARY ON DATABASE ${POSTGRES_DB}
   TO ${POSTGRES_NON_ROOT_USER};

-- ===============================
-- 4️⃣ Cria a extension uuid-ossp como superuser (aqui ainda é postgres)
--    e concede CREATE ON DATABASE para que o n8n possa recriar se precisar
-- ===============================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

GRANT CREATE ON DATABASE ${POSTGRES_DB}
   TO ${POSTGRES_NON_ROOT_USER};

-- ===============================
-- 5️⃣ Permissões no schema public
-- ===============================

GRANT USAGE ON SCHEMA public
   TO ${POSTGRES_NON_ROOT_USER};

GRANT CREATE ON SCHEMA public
   TO ${POSTGRES_NON_ROOT_USER};

-- ===============================
-- 6️⃣ Permissões nas tabelas existentes
-- ===============================

GRANT SELECT, INSERT, UPDATE, DELETE
   ON ALL TABLES IN SCHEMA public
   TO ${POSTGRES_NON_ROOT_USER};

GRANT USAGE, SELECT, UPDATE
   ON ALL SEQUENCES IN SCHEMA public
   TO ${POSTGRES_NON_ROOT_USER};

-- ===============================
-- 7️⃣ Permissões futuras (default)
-- ===============================

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT SELECT, INSERT, UPDATE, DELETE
   ON TABLES TO ${POSTGRES_NON_ROOT_USER};

ALTER DEFAULT PRIVILEGES IN SCHEMA public
   GRANT USAGE, SELECT, UPDATE
   ON SEQUENCES TO ${POSTGRES_NON_ROOT_USER};

EOF

echo "=== n8n_app ready ==="
