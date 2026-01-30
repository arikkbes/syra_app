import { openai } from "../config/openaiClient.js";
import { getSupabaseClient } from "./supabaseClient.js";

const EMBEDDING_MODEL = "text-embedding-3-small";
const EMBEDDING_BATCH_SIZE = 64;
const UPSERT_BATCH_SIZE = 200;

function buildEmbeddingText(chunkIndex) {
  const anchorsText = (chunkIndex.anchors || [])
    .map((anchor) => {
      if (typeof anchor === "string") return anchor;
      if (anchor?.quote) return anchor.quote;
      if (anchor?.context) return anchor.context;
      try {
        return JSON.stringify(anchor);
      } catch (e) {
        return String(anchor);
      }
    })
    .join(" | ");

  return `${chunkIndex.summary || ""}\nAnchors:${anchorsText}\nRange:${
    chunkIndex.dateRange || ""
  }`;
}

async function createEmbeddings(inputs) {
  if (!openai) {
    throw new Error("OpenAI client not configured");
  }

  const response = await openai.embeddings.create({
    model: EMBEDDING_MODEL,
    input: inputs,
  });

  return response.data.map((item) => item.embedding);
}

async function flushUpserts(supabase, rows) {
  if (!rows.length) return;
  const { error } = await supabase
    .from("message_embeddings")
    .upsert(rows, { onConflict: "uid,relationship_id,message_id" });

  if (error) {
    throw new Error(`Failed to upsert chunk embeddings: ${error.message}`);
  }
}

export async function clearSemanticIndex(uid, relationshipId) {
  const supabase = getSupabaseClient();
  const { error } = await supabase
    .from("message_embeddings")
    .delete()
    .eq("uid", uid)
    .eq("relationship_id", relationshipId);

  if (error) {
    throw new Error(`Failed to clear semantic index: ${error.message}`);
  }
}

export async function indexChunksToSupabase({
  uid,
  relationshipId,
  chunkIndexes,
}) {
  if (!chunkIndexes || chunkIndexes.length === 0) {
    return { indexed: 0 };
  }

  const supabase = getSupabaseClient();
  const pendingRows = [];
  let indexed = 0;

  for (let i = 0; i < chunkIndexes.length; i += EMBEDDING_BATCH_SIZE) {
    const batch = chunkIndexes.slice(i, i + EMBEDDING_BATCH_SIZE);
    const inputs = batch.map(buildEmbeddingText);
    const embeddings = await createEmbeddings(inputs);

    batch.forEach((chunkIndex, offset) => {
      pendingRows.push({
        uid,
        relationship_id: relationshipId,
        message_id: chunkIndex.chunkId,
        ts: chunkIndex.startDate || null,
        sender: "CHUNK",
        text: inputs[offset],
        embedding: embeddings[offset],
      });
    });

    while (pendingRows.length >= UPSERT_BATCH_SIZE) {
      const rows = pendingRows.splice(0, UPSERT_BATCH_SIZE);
      await flushUpserts(supabase, rows);
      indexed += rows.length;
    }
  }

  if (pendingRows.length) {
    await flushUpserts(supabase, pendingRows);
    indexed += pendingRows.length;
    pendingRows.length = 0;
  }

  return { indexed };
}
