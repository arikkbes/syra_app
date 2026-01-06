/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP ANALYSIS HANDLER V2
 * ═══════════════════════════════════════════════════════════════
 * Handles WhatsApp chat uploads and triggers the processing pipeline
 * 
 * New architecture:
 * - relationships/{uid}/{relationshipId} (master doc)
 * - relationships/{uid}/{relationshipId}/chunks/{chunkId} (lite index)
 * - Storage: relationship_chunks/{uid}/{relationshipId}/{chunkId}.txt
 * ═══════════════════════════════════════════════════════════════
 */

import Busboy from "busboy";
import AdmZip from "adm-zip";
import { auth, db as firestore } from "../config/firebaseAdmin.js";
import { processRelationshipUpload } from "../services/relationshipPipeline.js";

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
      console.log(`[${uid}] Relationship analysis request (V2 Pipeline)`);
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

    // Check for existing relationship ID (for updates)
    const existingRelationshipId = fields.relationshipId || null;
    const forceUpdate = fields.forceUpdate === "true" || fields.forceUpdate === true;

    // Process with new pipeline
    const result = await processRelationshipUpload(uid, chatText, existingRelationshipId, forceUpdate);

    // ═══════════════════════════════════════════════════════════════
    // MODULE 3: Handle mismatch detection
    // ═══════════════════════════════════════════════════════════════
    if (result.mismatchDetected) {
      console.log(`[${uid}] Mismatch detected, returning warning to client`);
      return res.status(200).json({
        success: false,
        mismatchDetected: true,
        reason: result.reason,
        suggestedAction: result.suggestedAction,
      });
    }

    console.log(`[${uid}] Pipeline complete: ${result.chunksCount} chunks, ${result.messagesCount} messages`);

    // Return success response
    return res.status(200).json({
      success: true,
      message: "Analiz tamamlandı",
      relationshipId: result.relationshipId,
      summary: result.masterSummary,
      stats: {
        totalMessages: result.messagesCount,
        totalChunks: result.chunksCount,
        speakers: result.speakers,
      },
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
        fileSize: 50 * 1024 * 1024, // 50MB limit (increased for larger chats)
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

    if (req.rawBody) {
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
      if (entry.entryName.toLowerCase().endsWith(".txt") && !entry.entryName.startsWith("__MACOSX")) {
        return entry.getData().toString("utf-8");
      }
    }

    throw new Error("ZIP dosyası içinde .txt dosyası bulunamadı.");
  } catch (err) {
    throw new Error(`ZIP dosyası açılamadı: ${err.message}`);
  }
}