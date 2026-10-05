#!/usr/bin/env node
// Explicit, loopback-only developer fixture. Never part of application startup.
import { createHash } from "node:crypto";
import { createRequire } from "node:module";
import { readFile } from "node:fs/promises";

// Reuse the backend's existing image library; no extra install or AI generation.
const require = createRequire(
  new URL("../apps/backend/package.json", import.meta.url),
);
const sharp = require("sharp");

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
const email = process.env.MINGLE_DEMO_EMAIL ?? "showcase@example.test";
const viewerToken = process.env.MINGLE_DEMO_VIEWER_TOKEN;
if (!viewerToken && !email.endsWith("@example.test"))
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
    .update(`mingle-showcase-v1:${key}`)
    .digest()
    .subarray(0, 16);
  bytes[6] = (bytes[6] & 15) | 0x50;
  bytes[8] = (bytes[8] & 63) | 0x80;
  const hex = bytes.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

async function upload(session, bytes, purpose, conversationId) {
  const ticket = await request("/media/uploads", {
    method: "POST",
    session,
    body: {
      purpose,
      mimeType: "image/png",
      sizeBytes: bytes.length,
      ...(conversationId ? { conversationId } : {}),
    },
  });
  const destination = new URL(ticket.upload.url);
  if (!["localhost", "127.0.0.1", "[::1]"].includes(destination.hostname))
    throw new Error("Showcase uploads require local object storage.");
  const form = new FormData();
  for (const [name, value] of Object.entries(ticket.upload.fields))
    form.append(name, value);
  form.append("file", new Blob([bytes], { type: "image/png" }), "showcase.png");
  const response = await fetch(destination, {
    method: "POST",
    body: form,
    redirect: "error",
    signal: AbortSignal.timeout(30000),
  });
  if (!response.ok)
    throw new Error(`Showcase storage: HTTP ${response.status}`);
  await request(`/media/${ticket.mediaId}/complete`, {
    method: "POST",
    session,
  });
  return ticket.mediaId;
}

async function avatar(session, index) {
  const me = await request("/users/me", { session });
  if (me.avatarUrl?.startsWith("/v1/media/")) return;
  const palettes = [
    ["#E6EFDF", "#3C736A", "#EAA99B"],
    ["#FFE7DB", "#CB7972", "#527C84"],
    ["#E5E8F2", "#5B698C", "#E9B988"],
    ["#F3EAD7", "#BD8E5C", "#769686"],
    ["#E3EEEE", "#487E86", "#DCAD8A"],
    ["#F4E1E9", "#9E657E", "#93B4AB"],
  ];
  const [bg, ink, accent] = palettes[index % palettes.length];
  const objects = [
    `<rect x="130" y="160" width="234" height="230" rx="22" fill="${ink}"/><path d="M174 160V390" stroke="${accent}" stroke-width="14"/><path d="M207 230H322M207 266H300" stroke="#FFF9EC" stroke-width="12" stroke-linecap="round"/><path d="M300 160V213L319 197L337 213V160" fill="${accent}"/>`,
    `<path d="M325 220H359C415 220 415 299 356 299H325" fill="none" stroke="${ink}" stroke-width="23"/><path d="M132 211H337V302Q337 359 282 359H187Q132 359 132 302Z" fill="${ink}"/><path d="M174 179Q152 152 178 130M234 179Q212 152 239 121M290 179Q267 150 291 130" fill="none" stroke="${accent}" stroke-width="13" stroke-linecap="round"/><rect x="114" y="365" width="271" height="15" rx="7" fill="${accent}"/>`,
    `<path d="M219 164L235 139H290L309 164H364Q390 164 390 190V345Q390 371 364 371H147Q121 371 121 345V190Q121 164 147 164Z" fill="${ink}"/><circle cx="257" cy="267" r="72" fill="#FFF9EC"/><circle cx="257" cy="267" r="53" fill="${accent}"/><circle cx="257" cy="267" r="33" fill="${ink}"/><circle cx="243" cy="251" r="11" fill="#FFF9EC" opacity=".8"/><rect x="145" y="187" width="44" height="13" rx="6" fill="${accent}"/>`,
    `<path d="M257 334V167" stroke="${ink}" stroke-width="11" stroke-linecap="round"/><path d="M257 245Q162 247 167 176Q248 167 257 245M258 208Q269 124 342 137Q339 215 258 208M257 292Q319 221 354 263Q343 326 257 292" fill="${ink}"/><path d="M183 316H331L311 396H203Z" fill="${accent}"/><rect x="174" y="308" width="166" height="24" rx="10" fill="${accent}"/>`,
  ];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><rect width="512" height="512" fill="${bg}"/><circle cx="424" cy="92" r="138" fill="#FFF9EC" opacity=".5"/><ellipse cx="256" cy="407" rx="137" ry="13" fill="${ink}" opacity=".1"/>${objects[index % objects.length]}</svg>`;
  const bytes = await sharp(Buffer.from(svg)).png().toBuffer();
  const mediaId = await upload(session, bytes, "avatar");
  await request(`/media/${mediaId}/avatar`, { method: "PATCH", session });
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
// Deliberately fictional, varied conversations for a product walkthrough.
const stories = [
  [
    "صباح الخير يا سارة، شفت التصميم الجديد؟",
    "أيوه! ترتيب الرسائل أوضح بكتير كده.",
    "حاولت أخلي المسافات مريحة خصوصًا مع الكلام العربي.",
    "حلو، نجربه كمان في الوضع الداكن؟",
    "تمام، هجهّز الشاشتين ونقارنهم بعد الظهر.",
    "وأنا هجمع ملاحظات الألوان والخطوط 🎨",
  ],
  [
    "Did you get a chance to review the notes?",
    "Yes — I added a small checklist for our next release.",
    "Great. Let's focus on the messaging flow first.",
    "Agreed. Photos and reconnecting are on my list too.",
    "I'll share the updated plan after lunch.",
    "Perfect. One clear step at a time.",
  ],
  [
    "نور، إيه أخبار ورشة الرسم؟",
    "خلصت أول اسكتش للركن اللي جنب الشباك 🌿",
    "الألوان الهادية لايقة عليه جدًا.",
    "جربت أخضر خفيف مع لون الورق الطبيعي.",
    "ابعتيه لما تخلصي، نفسي أشوف التفاصيل.",
    "أكيد، هصوره في ضوء النهار.",
  ],
  [
    "Any ideas for Saturday's photo walk?",
    "The old bookshop opens at ten. Great window light.",
    "That sounds good. I'll bring the small camera.",
    "Let's start there, then walk down to the river.",
    "Ten it is. I'll save the location.",
    "See you there — hoping for a sunny morning 📷",
  ],
  [
    "عامل إيه يا أحمد؟ وصلت لفين في المشروع؟",
    "خلصت الجزء الأول، وبراجع الحالات اللي فيها انقطاع نت.",
    "ممتاز. المهم الرسالة متتكررش لما نحاول تاني.",
    "بالضبط، وبنحتفظ بنفس رقم الرسالة.",
    "نراجع النتيجة سوا بعد الشغل؟",
    "تمام، هبعتلك الملاحظات الساعة سبعة.",
  ],
  [
    "How is the new course going?",
    "Really well. Today's lesson was about clear writing.",
    "What's one thing you'll use right away?",
    "Shorter sentences. And examples people recognize.",
    "That would make our project notes easier to follow.",
    "I'll try it in the next update. Thanks for the idea!",
  ],
  [
    "خلصت الكتاب اللي رشحتهولي 📚",
    "إيه أكتر جزء عجبك؟",
    "الفصل اللي بيتكلم عن العادات الصغيرة.",
    "ده المفضل عندي، خصوصًا أمثلة التطبيق اليومي.",
    "كتبت شوية ملاحظات عشان منساش الأفكار.",
    "ابعتها لما تفضى، ونختار الكتاب اللي بعده.",
  ],
  [
    "The illustration set is ready for a first look.",
    "Lovely. Did you keep the shapes simple?",
    "Yes, paper, plants and little everyday objects.",
    "That fits the calm direction we discussed.",
    "I'll send a preview with the two background options.",
    "Thanks! The cream version is my favorite so far.",
  ],
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
  const viewer = viewerToken
    ? {
        accessToken: viewerToken,
        user: await request("/users/me", {
          session: { accessToken: viewerToken },
        }),
      }
    : await account(email);
  if (
    process.env.MINGLE_DEMO_VIEWER_ID &&
    viewer.user.id !== process.env.MINGLE_DEMO_VIEWER_ID
  ) {
    throw new Error(
      "The authenticated viewer does not match the requested account.",
    );
  }
  const profile = await request("/users/me", { session: viewer });
  if (!profile.username || !profile.displayName) {
    await request("/users/me", {
      method: "PATCH",
      session: viewer,
      body: {
        username: "hussein_showcase",
        displayName: "Hussein",
        bio: "Building useful things. Sharing ideas along the way.",
      },
    });
  }
  await avatar(viewer, 4);
  for (const [index, [key, name, bio]] of people.entries()) {
    const peer = await account(`showcase.${key}@example.test`);
    await request("/users/me", {
      method: "PATCH",
      session: peer,
      body: { username: `showcase_${key}`, displayName: name, bio },
    });
    await avatar(peer, index);
    if (index >= 8) continue;
    const conversation = await request("/conversations/direct", {
      method: "POST",
      session: viewer,
      body: { userId: peer.user.id },
    });
    let last, first;
    const texts = stories[index];
    const count = texts.length;
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
          text: texts[j],
          ...(j === 2 && first ? { replyToMessageId: first.id } : {}),
        },
      });
      first ??= last;
      messageCount++;
    }
    if (index === 0) {
      const clientMessageId = messageId(`${conversation.id}:artwork`);
      const history = await request(
        `/conversations/${conversation.id}/messages?limit=100`,
        { session: peer },
      );
      if (
        !history.items.some(
          (message) =>
            message.clientMessageId === clientMessageId &&
            message.senderId === peer.user.id,
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
        await request(`/conversations/${conversation.id}/messages`, {
          method: "POST",
          session: peer,
          body: {
            clientMessageId,
            type: "image",
            imageMediaId,
            text: "دي دراسة الألوان اللي اتكلمنا عنها. إيه رأيك في درجات السما؟",
          },
        });
      }
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
    `Demo ready for @${viewer.user.username}: 12 discoverable profiles, 8 direct conversations, ${messageCount} stable seed messages. Search People for "showcase".`,
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
