import sys
sys.path.append(r"D:\PythonPackages")
from fastapi import FastAPI, Request
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
import uvicorn

app = FastAPI()

tokenizer = AutoTokenizer.from_pretrained("microsoft/Phi-3-mini-4k-instruct-gguf")
model = AutoModelForCausalLM.from_pretrained("microsoft/Phi-3-mini-4k-instruct-gguf")
generator = pipeline("text-generation", model=model, tokenizer=tokenizer)

@app.post("/chat")
async def chat(req: Request):
    data = await req.json()
    query = data["query"]
    output = generator(query, max_new_tokens=200)
    return {"response": output[0]["generated_text"]}

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)
