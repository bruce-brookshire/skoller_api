# GENERAL
import os
import sys

import nltk
# CUSTOM
scriptpath = "./classifiers"
sys.path.append(os.path.abspath(scriptpath))
from grade_scale.postprocessor import GradeScalePostProcessor

class GradeScaleClassifier:

    grade_key = ["A+","A","A-","B+","B","B-","C+","C","C-","D+","D","D-"]
    grade_scale_key = ["grade","grades","evaluation","scale"]

    def __init__(self):
        self.PostProcessor = GradeScalePostProcessor()

    def grade_scale_precursor(self,previous_word):
        digits = sum(l.isdigit() for l in previous_word)
        periods = sum(l == '.' for l in previous_word)
        correct_number_style = digits == 2 or (digits == 3 and periods == 1)
        is_key = previous_word == "100" or previous_word == "0" or previous_word == "=" or previous_word == "-"
        if correct_number_style or is_key:
            return True
        else:
            return False

    def in_grade_range(self,word):
        if word.isdigit():
            num = float(word)
            return num <= 100 and num >= 0
        else:
            return False

    # CHUNK GRAMMER
    def grammer(self):
        return (
            "GRADESCALE: {<GradeScaleKey>?<:>?<GradeScale.*>{3,}}"
        )

    # FEATURES (adds grade scale features to given features objectd)
    def grade_scale_features(self,features,word,prev_word,words,i,history):
        features["after-dash"] = prev_word == "-"
        features["follows-scale-key"] = sum((w.lower() in self.grade_scale_key) and words.index(w) < i and i - words.index(w) < 5 for w in words) > 0
        features["in-grade-range"] = self.in_grade_range(word)
        features["is-dash"] = word == "-"
        features["is-grade-key"] = word in self.grade_key
        features["has-grade-scale-precusor"] = self.grade_scale_precursor(prev_word)
        features["has-grade-scale-symbol"] = any(char in ["+","-"] for char in word)
        features["numbers-surround-dash"] = word[0].isdigit() and word[-1].isdigit() and any(char == "-" for char in word) and sum(char.isalpha() for char in word) == 0
        features["one-capital-letter"] = sum(char.isalpha() for char in word) == 1 and sum(char.isupper() for char in word) == 1
        features["sentence-has-grade-scale-key"] = any(word.lower() in self.grade_scale_key for word in words)
        features["sentence-has-multiple-grade-scale-keys"] = sum(word.lower() in self.grade_scale_key for word in words) > 1
        return features

    def chunk(self,text):
        cp = nltk.RegexpParser(self.grammer())
        res = cp.parse(text)
        return res

    def extract(self,output):
        return self.PostProcessor.objectify(output)

# Allows Grade Scale Classifier to Be Called as Script
if __name__ == "__main__":
    print('one sec')
