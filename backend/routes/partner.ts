import { Hono } from "hono";
import { supabaseAdmin } from "@/backend/lib/supabase";
import { authMiddleware } from "@/backend/lib/auth-middleware";

export const partnerRoutes = new Hono();

partnerRoutes.use("*", authMiddleware);

partnerRoutes.get("/search", async (c) => {
  const username = c.req.query("username");
  const userId = c.get("userId");

  if (!username || username.length < 2) {
    return c.json({ error: "Username must be at least 2 characters" }, 400);
  }

  const { data: profiles } = await supabaseAdmin
    .from("profiles")
    .select("id, username, display_name")
    .ilike("username", `%${username.toLowerCase()}%`)
    .neq("id", userId)
    .limit(10);

  return c.json({ users: profiles || [] });
});

partnerRoutes.post("/add", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json();
  const { partner_username } = body;

  if (!partner_username) {
    return c.json({ error: "Partner username is required" }, 400);
  }

  const { data: partner } = await supabaseAdmin
    .from("profiles")
    .select("id, username, display_name")
    .eq("username", partner_username.toLowerCase())
    .single();

  if (!partner) {
    return c.json({ error: "User not found" }, 404);
  }

  if (partner.id === userId) {
    return c.json({ error: "You can't add yourself as a partner" }, 400);
  }

  const { data: existing } = await supabaseAdmin
    .from("partnerships")
    .select("id")
    .eq("user_id", userId)
    .single();

  if (existing) {
    await supabaseAdmin
      .from("partnerships")
      .update({ partner_id: partner.id })
      .eq("user_id", userId);
  } else {
    await supabaseAdmin.from("partnerships").insert({
      user_id: userId,
      partner_id: partner.id,
    });
  }

  const { data: reverseExisting } = await supabaseAdmin
    .from("partnerships")
    .select("id")
    .eq("user_id", partner.id)
    .single();

  if (!reverseExisting) {
    await supabaseAdmin.from("partnerships").insert({
      user_id: partner.id,
      partner_id: userId,
    });
  }

  return c.json({
    partner: {
      id: partner.id,
      username: partner.username,
      display_name: partner.display_name,
    },
  });
});

partnerRoutes.delete("/remove", async (c) => {
  const userId = c.get("userId");

  await supabaseAdmin
    .from("partnerships")
    .delete()
    .eq("user_id", userId);

  return c.json({ success: true });
});
