#!/usr/bin/env node
// Export the editable SVG master; no image generation or app startup side effect.
// Requires sharp 0.35.4 in this environment (or supplied through NODE_PATH).
const fs = require("node:fs/promises");
const path = require("node:path");
const sharp = require("sharp");
const root = path.resolve(__dirname, "..");
const mobile = path.join(root, "apps/mobile");
const color = process.argv[2] ?? "#CA326E";
const background = process.argv[3] ?? "#FFF8F5";
if (![color, background].every((c) => /^#[\da-f]{6}$/i.test(c))) {
  throw new Error("Use two #RRGGBB colors: mark and launcher background.");
}
async function writePng(svg, size, output, flatten = false) {
  let render = sharp(Buffer.from(svg), { density: 768 }).resize(size, size);
  if (flatten) render = render.flatten({ background });
  await fs.mkdir(path.dirname(output), { recursive: true });
  await render.png().toFile(output);
}
async function main() {
  const master = await fs.readFile(
    path.join(mobile, "assets/brand/mingle-mark.svg"),
    "utf8",
  );
  const mark = master.replace('color="#CA326E"', `color="${color}"`);
  await writePng(mark, 768, path.join(mobile, "assets/art/mingle-mark.png"));
  const inner = mark.replace(/<svg[^>]*>/, "").replace("</svg>", "");
  const launcher = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" color="${color}"><rect width="128" height="128" fill="${background}"/><g transform="translate(16 16)">${inner}</g></svg>`;
  const ios = path.join(mobile, "ios/Runner/Assets.xcassets");
  const icons = JSON.parse(
    await fs.readFile(
      path.join(ios, "AppIcon.appiconset/Contents.json"),
      "utf8",
    ),
  );
  for (const item of icons.images) {
    if (!item.filename) continue;
    const pixels = Math.round(parseFloat(item.size) * parseFloat(item.scale));
    await writePng(
      launcher,
      pixels,
      path.join(ios, "AppIcon.appiconset", item.filename),
      true,
    );
  }
  for (const [density, size] of [
    ["mdpi", 48],
    ["hdpi", 72],
    ["xhdpi", 96],
    ["xxhdpi", 144],
    ["xxxhdpi", 192],
  ]) {
    await writePng(
      launcher,
      size,
      path.join(
        mobile,
        `android/app/src/main/res/mipmap-${density}/ic_launcher.png`,
      ),
      true,
    );
    await writePng(
      mark,
      size * 2,
      path.join(
        mobile,
        `android/app/src/main/res/drawable-${density}/mingle_mark.png`,
      ),
    );
  }
  for (const [suffix, scale] of [
    ["", 1],
    ["@2x", 2],
    ["@3x", 3],
  ]) {
    await writePng(
      mark,
      112 * scale,
      path.join(ios, `LaunchImage.imageset/LaunchImage${suffix}.png`),
    );
  }
  console.log(
    "Exported transparent app mark, opaque launcher icons and native splash marks.",
  );
}
main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
