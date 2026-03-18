import { Hono } from "hono";
import { supabaseAdmin, supabaseAnon } from "@/backend/lib/supabase";
import { authMiddleware } from "@/backend/lib/auth-middleware";

export const authRoutes = new Hono();

authRoutes.post("/register", async (c) => {
  const body = await c.req.json();
  const { email, password, username } = body;

  if (!email || !password || !username) {
    return c.json({ error: "Email, password, and username are required" }, 400);
  }

  if (username.length < 3 || username.length > 20) {
    return c.json({ error: "Username must be 3-20 characters" }, 400);
  }

  if (!/^[a-zA-Z0-9_]+$/.test(username)) {
    return c.json(
      { error: "Username can only contain letters, numbers, and underscores" },
      400,
    );
  }

  const { data: existing } = await supabaseAdmin
    .from("profiles")
    .select("id")
    .eq("username", username.toLowerCase())
    .single();

  if (existing) {
    return c.json({ error: "Username is already taken" }, 409);
  }

  const { data: authData, error: authError } =
    await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { username: username.toLowerCase() },
    });

  if (authError) {
    return c.json({ error: authError.message }, 400);
  }

  await supabaseAdmin.from("profiles").insert({
    id: authData.user.id,
    username: username.toLowerCase(),
    display_name: username,
  });

  const { data: signInData, error: signInError } =
    await supabaseAnon.auth.signInWithPassword({
      email,
      password,
    });

  if (signInError) {
    return c.json({ error: "Account created but login failed" }, 500);
  }

  return c.json({
    user: {
      id: authData.user.id,
      email: authData.user.email,
      username: username.toLowerCase(),
    },
    session: {
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
    },
  });
});

authRoutes.post("/login", async (c) => {
  const body = await c.req.json();
  const { identifier, password } = body;

  if (!identifier || !password) {
    return c.json({ error: "Identifier and password are required" }, 400);
  }

  let email = identifier;

  if (!identifier.includes("@")) {
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .eq("username", identifier.toLowerCase())
      .single();

    if (!profile) {
      return c.json({ error: "User not found" }, 404);
    }

    const { data: userData } =
      await supabaseAdmin.auth.admin.getUserById(profile.id);

    if (!userData?.user?.email) {
      return c.json({ error: "User not found" }, 404);
    }

    email = userData.user.email;
  }

  const { data: signInData, error: signInError } =
    await supabaseAnon.auth.signInWithPassword({
      email,
      password,
    });

  if (signInError) {
    return c.json({ error: "Invalid credentials" }, 401);
  }

  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("*")
    .eq("id", signInData.user.id)
    .single();

  return c.json({
    user: {
      id: signInData.user.id,
      email: signInData.user.email,
      username: profile?.username,
      display_name: profile?.display_name,
    },
    session: {
      access_token: signInData.session.access_token,
      refresh_token: signInData.session.refresh_token,
    },
  });
});

authRoutes.get("/me", authMiddleware, async (c) => {
  const userId = c.get("userId");

  const { data: profile } = await supabaseAdmin
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  if (!profile) {
    return c.json({ error: "Profile not found" }, 404);
  }

  const { data: partnership } = await supabaseAdmin
    .from("partnerships")
    .select("*, partner:profiles!partnerships_partner_id_fkey(*)")
    .eq("user_id", userId)
    .single();

  return c.json({
    user: {
      id: userId,
      username: profile.username,
      display_name: profile.display_name,
    },
    partner: partnership
      ? {
          id: partnership.partner.id,
          username: partnership.partner.username,
          display_name: partnership.partner.display_name,
        }
      : null,
  });
});

authRoutes.post("/refresh", async (c) => {
  const body = await c.req.json();
  const { refresh_token } = body;

  if (!refresh_token) {
    return c.json({ error: "Refresh token is required" }, 400);
  }

  const { data, error } = await supabaseAnon.auth.refreshSession({
    refresh_token,
  });

  if (error || !data.session) {
    return c.json({ error: "Failed to refresh session" }, 401);
  }

  return c.json({
    session: {
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    },
  });
});
