/**
 * ═══════════════════════════════════════════════════════════════
 * RELATIONSHIP JOB WORKER
 * ═══════════════════════════════════════════════════════════════
 * Background worker for processing relationship upload jobs
 * Triggered by Pub/Sub messages
 * ═══════════════════════════════════════════════════════════════
 */

import admin from "../config/firebaseAdmin.js";
import { db, FieldValue } from "../config/firebaseAdmin.js";
import { processRelationshipUpload } from "../services/relationshipPipeline.js";
import AdmZip from "adm-zip";

const storage = admin.storage().bucket();

/**
 * Process a single relationship job
 * @param {object} message - Pub/Sub message with { uid, jobId }
 */
export async function processRelationshipJob(message) {
  const { uid, jobId } = message;
  
  console.log(`[${uid}][${jobId}] Starting job processing...`);

  // Reference to job document
  const jobRef = db.collection("users").doc(uid).collection("relationship_jobs").doc(jobId);

  try {
    // Load job document
    const jobDoc = await jobRef.get();
    
    if (!jobDoc.exists) {
      throw new Error(`Job document not found: ${jobId}`);
    }

    const jobData = jobDoc.data();
    
    // Check if job is already processed or processing
    if (jobData.status === "complete") {
      console.log(`[${uid}][${jobId}] Job already complete, skipping`);
      return;
    }
    
    if (jobData.status === "processing") {
      console.log(`[${uid}][${jobId}] Job already being processed, skipping`);
      return;
    }

    // Mark as processing
    await jobRef.update({
      status: "processing",
      updatedAt: FieldValue.serverTimestamp(),
      progress: {
        step: "downloading",
        percent: 0,
      },
    });

    console.log(`[${uid}][${jobId}] Downloading file from Storage: ${jobData.filePath}`);

    // Download file from Cloud Storage
    const file = storage.file(jobData.filePath);
    const [fileBuffer] = await file.download();

    console.log(`[${uid}][${jobId}] File downloaded: ${fileBuffer.length} bytes`);

    // Update progress
    await jobRef.update({
      progress: {
        step: "extracting",
        percent: 10,
      },
    });

    // Extract chat text based on file type
    let chatText;
    const filename = jobData.fileName.toLowerCase();

    if (filename.endsWith(".zip")) {
      chatText = extractTextFromZip(fileBuffer);
    } else if (filename.endsWith(".txt")) {
      chatText = fileBuffer.toString("utf-8");
    } else {
      throw new Error("Unsupported file type");
    }

    if (!chatText || chatText.trim().length === 0) {
      throw new Error("File content is empty or unreadable");
    }

    console.log(`[${uid}][${jobId}] Chat text extracted: ${chatText.length} chars`);

    // Update progress
    await jobRef.update({
      progress: {
        step: "processing",
        percent: 20,
      },
    });

    // MODULE 2: Progress callback to update job document during chunk processing
    let totalChunks = null;
    const progressCallback = async (processedChunks, total) => {
      totalChunks = total;
      // Calculate percent: 20% (base) + 70% (processing) * progress
      const percent = Math.min(20 + Math.floor((processedChunks / total) * 70), 90);
      
      try {
        await jobRef.update({
          progress: {
            step: "processing",
            percent: percent,
            processedChunks: processedChunks,
            totalChunks: total,
          },
          updatedAt: FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Don't fail the whole job if progress update fails
        console.error(`[${uid}][${jobId}] Progress update error:`, e);
      }
    };

    // Process with pipeline
    const result = await processRelationshipUpload(
      uid,
      chatText,
      jobData.existingRelationshipId || null,
      jobData.forceUpdate || false,
      jobData.updateMode || "smart",
      progressCallback
    );

    // Handle mismatch detection
    if (result.mismatchDetected) {
      console.log(`[${uid}][${jobId}] Mismatch detected during processing`);
      
      await jobRef.update({
        status: "complete",
        updatedAt: FieldValue.serverTimestamp(),
        mismatchDetected: true,
        mismatchReason: result.reason,
        suggestedAction: result.suggestedAction,
        progress: {
          step: "complete",
          percent: 100,
        },
      });

      console.log(`[${uid}][${jobId}] Job completed with mismatch warning`);
      return;
    }

    // Success - update job with result
    await jobRef.update({
      status: "complete",
      updatedAt: FieldValue.serverTimestamp(),
      progress: {
        step: "complete",
        percent: 100,
      },
      result: {
        relationshipId: result.relationshipId,
        summaryShort: result.masterSummary || "Analysis complete",
        stats: {
          totalMessages: result.messagesCount,
          totalChunks: result.chunksCount,
          speakers: result.speakers,
        },
      },
    });

    console.log(`[${uid}][${jobId}] Job completed successfully - ${result.chunksCount} chunks, ${result.messagesCount} messages`);

  } catch (error) {
    console.error(`[${uid}][${jobId}] Job processing error:`, error);

    // Mark job as failed
    await jobRef.update({
      status: "failed",
      updatedAt: FieldValue.serverTimestamp(),
      error: {
        message: error.message || "Unknown error occurred",
        stack: error.stack,
      },
      progress: {
        step: "failed",
        percent: 0,
      },
    });

    // Re-throw to ensure Cloud Functions logs the error
    throw error;
  }
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

    throw new Error("No .txt file found in ZIP");
  } catch (err) {
    throw new Error(`Failed to extract ZIP: ${err.message}`);
  }
}
