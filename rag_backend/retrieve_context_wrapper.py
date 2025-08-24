import sys
sys.path.append(r'D:\PythonPackages')
import json
from retrieve import retrieve_context

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No query provided"}))
        sys.exit(1)

    query = sys.argv[1]
    top_k = 5  # you can increase for more context

    # retrieve top-k similar messages
    context_msgs = retrieve_context(query, top_k=top_k)

    # sort by ingestion order if available
    context_msgs.sort(key=lambda m: m.get("timestamp", 0))

    # format output for Dart
    output = []
    for msg in context_msgs:
        output.append({
            "actor": msg.get("actor"),
            "message": msg.get("message"),
            "image_path": msg.get("image_path"),
            "timestamp": msg.get("timestamp")
        })

    print(json.dumps(output, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
