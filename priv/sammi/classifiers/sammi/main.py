# GENERAL
import os
import json
import sys
# VENDOR
import nltk
import pickle
import random
from nltk.corpus import PlaintextCorpusReader
# CUSTOM
scriptpath = "./classifiers"
sys.path.append(os.path.abspath(scriptpath))
from base.main import BaseClassifier
from professor.main import ProfessorClassifier
from grade_scale.main import GradeScaleClassifier
from extractor import Extractor
from preprocessor import Preprocessor

class Sammi:

    def __init__(self, classifier=None):
        self.Extractor = Extractor()
        self.Preprocessor = Preprocessor()
        self.BaseClassifier = BaseClassifier()
        self.GradeScaleClassifier = GradeScaleClassifier()
        self.ProfessorClassifier = ProfessorClassifier()
        self.classifier = classifier
        self.train_set = None
        self.test_set = None
        # On Init, if no classifier is passed in
        # Load classifier from file
        if classifier is None:
            self.load_classifier()
        else:
            self.classifier = classifier

    # PERSISTANCE
    def load_classifier(self):
        path = "storage/sammi.pickle"
        if os.path.isfile(path):
            load = open(path, "rb")
            classifier = pickle.load(load)
            self.classifier = classifier
            load.close()

    def save_classifier(self,classifier):
        save = open("storage/sammi.pickle","wb")
        pickle.dump(classifier, save)
        save.close()

    # CORPUS
    def get_corpus(self,filename):
        corpus_root = "./corpora/"
        corpus = PlaintextCorpusReader(corpus_root,filename)
        res = eval(corpus.raw())
        return res

    def custom_corpus(self):
        res = []
        for subdir, dirs, files in os.walk("./corpora"):
            for corpus_file in files:
                corporized = self.get_corpus(corpus_file)
                if len(corporized) > 0:
                    for corp in corporized:
                        res.append(corp)
        return res

    def generate_detail_corpora(self,detail_type,detail_field=None):
        arr = []
        tagged_sents = self.custom_corpus()
        filename = (detail_field+'_detail.txt') if detail_field else (detail_type+'_detail.txt')
        for tagged_sent in tagged_sents:
            for i, (word, tag) in enumerate(tagged_sent):
                if detail_type == 'professor' and detail_field and tag == detail_field:
                    arr.append((word, tag))
                elif detail_type == 'grade_scale' and tag == 'GradeScale':
                    arr.append((word, tag))
        with open('./classifiers/'+detail_type+'/detail/corpora/'+filename, "w") as corpus_file:
            corpus_file.write(str(arr))

    # CLASSIFY
    def features(self,sentence,words,i,history):
        # Get info
        word = words[i]
        prev_word = "" if i == 0 else words[i-1]
        prev_pos = "<START>" if i == 0 else self.BaseClassifier.tag(words,i-1)
        prev_tag = "<START>" if i == 0 else history[i-1]
        # Declare features hash
        features = {}
        # Generic Features
        features = self.BaseClassifier.base_features(features,word,prev_pos,prev_tag,words,i,history)
        # Professor Features
        features = self.ProfessorClassifier.professor_features(features,sentence,words,i)
        # Grade Scale Features
        features = self.GradeScaleClassifier.grade_scale_features(features,word,prev_word,words,i,history)
        return features

    # TRAINING
    def base_sent_training(self):
        tagged_sents = self.custom_corpus()
        featuresets = []
        for tagged_sent in tagged_sents:
            history = []
            untagged_sent = nltk.tag.untag(tagged_sent)
            sent_text = self.Preprocessor.detokenize(untagged_sent)
            for i, (word, tag) in enumerate(tagged_sent):
                featureset = (self.features(sent_text,untagged_sent,i,history), tag)
                featuresets.append(featureset)
                history.append(tag)
        size = int(len(featuresets) * 0.1)
        random.shuffle(featuresets)
        self.train_set, self.test_set = featuresets[size:], featuresets[:size]
        classifier = nltk.NaiveBayesClassifier.train(self.train_set)
        return classifier

    def basic_training(self):
        classifier = self.base_sent_training()
        self.classifier = classifier
        self.save_classifier(classifier)
        return self

    # OUTPUT

    def pretty_print(self,json_object):
        return json.dumps(json_object, sort_keys=True, indent=4, separators=(',', ': '))

    def current_stats(self):
        if self.classifier is None:
            self.load_classifier()
        print({'labels': self.classifier.labels()})
        self.classifier.show_most_informative_features(100)

    def extract(self,filepath):
        output = self.parse(filepath)
        professor_info_obj = self.ProfessorClassifier.extract(output)
        grade_scale_obj = self.GradeScaleClassifier.extract(output)
        print({'professor_info': professor_info_obj,'grade_scale':grade_scale_obj})

    def grade_scale(self,filepath):
        output = self.parse(filepath)
        grade_scale_obj = self.GradeScaleClassifier.extract(output)
        print(grade_scale_obj)

    def parse(self,filepath):
        text = self.Extractor.text(filepath)
        sentences = self.Preprocessor.sent_tokenize(text)
        output = []
        for sent in sentences:
            history = []
            words = self.Preprocessor.word_tokenize(sent)
            for i,word in enumerate(words):
                # Get features
                feats = self.features(sent,words,i,history)
                # Find Tag
                res = self.classifier.classify(feats)
                # Get Probability of Tag
                prob = self.classifier.prob_classify(feats).prob(res)
                # Append to Output
                output.append((word,res,prob))
                # Update History
                history.append(res)
        return output

    def professor_info(self,filepath):
        output = self.parse(filepath)
        professor_info_obj = self.ProfessorClassifier.extract(output)
        print(professor_info_obj)

    def tag_sentence(self,sentence):
        words = self.Preprocessor.word_tokenize(sentence)
        history = []
        for i,word in enumerate(words):
            # Get features
            feats = self.features(words,i,history)
            # Find Tag
            res = self.classifier.classify(feats)
            # Get Probability of Tag
            prob = self.classifier.prob_classify(feats).prob(res)
            # Append to Output
            print(word+": "+res+"("+str(prob*100)+")")
            # Update History
            history.append(res)

# Allows Sammi to Be Called as Script
if __name__ == "__main__":
    sammi = Sammi()
    # TRAIN
    if len(sys.argv) > 1 and sys.argv[1] == 'train':
        sammi.basic_training()
        print("LABELS: "+str(sammi.classifier.labels()))
        print("ACCURACY: "+str(nltk.classify.accuracy(sammi.classifier,sammi.test_set)))
        sammi.classifier.show_most_informative_features(25)
    # CURRENT STATS
    elif len(sys.argv) > 1 and sys.argv[1] == 'stats':
        sammi.current_stats()
    # GENERATE NEW SYLLABI CORPUS
    elif len(sys.argv) > 2 and sys.argv[1] == 'corporize':
        sammi.generate_detail_corpora(sys.argv[2],sys.argv[3])
    # TAG GIVEN SENTENCE
    elif len(sys.argv) > 2 and sys.argv[1] == 'tag':
        sammi.tag_sentence(sys.argv[2])
    # NO CLASSIFIER FOUND
    elif sammi.classifier == None:
        print('Sammi not Found. Please run the train method.')
    # EXTRACT AND PRINT (I.E. CLASSIFY) ALL DATA POINTS FOR A GIVEN FILE
    elif len(sys.argv) > 2 and sys.argv[1] == 'extract':
        sammi.extract(sys.argv[2])
    # EXTRACT AND PRINT (I.E. CLASSIFY) PROFESSOR INFO FOR A GIVEN FILE
    elif len(sys.argv) > 2 and sys.argv[1] == 'professor_info':
        sammi.professor_info(sys.argv[2])
    # EXTRACT AND PRINT (I.E. CLASSIFY) GRADE SCALE FOR A GIVEN FILE
    elif len(sys.argv) > 2 and sys.argv[1] == 'grade_scale':
        sammi.grade_scale(sys.argv[2])
    # INVALID PARAMS
    else:
        print('Invalid params.')
