import sys
from retrieve import retrieve_context
from generation import generate_response  # your model generation logic

def main():
    query = sys.argv[1]
    context_msgs = retrieve_context(query, top_k=3)
    context_text = "\n".join([msg["message"] for msg in context_msgs])
    response = generate_response(query, context_text)
    print(response)

if __name__ == "__main__":
    main()
