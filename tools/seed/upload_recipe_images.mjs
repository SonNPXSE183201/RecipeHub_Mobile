// Tải ảnh món lên Firebase Storage và ghi `imageUrl` vào Firestore `recipes/{id}`.
//
// Dữ liệu vào: tools/seed/recipes.json — món nào có `imageFile` (tên file trong tools/seed/images/)
// sẽ được tải lên `recipe-images/{code}/cover.<ext>` (rules: firebase/storage.rules).
//
// Cách chạy (Node 18+):
//   cd tools/seed && npm i firebase-admin
//   set GOOGLE_APPLICATION_CREDENTIALS=<đường dẫn service-account.json>     (PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS="...")
//   set FIREBASE_STORAGE_BUCKET=<bucket>                                    (mặc định recipehub-mobile.firebasestorage.app)
//   node upload_recipe_images.mjs            # --dry-run để chỉ kiểm tra
//
// Không commit service-account.json.
import { readFileSync, existsSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { extname, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getStorage } from 'firebase-admin/storage';
import { getFirestore } from 'firebase-admin/firestore';

const here = dirname(fileURLToPath(import.meta.url));
const dryRun = process.argv.includes('--dry-run');
const bucketName =
  process.env.FIREBASE_STORAGE_BUCKET || 'recipehub-mobile.firebasestorage.app';
const mime = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' };

const recipes = JSON.parse(readFileSync(join(here, 'recipes.json'), 'utf8'));
const withImage = recipes.filter((r) => r.imageFile);
console.log(`${withImage.length}/${recipes.length} món có imageFile`);

initializeApp({ credential: applicationDefault(), storageBucket: bucketName });
const bucket = getStorage().bucket();
const db = getFirestore();

let ok = 0;
for (const r of withImage) {
  // `imageFile` là tên gợi ý (vd TS-OLSUAD.jpg); chấp nhận .jpg/.jpeg/.png/.webp cùng tên.
  const base = r.imageFile.replace(/\.[^.]+$/, '');
  const found = Object.keys(mime)
    .map((e) => ({ ext: e, local: join(here, 'images', base + e) }))
    .find((c) => existsSync(c.local));
  if (!found) {
    console.log(`CHƯA CÓ ẢNH ${r.code}: đặt images/${base}.jpg (hoặc .png/.webp)`);
    continue;
  }
  const { local, ext } = found;
  const path = `recipe-images/${r.code}/cover${ext}`;
  const token = randomUUID();
  const url = `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
  if (dryRun) {
    console.log(`[dry-run] ${r.code} → ${path}`);
    continue;
  }
  await bucket.upload(local, {
    destination: path,
    metadata: {
      contentType: mime[ext],
      cacheControl: 'public, max-age=31536000',
      metadata: { firebaseStorageDownloadTokens: token },
    },
  });
  const snap = await db.collection('recipes').where('code', '==', r.code).limit(1).get();
  if (snap.empty) {
    console.error(`Đã tải ảnh ${r.code} nhưng chưa có tài liệu recipes với code này (hãy nạp bộ công thức trước).`);
    continue;
  }
  await snap.docs[0].ref.update({ imageUrl: url, imagePath: path });
  console.log(`OK ${r.code} → ${path}`);
  ok++;
}
console.log(dryRun ? 'Dry-run xong.' : `Hoàn tất: ${ok}/${withImage.length} món.`);
