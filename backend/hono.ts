import { Hono } from "hono";
import { cors } from "hono/cors";
import { authRoutes } from "@/backend/routes/auth";
import { partnerRoutes } from "@/backend/routes/partner";
import { notesRoutes } from "@/backend/routes/notes";

const app = new Hono();

app.use("*", cors());

app.get("/", (c) => {
  return c.json({ status: "ok", message: "Whisper API is running" });
});

app.route("/auth", authRoutes);
app.route("/partner", partnerRoutes);
app.route("/notes", notesRoutes);

export default app;
