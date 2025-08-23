import sys
sys.path.append(r'D:\PythonPackages')
import json
import os
from sentence_transformers import SentenceTransformer
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
import torch
import numpy as np

DATA_FILE = os.path.join("..", "data", "conversations.json")

text_model = SentenceTransformer("all-MiniLM-L6-v2")
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

def load_data():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_data(conversations):
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

    
    if "message" not in msg:
        msg["message"] = ""

   
    msg["text_embedding"] = text_model.encode(msg["message"]).tolist()
    if msg.get("image_path"):
        msg["image_embedding"] = compute_image_embedding(msg["image_path"]).tolist()
    else:
        msg["image_embedding"] = []

    conversations.append(msg)
    save_data(conversations)
    return msg
