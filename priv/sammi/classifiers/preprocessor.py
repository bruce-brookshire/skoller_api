import nltk
from nltk.tokenize.moses import MosesDetokenizer
from nltk.tokenize import line_tokenize
from nltk.tokenize import sent_tokenize
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords

class Preprocessor:

    def detokenize(self,tokens):
        detokenizer = MosesDetokenizer()
        return detokenizer.detokenize(tokens,return_str=True)

    def filter(self,words):
        stop_words = set(stopwords.words('english'))
        filtered_stop_words = [w for w in words if not w in stop_words]
        return filtered_stop_words

    def line_tokenize(self,text):
        lines = line_tokenize(text)
        return self.filter(lines)

    def word_tokenize(self,text):
        words = word_tokenize(text)
        return self.filter(words)

    def sent_tokenize(self,text):
        sents = sent_tokenize(text)
        return self.filter(sents)


# Allows Preprocessor to Be Called as Script
if __name__ == "__main__":
    p = Preprocessor()
    tokenized = p.word_tokenize(sys.argv[1])
    print(tokenized)
