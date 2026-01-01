#!/bin/bash

# Supabase 데이터베이스 연결 정보
DB_HOST="db.rmqsukldnmileszpndgh.supabase.co"
DB_PORT="5432"
DB_NAME="postgres"
DB_USER="postgres"
DB_PASSWORD="your-db-password"  # 실제 비밀번호 필요

# Migration SQL 파일
SQL_FILE="supabase/migrations/20260101_create_consultations.sql"

echo "🚀 Executing Supabase migration via psql..."
echo "📁 File: $SQL_FILE"
echo "🔗 Host: $DB_HOST"
echo ""

# psql이 설치되어 있는지 확인
if ! command -v psql &> /dev/null; then
    echo "❌ psql is not installed"
    echo "   Install: brew install postgresql"
    exit 1
fi

# psql로 SQL 파일 실행
PGPASSWORD="$DB_PASSWORD" psql \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USER" \
  -d "$DB_NAME" \
  -f "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration executed successfully"
else
    echo ""
    echo "❌ Migration failed"
    exit 1
fi
