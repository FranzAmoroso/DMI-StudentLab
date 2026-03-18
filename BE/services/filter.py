import json
import random
import os
def shuffle_filter(dipartimento, corso, materia):
    path = os.path.join("data","questions.json")
    with open (path, "r") as file:
        all = json.load(file)

        filtered = {
            d for d in all
            if d['metadata']['dipartimento'] == dipartimento
            and d['metadata']['corso'] == corso
            and d['metadata']['materia'] == materia
        }

        for d in filtered:
            random.shuffle(d['opzioni'])
        return filtered

def validate_answer(id_domanda, id_scelta):
    path = os.path.join("data","questions.json")
    with open(path, "r") as file:
        all = json.load(file)

        for d in all:
            if str(d['id_domanda']) == str(id_domanda):
                return d['id_corretta'] == id_scelta
            return None