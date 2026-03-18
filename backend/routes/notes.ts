import { Hono } from "hono";
import { supabaseAdmin } from "@/backend/lib/supabase";
import { authMiddleware } from "@/backend/lib/auth-middleware";

export const notesRoutes = new Hono();

notesRoutes.use("*", authMiddleware);

notesRoutes.post("/send", async (c) => {
  const userId = c.get("userId");
  const body = await c.req.json();
  const { content } = body;

  if (!content || content.trim().length === 0) {
    return c.json({ error: "Note content is required" }, 400);
  }

  if (content.length > 200) {
    return c.json({ error: "Note must be 200 characters or less" }, 400);
  }

  const { data: partnership } = await supabaseAdmin
    .from("partnerships")
    .select("partner_id")
    .eq("user_id", userId)
    .single();

  if (!partnership) {
    return c.json({ error: "You need to add a partner first" }, 400);
  }

  const { data: note, error } = await supabaseAdmin
    .from("notes")
    .insert({
      sender_id: userId,
      receiver_id: partnership.partner_id,
      content: content.trim(),
    })
    .select()
    .single();

  if (error) {
    return c.json({ error: "Failed to send note" }, 500);
  }

  return c.json({ note });
});

notesRoutes.get("/latest", async (c) => {
  const userId = c.get("userId");

  const { data: note } = await supabaseAdmin
    .from("notes")
    .select("*, sender:profiles!notes_sender_id_fkey(username, display_name)")
    .eq("receiver_id", userId)
    .order("created_at", { ascending: false })
    .limit(1)
    .single();

  return c.json({ note: note || null });
});

notesRoutes.get("/sent", async (c) => {
  const userId = c.get("userId");

  const { data: notes } = await supabaseAdmin
    .from("notes")
    .select(
      "*, receiver:profiles!notes_receiver_id_fkey(username, display_name)",
    )
    .eq("sender_id", userId)
    .order("created_at", { ascending: false })
    .limit(20);

  return c.json({ notes: notes || [] });
});

notesRoutes.get("/received", async (c) => {
  const userId = c.get("userId");

  const { data: notes } = await supabaseAdmin
    .from("notes")
    .select("*, sender:profiles!notes_sender_id_fkey(username, display_name)")
    .eq("receiver_id", userId)
    .order("created_at", { ascending: false })
    .limit(20);

  return c.json({ notes: notes || [] });
});
