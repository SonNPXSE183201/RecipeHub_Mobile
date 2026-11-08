"""Xáo đáp án tất định, chạy lại không đổi kết quả; không sửa nội dung câu hỏi.

python tools/seed/shuffle_quizzes.py [path/to/quizzes.json]
"""
import hashlib
import json
import sys
from pathlib import Path


def shuffle_quizzes(quizzes):
    for quiz in quizzes:
        for question in quiz["questions"]:
            options = question["options"]
            # Canonicalize before sorting so reruns produce the same order.
            correct = options[question["correctIndex"]]
            seed = f'{quiz["id"]}:{question["id"]}:'
            options.sort(key=lambda option: (
                hashlib.sha256((seed + option).encode("utf-8")).digest(), option))
            question["correctIndex"] = options.index(correct)
    return quizzes


if __name__ == "__main__":
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name("quizzes.json")
    data = json.loads(path.read_text(encoding="utf-8"))
    path.write_text(json.dumps(shuffle_quizzes(data), ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8")
