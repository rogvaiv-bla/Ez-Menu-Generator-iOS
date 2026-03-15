//
// lib.ts
//

export function normalizeUsername(input: string): string {
  return input.trim().replace(/\s+/g, " ");
}

export function isValidUUID(input: string): boolean {
  return /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/.test(input);
}

export function isValidUsername(input: string): boolean {
  const name = normalizeUsername(input);
  return name.length >= 2 && name.length <= 32;
}

export function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS"
    }
  });
}
