import admin from "firebase-admin";
import { getSupabaseClient } from "../services/supabaseClient.js";

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// Bir collection'daki tum dokumanlari batch halinde sil (500'er 500'er)
async function deleteCollection(collectionRef) {
  let totalDeleted = 0;
  let snapshot = await collectionRef.limit(500).get();

  while (!snapshot.empty) {
    const batch = db.batch();
    for (const doc of snapshot.docs) {
      // Alt collection'lari da kontrol et (conversations -> messages gibi)
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
    const userRef = db.collection("users").doc(uid);

    // 1) Subcollection'lari sil
    const subcollections = ["chat_sessions", "usage_daily", "profile_memory", "conversations"];
    for (const subName of subcollections) {
      const subRef = userRef.collection(subName);
      await deleteCollection(subRef);
    }

    // 2) Supabase'ten kullanici verilerini sil
    try {
      const supabase = getSupabaseClient();
      const { error } = await supabase.from("message_embeddings").delete().eq("uid", uid);

      if (error) {
        console.error(`[deleteUser] Supabase temizleme hatasi: ${error.message}`);
        // Supabase hatasi silme islemini durdurmasin, devam et
      }
    } catch (supaErr) {
      console.error(`[deleteUser] Supabase erisim hatasi: ${supaErr.message}`);
      // Supabase erisilemese bile devam et
    }

    // 3) Ana user dokumanini sil
    await userRef.delete();

    // 4) Firebase Auth hesabini sil (admin SDK - re-auth gerekmez)
    await admin.auth().deleteUser(uid);

    console.log(`[deleteUser] uid=${uid} - tum veriler silindi`);
    return res.status(200).json({ success: true, uid });
  } catch (err) {
    console.error("[deleteUser_error]", err?.stack || err);
    return res.status(500).json({
      success: false,
      code: "INTERNAL",
      message: String(err?.message || err),
    });
  }
}
