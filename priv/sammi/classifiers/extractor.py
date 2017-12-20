# https://github.com/openpaperwork/pyocr
import io
import os
import sys
# Vendor
import docx2txt
from PIL import Image as PI
import pyocr
import pyocr.builders
# Custom
from converter import Converter
from preprocessor import Preprocessor

class Extractor:

    def __init__(self):
        self.Converter = Converter()
        self.Preprocessor = Preprocessor()
        ################## TOOL ##################
        self.tools = pyocr.get_available_tools()
        if len(self.tools) == 0:
            print("No OCR tool found")
            sys.exit(1)
        # The tools are returned in the recommended order of usage
        self.tool = self.tools[0]
        ############### LANGUAGE #################
        self.langs = self.tool.get_available_languages()

    def base_tokenize(self,text):
        sentences = self.Preprocessor.sent_tokenize(text)
        arr = []
        for sent in sentences:
            sent_arr = []
            words = self.Preprocessor.word_tokenize(sent)
            for w in words:
                word_key = (w,'None')
                sent_arr.append(word_key)
            arr.append(sent_arr)
        return arr

    def corporize(self,filepath):
        txt = self.text(filepath)
        arr = self.base_tokenize(txt)
        base = os.path.basename(filepath)
        filename = os.path.splitext(base)[0]
        with open("./corpora/"+filename+".txt", "w") as corpus_file:
            corpus_file.write(str(arr))

    ############### GET ALL TEXT #################

    def text(self,filepath):
        extension = os.path.splitext(filepath)[1]
        if extension == '.docx' or extension == '.doc':
            text = docx2txt.process(filepath)
            return text
        else:
            req_image = self.Converter.convert(filepath)
            final_text = []
            for img in req_image:
                txt = self.tool.image_to_string(
                    PI.open(io.BytesIO(img)),
                    lang="eng",
                    builder=pyocr.builders.TextBuilder()
                )
                # txt is a Python string
                final_text.append(txt)
            return (" ").join(final_text)

    ############### GET WORD BOXES #################

    def words(self,filepath):
        req_image = self.Converter.convert(filepath)
        final_word_boxes = []
        # list of box objects. For each box object:
        #   box.content is the word in the box
        #   box.position is its position on the page (in pixels)
        for img in req_image:
            word_boxes = self.tool.image_to_string(
                PI.open(io.BytesIO(img)),
                lang="eng",
                builder=pyocr.builders.WordBoxBuilder()
            )
            final_word_boxes.append(word_boxes)
        return final_word_boxes

    ############### GET LINE BOXES #################

    def lines(self,filepath):
        req_image = self.Converter.convert(filepath)
        final_line_and_word_boxes = []
        # list of line objects. For each line object:
        #   line.word_boxes is a list of word boxes (the individual words in the line)
        #   line.content is the whole text of the line
        #   line.position is the position of the whole line on the page (in pixels)
        for img in req_image:
            line_and_word_boxes = self.tool.image_to_string(
                PI.open(io.BytesIO(img)), lang="eng",
                builder=pyocr.builders.LineBoxBuilder()
            )
            final_line_and_word_boxes.append(line_and_word_boxes)
        return final_line_and_word_boxes

# Allows Extractor to Be Called as Script
if __name__ == "__main__":
    e = Extractor()
    print(e.text(sys.argv[1]))
