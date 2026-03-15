# household-auth edge function

Minimal auth + household create/join for Supabase.

## Env vars
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_SECRET`

## Run locally
```bash
cd "/Users/eduard/Downloads/Ez Menu Generator/supabase/functions/household-auth"
deno task start
```

## Tests
```bash
cd "/Users/eduard/Downloads/Ez Menu Generator/supabase/functions/household-auth"
deno task test
```

## Create household
```bash
curl -i -X POST \
  "http://localhost:8000" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","username":"Ion","household_name":"Familia Ion"}'
```

## Join household
```bash
curl -i -X POST \
  "http://localhost:8000" \
  -H "Content-Type: application/json" \
  -d '{"action":"join","username":"Maria","invite_key":"00000000-0000-0000-0000-000000000000"}'
```
