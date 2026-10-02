#!/usr/bin/env node
// Explicit fixture data, not application startup. Loopback + reserved demo users only.
import { readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
const origin = new URL(
  process.env.CHAT_API_BASE_URL ?? "http://127.0.0.1:55418",
);
if (
  !["localhost", "127.0.0.1", "[::1]"].includes(origin.hostname) ||
  origin.protocol !== "http:" ||
  origin.username ||
  origin.password ||
  origin.pathname !== "/"
)
  throw new Error("Demo media requires a loopback HTTP origin.");
const email = process.env.MINGLE_DEMO_EMAIL ?? "iphone.demo@example.test";
const password = process.env.MINGLE_DEMO_PASSWORD;
if (!email.endsWith("@example.test") || !password)
  throw new Error("Set reserved demo email/password environment variables.");
const api = `${origin.origin}/v1`;
const image = await readFile(
  new URL("../apps/mobile/assets/art/landscape_avatar.png", import.meta.url),
);
async function request(path, token, method = "GET", body) {
  const response = await fetch(`${api}${path}`, {
    method,
    redirect: "error",
    signal: AbortSignal.timeout(30000),
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  if (!response.ok)
    throw new Error(`Demo request ${path}: HTTP ${response.status}`);
  return response.status === 204 ? null : response.json();
}
const session = await request("/auth/login", null, "POST", { email, password });
async function upload(purpose, conversationId) {
  const ticket = await request("/media/uploads", session.accessToken, "POST", {
    purpose,
    mimeType: "image/png",
    sizeBytes: image.length,
    ...(conversationId ? { conversationId } : {}),
  });
  const form = new FormData();
  for (const [name, value] of Object.entries(ticket.upload.fields))
    form.append(name, value);
  form.append("file", new Blob([image], { type: "image/png" }), "demo.png");
  const response = await fetch(ticket.upload.url, {
    method: "POST",
    body: form,
    redirect: "error",
    signal: AbortSignal.timeout(30000),
  });
  if (!response.ok) throw new Error(`Demo storage: HTTP ${response.status}`);
  await request(
    `/media/${ticket.mediaId}/complete`,
    session.accessToken,
    "POST",
  );
  return ticket.mediaId;
}
try {
  const me = await request("/users/me", session.accessToken);
  if (!me.avatarUrl?.startsWith("/v1/media/")) {
    const id = await upload("avatar");
    await request(`/media/${id}/avatar`, session.accessToken, "PATCH");
    console.log("Added actual stored photo to local demo profile.");
  } else console.log("Existing demo photo reused.");
  const conversations = await request(
    "/conversations?limit=20",
    session.accessToken,
  );
  const chat = conversations.items[0];
  if (chat) {
    const hash = createHash("sha256")
      .update(`mingle-demo-image-v1:${me.id}:${chat.id}`)
      .digest("hex");
    const clientMessageId = `${hash.slice(0, 8)}-${hash.slice(8, 12)}-5${hash.slice(13, 16)}-a${hash.slice(17, 20)}-${hash.slice(20, 32)}`;
    const history = await request(
      `/conversations/${chat.id}/messages?limit=100`,
      session.accessToken,
    );
    if (
      !history.items.some(
        (m) => m.senderId === me.id && m.clientMessageId === clientMessageId,
      )
    ) {
      const id = await upload("message", chat.id);
      await request(
        `/conversations/${chat.id}/messages`,
        session.accessToken,
        "POST",
        {
          clientMessageId,
          type: "image",
          imageMediaId: id,
          text: "A little color for our conversation. 🌤️",
        },
      );
      console.log(
        "Added one actual image message to the local demo conversation.",
      );
    } else console.log("Existing demo image message reused.");
  }
} finally {
  await request("/auth/logout", session.accessToken, "POST", {
    refreshToken: session.refreshToken,
  });
}
