import admin from "firebase-admin";
import { getSupabaseClient } from "../services/supabaseClient.js";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// Bir collection'daki tum dokumanlari batch halinde sil (500'er 500'er).
// Her dok icin alt subcollection'lari da recursive olarak siler.
async function deleteCollection(collectionRef) {
  let totalDeleted = 0;
  let snapshot = await collectionRef.limit(500).get();

  while (!snapshot.empty) {
    const batch = db.batch();
    for (const doc of snapshot.docs) {
      const subCollections = await doc.ref.listCollections();
      for (const subCol of subCollections) {
        await deleteCollection(subCol);
      }
      batch.delete(doc.ref);
    }
    await batch.commit();
    totalDeleted += snapshot.size;
    snapshot = await collectionRef.limit(500).get();
  }

  return totalDeleted;
}

// Storage'da verilen prefix altindaki tum dosyalari sayfali olarak siler.
// "Best effort": tek tek dosya hatalari Promise.allSettled ile yutulur.
async function deleteStoragePrefix(bucket, prefix) {
  let deletedCount = 0;
  let pageToken;

  do {
    const queryOpts = { prefix, autoPaginate: false, maxResults: 1000 };
    if (pageToken) queryOpts.pageToken = pageToken;

    const [files, nextQuery] = await bucket.getFiles(queryOpts);

    if (files.length > 0) {
      const results = await Promise.allSettled(files.map((f) => f.delete()));
      for (const r of results) {
        if (r.status === "fulfilled") deletedCount++;
      }
    }

    pageToken = nextQuery?.pageToken ?? null;
  } while (pageToken);

  return deletedCount;
}

export async function deleteUserDataHandler(req, res) {
  try {
    // Sadece POST kabul et
    if (req.method !== "POST") {
      return res.status(405).json({ success: false, code: "METHOD_NOT_ALLOWED" });
    }

    // Firebase Auth token dogrula
    const authHeader = req.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ success: false, code: "UNAUTHORIZED" });
    }

    const idToken = authHeader.slice("Bearer ".length).trim();
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (err) {
      return res.status(401).json({ success: false, code: "INVALID_TOKEN" });
    }

    const uid = decodedToken.uid;
    const warnings = [];
    const errors = [];

    // ── 1) users/{uid} subcollection'lari – dinamik liste ────────────────────
    const userRef = db.collection("users").doc(uid);
    const userSubCols = await userRef.listCollections();
    let userSubcollectionsCount = 0;
    for (const subCol of userSubCols) {
      userSubcollectionsCount += await deleteCollection(subCol);
    }

    // ── 2) Top-level kullanici koleksiyonlari (doc + altlari) ─────────────────
    const topLevelPaths = [
      "conversation_history",
      "relationship_memory",
      "relationship_analyses",
      "relationships",
    ];
    const topLevelDeleted = [];
    for (const colName of topLevelPaths) {
      const docRef = db.collection(colName).doc(uid);
      try {
        const subCols = await docRef.listCollections();
        for (const sub of subCols) {
          await deleteCollection(sub);
        }
        await docRef.delete().catch(() => {}); // dok yoksa sessizce gec
        topLevelDeleted.push(colName);
      } catch (e) {
        const msg = `${colName}/${uid}: ${e?.message}`;
        errors.push(msg);
        console.error(`[deleteUser] top-level silme hatasi: ${msg}`);
      }
    }

    // ── 3) Storage temizligi – relationship_chunks/{uid}/ ────────────────────
    let storageDeletedCount = 0;
    try {
      const bucket = admin.storage().bucket();
      storageDeletedCount = await deleteStoragePrefix(
        bucket,
        `relationship_chunks/${uid}/`
      );
    } catch (stErr) {
      const msg = `storage: ${stErr?.message}`;
      warnings.push(msg);
      console.error(`[deleteUser] Storage temizleme uyarisi: ${msg}`);
    }

    // ── 4) Supabase silme ─────────────────────────────────────────────────────
    try {
      const supabase = getSupabaseClient();
      const { error } = await supabase
        .from("message_embeddings")
        .delete()
        .eq("uid", uid);
      if (error) {
        const msg = `supabase: ${error.message}`;
        warnings.push(msg);
        console.error(`[deleteUser] Supabase temizleme hatasi: ${error.message}`);
      }
    } catch (supaErr) {
      const msg = `supabase: ${supaErr?.message}`;
      warnings.push(msg);
      console.error(`[deleteUser] Supabase erisim hatasi: ${supaErr?.message}`);
    }

    // ── 5) users/{uid} ana dokumanini sil ────────────────────────────────────
    await userRef.delete();

    // ── 6) Firebase Auth hesabini sil ────────────────────────────────────────
    await admin.auth().deleteUser(uid);

    console.log(`[deleteUser] uid=${uid} - tum veriler silindi`);
    return res.status(200).json({
      success: true,
      uid,
      deleted: {
        userSubcollectionsCount,
        topLevelDeleted,
        storageDeletedCount,
      },
      warnings,
      errors,
    });
  } catch (err) {
    console.error("[deleteUser_error]", err?.stack || err);
    return res.status(500).json({
      success: false,
      code: "INTERNAL",
      message: String(err?.message || err),
    });
  }
}
