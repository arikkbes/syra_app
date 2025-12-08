/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP ANALYSIS HANDLER
 * ═══════════════════════════════════════════════════════════════
 * Analyzes WhatsApp chat exports and returns relationship insights
 */

import Busboy from "busboy";
import AdmZip from "adm-zip";
import { auth, db as firestore } from "../config/firebaseAdmin.js";
import { analyzeWhatsAppChat } from "./relationshipAnalysisService.js";

export async function analyzeRelationshipChatHandler(req, res) {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({
      success: false,
      message: "Sadece POST metodu kabul edilir.",
    });
  }

  try {
    // Verify authentication
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        success: false,
        message: "Yetkilendirme hatası.",
      });
    }

    const idToken = authHeader.split("Bearer ")[1];
    let uid;

    try {
      const decoded = await auth.verifyIdToken(idToken);
      uid = decoded.uid;
      console.log(`[${uid}] Relationship analysis request`);
    } catch (err) {
      console.error("Token verification failed:", err);
      return res.status(401).json({
        success: false,
        message: "Geçersiz oturum.",
      });
    }

    // Parse multipart form data
    const { fileData, fields } = await parseMultipartForm(req);

    if (!fileData || !fileData.buffer) {
      return res.status(400).json({
        success: false,
        message: "Dosya yüklenemedi.",
      });
    }

    console.log(`[${uid}] File received: ${fileData.filename}, size: ${fileData.buffer.length} bytes`);

    // Extract text content
    let chatText;
    const filename = fileData.filename.toLowerCase();

    if (filename.endsWith(".zip")) {
      // Extract .txt from .zip
      chatText = extractTextFromZip(fileData.buffer);
    } else if (filename.endsWith(".txt")) {
      chatText = fileData.buffer.toString("utf-8");
    } else {
      return res.status(400).json({
        success: false,
        message: "Sadece .txt veya .zip dosyaları desteklenir.",
      });
    }

    if (!chatText || chatText.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "Dosya içeriği boş veya okunamadı.",
      });
    }

    console.log(`[${uid}] Chat text extracted, length: ${chatText.length} chars`);

    // Truncate if too long (keep beginning and end)
    const MAX_CHARS = 50000;
    if (chatText.length > MAX_CHARS) {
      const halfSize = Math.floor(MAX_CHARS / 2);
      chatText = chatText.slice(0, halfSize) + "\n\n[... orta kısım çıkarıldı ...]\n\n" + chatText.slice(-halfSize);
      console.log(`[${uid}] Chat text truncated to ${MAX_CHARS} chars`);
    }

    // Analyze with LLM
    const analysis = await analyzeWhatsAppChat(chatText);

    console.log(`[${uid}] Analysis completed`);

    // Save to Firestore (optional)
    let analysisDocId = null;
    try {
      const analysisRef = firestore
        .collection("relationship_analyses")
        .doc(uid)
        .collection("analyses")
        .doc();

      await analysisRef.set({
        ...analysis,
        createdAt: new Date().toISOString(),
        userId: uid,
      });

      analysisDocId = analysisRef.id;
      console.log(`[${uid}] Analysis saved to Firestore: ${analysisRef.id}`);
    } catch (firestoreErr) {
      console.error(`[${uid}] Firestore save failed (non-critical):`, firestoreErr);
    }

    // Save/update relationship memory (per-user summary document)
    try {
      const memoryRef = firestore.collection("relationship_memory").doc(uid);

      await memoryRef.set(
        {
          ...analysis,
          lastUploadAt: new Date().toISOString(),
          source: "whatsapp_upload",
          lastAnalysisId: analysisDocId,
          isActive: true, // Reactivate on every upload
        },
        { merge: true }
      );

      console.log(`[${uid}] Relationship memory updated (isActive: true)`);
    } catch (memoryErr) {
      console.error(`[${uid}] Relationship memory save failed (non-critical):`, memoryErr);
    }

    // Return success response
    return res.status(200).json({
      success: true,
      message: "Analiz tamamlandı",
      analysis,
    });

  } catch (error) {
    console.error("analyzeRelationshipChatHandler error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Analiz sırasında bir hata oluştu.",
    });
  }
}

/**
 * Parse multipart form data with Busboy
 */
function parseMultipartForm(req) {
  return new Promise((resolve, reject) => {
    const busboy = Busboy({ 
      headers: req.headers,
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB limit
      }
    });
    let fileData = null;
    let fields = {};

    busboy.on("field", (fieldname, value) => {
      fields[fieldname] = value;
    });

    busboy.on("file", (fieldname, file, info) => {
      const { filename, encoding, mimeType } = info;
      const chunks = [];

      file.on("data", (chunk) => {
        chunks.push(chunk);
      });

      file.on("end", () => {
        fileData = {
          filename,
          buffer: Buffer.concat(chunks),
          encoding,
          mimeType,
        };
      });

      file.on("error", (err) => {
        reject(err);
      });
    });

    busboy.on("finish", () => {
      resolve({ fileData, fields });
    });

    busboy.on("error", (err) => {
      reject(err);
    });

    // Important: pipe the request to busboy
    if (req.rawBody) {
      // For Cloud Functions v2
      busboy.end(req.rawBody);
    } else {
      req.pipe(busboy);
    }
  });
}

/**
 * Extract .txt content from .zip file
 */
function extractTextFromZip(buffer) {
  try {
    const zip = new AdmZip(buffer);
    const zipEntries = zip.getEntries();

    // Find first .txt file
    for (const entry of zipEntries) {
      if (entry.entryName.toLowerCase().endsWith(".txt")) {
        return entry.getData().toString("utf-8");
      }
    }

    throw new Error("ZIP dosyası içinde .txt dosyası bulunamadı.");
  } catch (err) {
    throw new Error(`ZIP dosyası açılamadı: ${err.message}`);
  }
}
