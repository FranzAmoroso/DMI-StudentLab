import json
import random
import os
from pathlib import Path
def shuffle_filter(department, course, sub):
    path = os.path.join("data/dmi/question",f"{sub}.json")
    with open (path, "r") as file:
        all = json.load(file)

        filtered = [
            d for d in all
            if d['metadata']['department'] == department
            and d['metadata']['course'] == course
            and d['metadata']['sub'] == sub
        ]

        for d in filtered:
            random.shuffle(d['option'])
        return filtered

def validate_answer(idQuestion, idChoice, sub):
    BASE_DIR = Path(__file__).resolve().parent
    path = os.path.join(BASE_DIR, "/data/dmi/question",f"{sub}.json")
    with open(path, "r") as file:
        all = json.load(file)

        for d in all:
            if str(d['id_question']) == str(idQuestion):
                return {"correct": d['id_correct'] == idChoice}
        return None