import { createClient } from "https://esm.sh/@supabase/supabase-js@2.43.0";
import { corsHeaders } from "../_shared/cors.ts";

console.log("Function `fetch-household-members` up and running!");

interface HouseholdMember {
    id: string;
    household_id: string;
    username: string;
    role: string;
}

Deno.serve(async (req: Request) => {
    // Handle CORS
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    // Only allow POST
    if (req.method !== "POST") {
        return new Response(
            JSON.stringify({ error: "Method not allowed. Use POST." }),
            { status: 405, headers: corsHeaders }
        );
    }

    try {
        const supabaseUrl = Deno.env.get("SUPABASE_URL");
        const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

        if (!supabaseUrl || !serviceRoleKey) {
            console.error("Missing Supabase configuration");
            return new Response(
                JSON.stringify({ error: "Server configuration error" }),
                { status: 500, headers: corsHeaders }
            );
        }

        let body;
        try {
            body = await req.json();
        } catch {
            return new Response(
                JSON.stringify({ error: "Invalid JSON body" }),
                { status: 400, headers: corsHeaders }
            );
        }

        const { householdId } = body;

        if (!householdId) {
            return new Response(
                JSON.stringify({ error: "Missing householdId" }),
                { status: 400, headers: corsHeaders }
            );
        }

        // Create admin client (bypasses RLS)
        const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

        // Query without RLS restrictions
        const { data, error } = await supabaseAdmin
            .from("household_users")
            .select("id,household_id,username,role")
            .eq("household_id", householdId)
            .limit(100);

        if (error) {
            console.error("Database error:", error);
            return new Response(
                JSON.stringify({ error: error.message || "Database query failed" }),
                { status: 500, headers: corsHeaders }
            );
        }

        return new Response(JSON.stringify(data || []), {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    } catch (error) {
        console.error("Function error:", error);
        const errorMessage = error instanceof Error ? error.message : "Unknown error";
        return new Response(
            JSON.stringify({ error: errorMessage }),
            { status: 500, headers: corsHeaders }
        );
    }
});
