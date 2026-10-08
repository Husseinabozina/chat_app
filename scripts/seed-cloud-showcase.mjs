#!/usr/bin/env node
// Explicit fictional cloud fixture. No local accounts or history are copied.
import { createHash } from "node:crypto";
import { createRequire } from "node:module";
import { readFile } from "node:fs/promises";

const origin = "https://chat-app-backend-two-tawny.vercel.app";
const password = process.env.MINGLE_CLOUD_DEMO_PASSWORD;
if (!password || password.length < 16)
  throw new Error(
    "Set a private MINGLE_CLOUD_DEMO_PASSWORD of at least 16 characters.",
  );
const sharp = createRequire(
  new URL("../apps/backend/package.json", import.meta.url),
)("sharp");
const sessions = [];
async function request(path, session, method = "GET", body, conflict = false) {
  const res = await fetch(`${origin}/v1${path}`, {
    method,
    redirect: "error",
    signal: AbortSignal.timeout(30000),
    headers: {
      "Content-Type": "application/json",
      ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  if (conflict && res.status === 409) return null;
  if (!res.ok) throw new Error(`Showcase API ${path}: HTTP ${res.status}`);
  return res.status === 204 ? null : res.json();
}
async function account(name) {
  const email = `${name}@showcase.example.test`;
  const session =
    (await request(
      "/auth/register",
      null,
      "POST",
      { email, password },
      true,
    )) ?? (await request("/auth/login", null, "POST", { email, password }));
  sessions.push(session);
  return session;
}
function id(key) {
  const h = createHash("sha256")
    .update(`cloud-showcase-v1:${key}`)
    .digest("hex");
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-5${h.slice(13, 16)}-a${h.slice(17, 20)}-${h.slice(20, 32)}`;
}
async function upload(session, bytes, purpose, conversationId) {
  const ticket = await request("/media/uploads", session, "POST", {
    purpose,
    mimeType: "image/png",
    sizeBytes: bytes.length,
    ...(conversationId ? { conversationId } : {}),
  });
  const target = new URL(ticket.upload.url);
  if (
    target.protocol !== "https:" ||
    !(
      target.hostname === "vercel.com" ||
      target.hostname.endsWith(".blob.vercel-storage.com")
    ) ||
    target.username ||
    target.password ||
    ticket.upload.method !== "PUT"
  )
    throw new Error("Unexpected private cloud upload destination.");
  const res = await fetch(target, {
    method: "PUT",
    headers: ticket.upload.headers,
    body: bytes,
    redirect: "error",
    signal: AbortSignal.timeout(30000),
  });
  if (!res.ok) throw new Error(`Private cloud upload: HTTP ${res.status}`);
  await request(`/media/${ticket.mediaId}/complete`, session, "POST");
  return ticket.mediaId;
}
const people = [
  ["sara", "سارة أحمد", "تصميم وكتب وقهوة. حساب عرض تجريبي."],
  ["omar", "Omar Khaled", "Building useful things. Fictional demo profile."],
  ["nour", "نور علي", "رسم وألوان هادية. حساب عرض تجريبي."],
  ["yasmine", "Yasmine Hassan", "Photography and weekend walks. Demo profile."],
  ["ahmed", "أحمد سامي", "برمجة وموسيقى. حساب عرض تجريبي."],
  ["lina", "Lina Mohamed", "Learning something new every day. Demo profile."],
  ["youssef", "يوسف محمود", "كتب وتجارب جديدة. حساب عرض تجريبي."],
  ["malak", "Malak Adel", "Illustration and everyday stories. Demo profile."],
  ["hana", "هنا إبراهيم", "تصميم وقراءة. حساب عرض تجريبي."],
  ["adam", "Adam Nabil", "Music and coding. Fictional demo profile."],
  ["salma", "سلمى حسن", "زراعة وتصوير. حساب عرض تجريبي."],
  ["karim", "Karim Mostafa", "Coffee and creative projects. Demo profile."],
];
async function avatar(session, index) {
  const me = await request("/users/me", session);
  if (me.avatarUrl?.startsWith("/v1/media/")) return;
  const colors = [
    ["#E6EFDF", "#3C736A", "#EAA99B"],
    ["#FFE7DB", "#CB7972", "#527C84"],
    ["#E5E8F2", "#5B698C", "#E9B988"],
    ["#F3EAD7", "#BD8E5C", "#769686"],
  ];
  const [bg, ink, accent] = colors[index % colors.length];
  const objects = [
    `<rect x="92" y="96" width="140" height="150" rx="15" fill="${ink}"/><path d="M126 96V246" stroke="${accent}" stroke-width="10"/><path d="M151 147H207M151 175H195" stroke="#FFF9EC" stroke-width="9" stroke-linecap="round"/>`,
    `<path d="M219 143H239C276 143 277 191 240 191H219" fill="none" stroke="${ink}" stroke-width="15"/><path d="M88 135H226V198Q226 231 195 231H119Q88 231 88 198Z" fill="${ink}"/><path d="M127 115Q108 96 127 77M172 115Q153 95 173 71" fill="none" stroke="${accent}" stroke-width="9" stroke-linecap="round"/>`,
    `<rect x="78" y="110" width="168" height="128" rx="20" fill="${ink}"/><circle cx="162" cy="173" r="47" fill="#FFF9EC"/><circle cx="162" cy="173" r="32" fill="${accent}"/><rect x="111" y="92" width="65" height="31" rx="8" fill="${ink}"/>`,
    `<path d="M161 205V97" stroke="${ink}" stroke-width="9"/><path d="M161 157Q102 153 102 113Q154 103 161 157M161 131Q168 83 216 87Q211 133 161 131" fill="${ink}"/><path d="M114 202H208L195 256H127Z" fill="${accent}"/>`,
  ];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="320" height="320"><rect width="320" height="320" fill="${bg}"/><circle cx="286" cy="42" r="96" fill="#FFF9EC" opacity=".5"/>${objects[index % 4]}</svg>`;
  const media = await upload(
    session,
    await sharp(Buffer.from(svg)).png().toBuffer(),
    "avatar",
  );
  await request(`/media/${media}/avatar`, session, "PATCH");
}
try {
  const viewer = await account("mingle");
  await request("/users/me", viewer, "PATCH", {
    username: "mingle_demo",
    displayName: "Hussein",
    bio: "حساب عرض تجريبي لتجربة Mingle والحديث عن الأفكار والمشاريع.",
  });
  await avatar(viewer, 3);
  for (const [index, [key, name, bio]] of people.entries()) {
    const peer = await account(key);
    await request("/users/me", peer, "PATCH", {
      username: `demo_${key}`,
      displayName: name,
      bio,
    });
    await avatar(peer, index);
    if (index >= 8) continue;
    const conversation = await request(
      "/conversations/direct",
      viewer,
      "POST",
      { userId: peer.user.id },
    );
    const texts =
      index % 2 === 0
        ? [
            "إيه أخبار المشروع؟",
            "خلصت الجزء الأول وبراجع التفاصيل ✨",
            "حلو جدًا، نراجع الأفكار سوا؟",
            "أكيد، جهزت شوية ملاحظات.",
            "نجرب الألوان والخطوط بعد الظهر؟",
            "تمام! هبعتلك النتيجة 🎨",
            "مستني رأيك في آخر تعديل 🌿",
          ]
        : [
            "Did you review the latest ideas?",
            "Yes! I added a few notes for our next step.",
            "Let's focus on the messaging flow first.",
            "Agreed. Clear, simple and easy to use.",
            "I'll share an update after lunch.",
            "Perfect. Thanks for helping!",
            "The new notes are ready. Want to take a look? ☕",
          ];
    let last, first;
    for (const [j, text] of texts.entries()) {
      const sender = j % 2 === 0 && j !== 6 ? viewer : peer;
      last = await request(
        `/conversations/${conversation.id}/messages`,
        sender,
        "POST",
        {
          clientMessageId: id(`${conversation.id}:${j}`),
          type: "text",
          text,
          ...(j === 2 && first ? { replyToMessageId: first.id } : {}),
        },
      );
      first ??= last;
    }
    if (index === 0) {
      const key = id(`${conversation.id}:image`);
      const history = await request(
        `/conversations/${conversation.id}/messages?limit=100`,
        peer,
      );
      if (
        !history.items.some(
          (m) => m.clientMessageId === key && m.senderId === peer.user.id,
        )
      ) {
        const bytes = await readFile(
          new URL(
            "../apps/mobile/assets/art/landscape_avatar.png",
            import.meta.url,
          ),
        );
        const imageMediaId = await upload(
          peer,
          bytes,
          "message",
          conversation.id,
        );
        await request(
          `/conversations/${conversation.id}/messages`,
          peer,
          "POST",
          {
            clientMessageId: key,
            type: "image",
            imageMediaId,
            text: "دراسة ألوان هادية للشغل الجديد 🌿",
          },
        );
      }
    }
    await request(`/conversations/${conversation.id}/read`, peer, "POST", {
      upToMessageId: last.id,
    });
    if (index % 3 === 0)
      await request(`/conversations/${conversation.id}/read`, viewer, "POST", {
        upToMessageId: last.id,
      });
  }
  const inbox = await request("/conversations?limit=20", viewer);
  if (inbox.items.length < 8) throw new Error("Showcase inbox is incomplete.");
  console.log(
    "Cloud showcase ready: @mingle_demo, 12 fictional peers, 8 conversations, 56 text messages and an image. Credentials are supplied privately.",
  );
} finally {
  for (const session of sessions) {
    try {
      await request("/auth/logout", null, "POST", {
        refreshToken: session.refreshToken,
      });
    } catch {
      /* Expiry remains the fallback. */
    }
  }
}
