//
// index.ts
//

import { createClient } from "@supabase/supabase-js";
import { SignJWT, importJWK, jwtVerify } from "jose";
import { isValidUUID, isValidUsername, jsonResponse, normalizeUsername } from "./lib.ts";

type Role = "owner" | "admin" | "member" | "guest";

type RequestBody = {
  action: "create" | "join" | "members";
  username?: string;
  household_name?: string;
  invite_key?: string;
  household_id?: string;
};

const APP_SUPABASE_URL = Deno.env.get("APP_SUPABASE_URL") ?? "";
const APP_SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("APP_SUPABASE_SERVICE_ROLE_KEY") ?? "";
const APP_SUPABASE_JWT_SECRET = Deno.env.get("APP_SUPABASE_JWT_SECRET") ?? "";

function requireEnv(): string | null {
  if (!APP_SUPABASE_URL || !APP_SUPABASE_SERVICE_ROLE_KEY || !APP_SUPABASE_JWT_SECRET) {
    return "Missing APP_SUPABASE_URL, APP_SUPABASE_SERVICE_ROLE_KEY or APP_SUPABASE_JWT_SECRET";
  }
  return null;
}

async function signAccessToken(userId: string, householdId: string, role: Role, username: string) {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + 60 * 60 * 24 * 30; // 30 days

  const { key, alg, kid } = await getSigningKey(APP_SUPABASE_JWT_SECRET);

  return await new SignJWT({
    role: "authenticated",
    app_metadata: { household_id: householdId, role },
    user_metadata: { username }
  })
    .setProtectedHeader(kid ? { alg, kid } : { alg })
    .setIssuedAt(now)
    .setExpirationTime(exp)
    .setSubject(userId)
    .setIssuer("supabase")
    .setAudience("authenticated")
    .sign(key);
}

async function getSigningKey(rawSecret: string) {
  const trimmed = rawSecret.trim();
  if (trimmed.startsWith("{")) {
    const jwk = JSON.parse(trimmed);
    if (!jwk.d) {
      throw new Error("JWT secret JWK missing private key (d)");
    }
    const alg = jwk.alg ?? "ES256";
    const key = await importJWK(jwk, alg);
    return { key, alg, kid: jwk.kid };
  }

  const key = new TextEncoder().encode(rawSecret);
  return { key, alg: "HS256", kid: undefined as string | undefined };
}

async function getVerifyKey(rawSecret: string) {
  const trimmed = rawSecret.trim();
  if (trimmed.startsWith("{")) {
    const jwk = JSON.parse(trimmed);
    const alg = jwk.alg ?? "ES256";
    const key = await importJWK(jwk, alg);
    return { key, alg };
  }

  const key = new TextEncoder().encode(rawSecret);
  return { key, alg: "HS256" };
}

function getBearerToken(req: Request) {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.toLowerCase().startsWith("bearer ")) return null;
  return auth.slice(7).trim();
}

async function verifyAccessToken(token: string) {
  const { key, alg } = await getVerifyKey(APP_SUPABASE_JWT_SECRET);
  const { payload } = await jwtVerify(token, key, {
    issuer: "supabase",
    audience: "authenticated",
    algorithms: [alg]
  });
  return payload;
}

function getClient() {
  return createClient(APP_SUPABASE_URL, APP_SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false }
  });
}

async function handleCreate(body: RequestBody) {
  const username = normalizeUsername(body.username);
  const householdName = (body.household_name ?? "").trim();

  if (!isValidUsername(username) || householdName.length < 2) {
    return jsonResponse(400, { error: "Invalid username or household_name" });
  }

  const supabase = getClient();
  const userId = crypto.randomUUID();
  const householdId = crypto.randomUUID();
  const inviteKey = crypto.randomUUID();

  const { error: householdError } = await supabase
    .from("households")
    .insert({
      id: householdId,
      name: householdName,
      invite_key: inviteKey,
      owner_id: userId
    });

  if (householdError) {
    return jsonResponse(500, { error: householdError.message });
  }

  const { error: userError } = await supabase
    .from("household_users")
    .insert({
      id: userId,
      household_id: householdId,
      username,
      role: "owner"
    });

  if (userError) {
    await supabase.from("households").delete().eq("id", householdId);
    return jsonResponse(500, { error: userError.message });
  }

  await supabase.from("activity_log").insert({
    household_id: householdId,
    user_id: userId,
    action: "createHousehold",
    entity_type: "Household",
    entity_id: householdId,
    description: "Household created"
  });

  const token = await signAccessToken(userId, householdId, "owner", username);

  return jsonResponse(200, {
    access_token: token,
    token_type: "bearer",
    expires_in: 60 * 60 * 24 * 30,
    user: {
      id: userId,
      username,
      role: "owner",
      household_id: householdId
    },
    household: {
      id: householdId,
      name: householdName,
      invite_key: inviteKey,
      owner_id: userId
    }
  });
}

async function handleJoin(body: RequestBody) {
  const username = normalizeUsername(body.username);
  const inviteKey = (body.invite_key ?? "").trim();

  if (!isValidUsername(username) || !isValidUUID(inviteKey)) {
    return jsonResponse(400, { error: "Invalid username or invite_key" });
  }

  const supabase = getClient();

  const { data: household, error: householdError } = await supabase
    .from("households")
    .select("id, name, invite_key, owner_id")
    .eq("invite_key", inviteKey)
    .maybeSingle();

  if (householdError || !household) {
    return jsonResponse(404, { error: "Invite key not found" });
  }

  const { data: existingUser } = await supabase
    .from("household_users")
    .select("id")
    .eq("household_id", household.id)
    .eq("username", username)
    .maybeSingle();

  if (existingUser) {
    return jsonResponse(409, { error: "Username already used in household" });
  }

  const userId = crypto.randomUUID();

  const { error: userError } = await supabase
    .from("household_users")
    .insert({
      id: userId,
      household_id: household.id,
      username,
      role: "member"
    });

  if (userError) {
    return jsonResponse(500, { error: userError.message });
  }

  await supabase.from("activity_log").insert({
    household_id: household.id,
    user_id: userId,
    action: "joinHousehold",
    entity_type: "Household",
    entity_id: household.id,
    description: "User joined household"
  });

  const token = await signAccessToken(userId, household.id, "member", username);

  return jsonResponse(200, {
    access_token: token,
    token_type: "bearer",
    expires_in: 60 * 60 * 24 * 30,
    user: {
      id: userId,
      username,
      role: "member",
      household_id: household.id
    },
    household: {
      id: household.id,
      name: household.name,
      invite_key: household.invite_key,
      owner_id: household.owner_id
    }
  });
}

async function handleMembers(req: Request, body: RequestBody) {
  const token = getBearerToken(req);
  if (!token) {
    return jsonResponse(401, { error: "Missing bearer token" });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await verifyAccessToken(token);
  } catch {
    return jsonResponse(401, { error: "Invalid access token" });
  }

  const appMetadata = payload.app_metadata as { household_id?: string } | undefined;
  const householdId = body.household_id ?? appMetadata?.household_id;
  if (!householdId || !isValidUUID(householdId)) {
    return jsonResponse(400, { error: "Invalid household_id" });
  }

  if (appMetadata?.household_id && appMetadata.household_id !== householdId) {
    return jsonResponse(403, { error: "Household mismatch" });
  }

  const supabase = getClient();
  const { data, error } = await supabase
    .from("household_users")
    .select("id, household_id, username, role")
    .eq("household_id", householdId);

  if (error) {
    return jsonResponse(500, { error: error.message });
  }

  return jsonResponse(200, { members: data ?? [] });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return jsonResponse(200, {});
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  const missingEnv = requireEnv();
  if (missingEnv) {
    return jsonResponse(500, { error: missingEnv });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse(400, { error: "Invalid JSON" });
  }

  if (body.action === "create") {
    return await handleCreate(body);
  }

  if (body.action === "join") {
    return await handleJoin(body);
  }

  if (body.action === "members") {
    return await handleMembers(req, body);
  }

  return jsonResponse(400, { error: "Invalid action" });
});
