import sys
import json
import os
from datetime import datetime
from sentence_transformers import SentenceTransformer
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
import torch
import numpy as np


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_FILE = os.path.join(BASE_DIR, "..", "data", "conversations.json")


text_model = SentenceTransformer("all-MiniLM-L6-v2")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

def load_data():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError:
            return []

def save_data(conversations):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(conversations, f, ensure_ascii=False, indent=2)

def compute_image_embedding(image_path):
    image = Image.open(image_path).convert("RGB")
    inputs = clip_processor(images=image, return_tensors="pt")
    with torch.no_grad():
        emb = clip_model.get_image_features(**inputs)
    return emb.squeeze().numpy()

def ingest_message(msg):
    conversations = load_data()

    msg.setdefault("message", "")
    msg.setdefault("timestamp", datetime.utcnow().isoformat())

    msg["text_embedding"] = text_model.encode(msg["message"]).tolist()

    if msg.get("image_path"):
        msg["image_embedding"] = compute_image_embedding(msg["image_path"]).tolist()
    else:
        msg["image_embedding"] = []

    conversations.append(msg)
    save_data(conversations)

    # Debug prints to confirm ingestion
    print(f"[INGEST] Added message: {msg}")
    print(f"[INGEST] Total messages: {len(conversations)}")

    return msg

if __name__ == "__main__":
    actor = sys.argv[1]
    message = sys.argv[2]
    image_path = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "" else None
    msg = {"actor": actor, "message": message, "image_path": image_path}
    ingest_message(msg)
    print("Message ingested successfully")

