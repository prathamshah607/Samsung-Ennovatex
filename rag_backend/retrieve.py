import sys
sys.path.append(r'D:\PythonPackages')
import json
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import os

# Path to your JSON data
DATA_FILE = os.path.join(os.path.dirname(__file__), "../data/conversations.json")


text_model = SentenceTransformer("all-MiniLM-L6-v2")

def load_data():
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)

def save_data(data):
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def embed_message(msg):
    """
    Compute embedding for a message and optionally for an image
    """
    text_emb = text_model.encode(msg.get("message", msg.get("text", ""))).tolist()
    img_emb = msg.get("image_embedding", [])
    return text_emb + img_emb if img_emb else text_emb

def retrieve_context(query, top_k=3):
    conversations = load_data()
    
    if not conversations:
        return []

    
    for msg in conversations:
        if "text_embedding" not in msg:
            msg["text_embedding"] = text_model.encode(msg.get("message", msg.get("text", ""))).tolist()
    save_data(conversations)  # update JSON with embeddings if missing

    
    query_emb = text_model.encode(query).reshape(1, -1)

   
    embeddings = []
    for msg in conversations:
        e = np.array(msg.get("text_embedding", []))
        if msg.get("image_embedding"):
            e = np.concatenate([e, np.array(msg["image_embedding"])])
        embeddings.append(e)

    
    if not embeddings or embeddings[0].size == 0:
        return []

    embeddings = np.vstack(embeddings)
    sims = cosine_similarity(query_emb, embeddings)[0]
    top_indices = sims.argsort()[-top_k:][::-1]

    return [conversations[i] for i in top_indices]


if __name__ == "__main__":
    import sys
    query = " ".join(sys.argv[1:])
    results = retrieve_context(query)
    print(json.dumps(results, ensure_ascii=False, indent=2))
