import sys
sys.path.append(r'D:\PythonPackages')
import sys
import json
from retrieve import retrieve_context

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No query provided"}))
        sys.exit(1)

    query = sys.argv[1]
    top_k = 3  

    context_msgs = retrieve_context(query, top_k=top_k)

    output = []
    for msg in context_msgs:
        output.append({
            "actor": msg.get("actor"),
            "message": msg.get("message"),
            "image_path": msg.get("image_path")
        })

    print(json.dumps(output))

if __name__ == "__main__":
    main()
