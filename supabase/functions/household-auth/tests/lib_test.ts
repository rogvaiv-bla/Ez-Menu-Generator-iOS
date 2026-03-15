import { isValidUUID, isValidUsername, normalizeUsername } from "../lib.ts";
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

Deno.test("normalizeUsername trims and collapses spaces", () => {
  const value = normalizeUsername("  Ana   Maria  ");
  assertEquals(value, "Ana Maria");
});

Deno.test("isValidUsername enforces length", () => {
  assertEquals(isValidUsername("A"), false);
  assertEquals(isValidUsername("Ab"), true);
  assertEquals(isValidUsername("A".repeat(40)), false);
});

Deno.test("isValidUUID accepts valid uuid", () => {
  assertEquals(isValidUUID("550e8400-e29b-41d4-a716-446655440000"), true);
  assertEquals(isValidUUID("invalid"), false);
});
