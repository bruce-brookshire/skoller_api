# GENERAL
import os
import sys
# VENDOR
import enchant
english_dictionary = enchant.Dict("en_US")
import nltk
import pickle
import random
from nltk.corpus import brown
# CUSTOM
scriptpath = "./classifiers"
sys.path.append(os.path.abspath(scriptpath))
from extractor import Extractor
from preprocessor import Preprocessor

class BaseClassifier:

    def __init__(self, classifier=None):
        self.Extractor = Extractor()
        self.Preprocessor = Preprocessor()
        self.classifier = classifier
        self.train_set = None
        self.test_set = None
        # On Init, if no classifier is passed in
        # Load classifier from file
        if classifier is None:
            self.load_classifier()
        else:
            self.classifier = classifier

    # Persistance
    def load_classifier(self):
        path = "storage/base_classifier.pickle"
        if os.path.isfile(path):
            load = open(path, "rb")
            classifier = pickle.load(load)
            self.classifier = classifier
            load.close()

    def save_classifier(self,classifier):
        save = open("storage/base_classifier.pickle","wb")
        pickle.dump(classifier, save)
        save.close()

    # FEATURES
    # determines how things are classified for POS tagging
    def features(self,sentence,i):
        word = sentence[i]
        features = {"suffix(1)": sentence[i][-1:],
                    "suffix(2)": sentence[i][-2:],
                    "suffix(3)": sentence[i][-3:]}
        features["capitalized"] = word[0].isupper()
        features["has_numbers"] = sum(d.isdigit() for d in word) > 0
        if i == 0:
            features["prev-word"] = "<START>"
        else:
            features["prev-word"] = sentence[i-1]
        return features

    # determines basic features for sammi tagging
    def base_features(self,features,word,prev_pos,prev_tag,words,i,history):
        features["all-caps"] = sum(l.isupper() for l in word) == len(word)
        features["capitalized"] = word[0].isupper()
        features["has-@"] = any(l == '@' for l in word)
        features["has-colon"] = any(l == ':' for l in word)
        features["has-dash"] = any(l == '-' for l in word)
        features["has-number"] = any(l.isdigit() for l in word)
        features["is-english-word"] = english_dictionary.check(word)
        features["is-separator"] = word == ';' or word == ','
        features["pos"] = self.tag(words,i)
        features["prev-pos"] = prev_pos
        features["prev-tag"] = prev_tag
        features["prev-word"] = words[i-1] if i > 0 else "<START>"
        features["prev-prev-word"] = words[i-2] if i > 1 else "<START>"
        features["starts-with"] = word[0]
        features["zero-letters"] = sum(l.isalpha() for l in word) == 0
        return features

    # Training
    def base_sent_training(self):
        # tagged_sents = brown.tagged_sents(categories='news')
        tagged_sents = brown.tagged_sents()
        featuresets = []
        for tagged_sent in tagged_sents:
            untagged_sent = nltk.tag.untag(tagged_sent)
            for i, (word, tag) in enumerate(tagged_sent):
                featuresets.append( (self.features(untagged_sent, i), tag) )
        size = int(len(featuresets) * 0.1)
        self.train_set, self.test_set = featuresets[size:], featuresets[:size]
        classifier = nltk.NaiveBayesClassifier.train(self.train_set)
        return classifier

    # Creates a new trained classifier (or overwrites existing) from scratch
    def basic_training(self):
        classifier = self.base_sent_training()
        self.classifier = classifier
        self.save_classifier(classifier)
        return self

    # Takes a file and returns a list of classified words (POS tagging)
    def parse(self,filepath):
        text = self.Extractor.text(filepath)
        tokenized_text = self.Preprocessor.sent_tokenize(text)
        output = []
        for sent in tokenized_text:
            words = self.Preprocessor.word_tokenize(sent)
            for i,word in enumerate(words):
                feats = self.features(words,i)
                res = self.classifier.classify(feats)
                output.append((word,res))
        return output

    def tag(self,words,i):
        feats = self.features(words,i)
        res = self.classifier.classify(feats)
        return res

# Allows Base Classifier to Be Called as Script
if __name__ == "__main__":
    base_classifier = BaseClassifier()
    # Train it
    if len(sys.argv) > 1 and sys.argv[1] == 'train':
        base_classifier = base_classifier.basic_training()
        print("ACCURACY: "+str(nltk.classify.accuracy(base_classifier.classifier,base_classifier.test_set)))
        base_classifier.classifier.show_most_informative_features(25)
    # Hasn't been trained yet
    elif base_classifier.classifier == None:
        print('No Base Classifier Found. Please run the train method.')
    # Parse it
    elif len(sys.argv) > 1:
        output = base_classifier.parse(sys.argv[1])
        print(output)
    # Invalid params
    else:
        print('Please pass in a filepath to be parsed.')
