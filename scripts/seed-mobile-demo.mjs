#!/usr/bin/env node
// Explicit, loopback-only developer fixture. Never part of application startup.
import { createHash } from "node:crypto";

const origin = new URL(
  process.env.CHAT_API_BASE_URL ?? "http://127.0.0.1:55418",
);
if (
  !["127.0.0.1", "[::1]", "localhost"].includes(origin.hostname) ||
  origin.protocol !== "http:" ||
  origin.username ||
  origin.password ||
  (origin.pathname !== "/" && origin.pathname !== "/v1")
) {
  throw new Error(
    "Demo seeding requires an HTTP loopback API URL with no credentials.",
  );
}
const password = process.env.MINGLE_DEMO_PASSWORD;
if (!password || password.length < 8)
  throw new Error(
    "Set MINGLE_DEMO_PASSWORD to the disposable local account password (at least 8 characters).",
  );
const email = process.env.MINGLE_DEMO_EMAIL ?? "iphone.demo@example.test";
if (!email.endsWith("@example.test"))
  throw new Error(
    "The demo viewer must use the reserved @example.test domain.",
  );
const api = `${origin.origin}/v1`;
const sessions = [];
async function request(
  path,
  { method = "GET", session, body, allowConflict = false } = {},
) {
  const response = await fetch(`${api}${path}`, {
    method,
    redirect: "error",
    signal: AbortSignal.timeout(15000),
    headers: {
      "Content-Type": "application/json",
      ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  if (allowConflict && response.status === 409) return null;
  if (!response.ok)
    throw new Error(`${method} ${path}: HTTP ${response.status}`);
  return response.status === 204 ? null : response.json();
}
async function account(address) {
  const session =
    (await request("/auth/register", {
      method: "POST",
      body: { email: address, password },
      allowConflict: true,
    })) ??
    (await request("/auth/login", {
      method: "POST",
      body: { email: address, password },
    }));
  sessions.push(session);
  return session;
}
function messageId(key) {
  const bytes = createHash("sha256")
    .update(`mingle-local-demo-v1:${key}`)
    .digest()
    .subarray(0, 16);
  bytes[6] = (bytes[6] & 15) | 0x50;
  bytes[8] = (bytes[8] & 63) | 0x80;
  const hex = bytes.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
const people = [
  ["sara", "سارة أحمد", "تصميم، كتب، وقهوة. حساب تجريبي."],
  [
    "omar",
    "Omar Khaled",
    "Building small things with big ideas. Demo profile.",
  ],
  ["nour", "نور علي", "بحب الرسم والألوان الهادية. حساب تجريبي."],
  [
    "yasmine",
    "Yasmine Hassan",
    "Photography, plants and weekend walks. Demo profile.",
  ],
  ["ahmed", "أحمد سامي", "برمجة وموسيقى ومحادثات بسيطة. حساب تجريبي."],
  ["lina", "Lina Mohamed", "Learning something new every day. Demo profile."],
  ["youssef", "يوسف محمود", "كتب وسفر وتجارب جديدة. حساب تجريبي."],
  [
    "malak",
    "Malak Adel",
    "Illustration and little everyday stories. Demo profile.",
  ],
  ["hana", "هنا إبراهيم", "مهتمة بالتصميم والقراءة. حساب تجريبي."],
  ["adam", "Adam Nabil", "Music, coding and good conversations. Demo profile."],
  ["salma", "سلمى حسن", "زراعة وتصوير وكتابة. حساب تجريبي."],
  ["karim", "Karim Mostafa", "Coffee and creative projects. Demo profile."],
];
const texts = [
  "أهلًا 👋 عامل إيه؟",
  "Hey! Great to hear from you.",
  "كنت عايز أشاركك فكرة صغيرة عن المشروع، لما تفضى قولي رأيك.",
  "Sounds good. Let’s talk after lunch ☕",
  "العربي والإنجليزي مع بعض: Mingle بيجمع محادثات بسيطة ✨",
  "That sounds lovely. See you soon!",
];
const previews = [
  "شوف الرسمة الجديدة لما تفضى 🎨",
  "The notes are ready. Want to take a look?",
  "وصلت البيت، نكمل كلامنا بكرة 👋",
  "Found a lovely little spot for photos 🌿",
  "تمام، هبعتلك الفكرة بعد شوية ☕",
  "Thanks for helping me with the project!",
  "الكتاب ده عجبني جدًا، لازم تقراه 📚",
  "Sketching something new today ✨",
];
let messageCount = 0;
try {
  const health = await request("/health");
  if (health.database !== "up")
    throw new Error("The local database must be healthy.");
  const viewer = await account(email);
  const profile = await request("/users/me", { session: viewer });
  if (!profile.username || !profile.displayName) {
    await request("/users/me", {
      method: "PATCH",
      session: viewer,
      body: {
        username: "hussein_demo",
        displayName: "Hussein Demo",
        bio: "Local Mingle demo account.",
      },
    });
  }
  for (const [index, [key, name, bio]] of people.entries()) {
    const peer = await account(`mingle.${key}@example.test`);
    await request("/users/me", {
      method: "PATCH",
      session: peer,
      body: { username: `demo_${key}`, displayName: name, bio },
    });
    if (index >= 8) continue;
    const conversation = await request("/conversations/direct", {
      method: "POST",
      session: viewer,
      body: { userId: peer.user.id },
    });
    let last, first;
    const count = index === 0 ? 44 : texts.length;
    for (let j = 0; j < count; j++) {
      const sender = j % 2 === 0 ? viewer : peer;
      last = await request(`/conversations/${conversation.id}/messages`, {
        method: "POST",
        session: sender,
        body: {
          clientMessageId: messageId(
            `${conversation.id}:${sender.user.id}:${j}`,
          ),
          type: "text",
          text: `${texts[j % texts.length]}${j >= texts.length ? ` (${j + 1})` : ""}`,
          ...(j === 2 && first ? { replyToMessageId: first.id } : {}),
        },
      });
      first ??= last;
      messageCount++;
    }
    last = await request(`/conversations/${conversation.id}/messages`, {
      method: "POST",
      session: peer,
      body: {
        clientMessageId: messageId(
          `${conversation.id}:${peer.user.id}:preview`,
        ),
        type: "text",
        text: previews[index],
      },
    });
    messageCount++;
    await request(`/conversations/${conversation.id}/read`, {
      method: "POST",
      session: peer,
      body: { upToMessageId: last.id },
    });
    if (index % 3 === 0) {
      await request(`/conversations/${conversation.id}/read`, {
        method: "POST",
        session: viewer,
        body: { upToMessageId: last.id },
      });
    }
  }
  console.log(
    `Demo ready for ${email}: 12 discoverable profiles, 8 direct conversations, ${messageCount} stable seed messages. Search People for "demo".`,
  );
  console.log(
    "All timestamps and receipts are real API records. Reruns reuse conversations/message IDs; existing read positions remain monotonic.",
  );
} finally {
  for (const session of sessions) {
    try {
      await request("/auth/logout", {
        method: "POST",
        body: { refreshToken: session.refreshToken },
      });
    } catch {
      /* Do not conceal an earlier seed failure; sessions still expire normally. */
    }
  }
}
