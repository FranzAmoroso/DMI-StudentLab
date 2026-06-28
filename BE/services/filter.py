import json
import random
import os
def shuffle_filter(department, course, sub):
    path = os.path.join("data/dmi/question","iem.json")
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

def validate_answer(idQuestion, idChoice):
    path = os.path.join("data/dmi/question","iem.json")
    with open(path, "r") as file:
        all = json.load(file)

        for d in all:
            if str(d['id_question']) == str(idQuestion):
                return d['id_correct'] == idChoice
        return None