#!/bin/bash

# Supabase 설정
SUPABASE_URL="https://rmqsukldnmileszpndgh.supabase.co"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtcXN1a2xkbm1pbGVzenBuZGdoIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NTIwMzc4MSwiZXhwIjoyMDgwNzc5NzgxfQ.ll87JKJO8uU8xUlZrFnipH3AQsXGQPM1jfsJn2mYwq0"

# Migration SQL 파일 읽기
SQL_FILE="supabase/migrations/20260101_create_consultations.sql"

echo "🚀 Executing Supabase migration..."
echo "📁 File: $SQL_FILE"
echo ""

# SQL 파일 내용을 읽어서 Supabase RPC로 실행
SQL_CONTENT=$(cat "$SQL_FILE")

# Supabase의 SQL 실행을 위한 cURL 요청
curl -X POST "${SUPABASE_URL}/rest/v1/rpc/exec_sql" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $(jq -Rs . <<< "$SQL_CONTENT")}"

echo ""
echo "✅ Migration execution completed"
