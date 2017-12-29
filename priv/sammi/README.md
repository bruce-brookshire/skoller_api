
# Installation Requirements

  * Python3 (https://www.python.org/downloads/mac-osx/)
  * Ghostscript (brew install ghostscript)
  * ImageMagick (https://www.imagemagick.org/script/install-source.php) (REQUIRES V6)
    - ``ln -s /usr/local/Cellar/imagemagick@6/6.9.9-26/lib/libMagickWand-6.Q16.dylib /usr/local/lib/libMagickWand.dylib``
  * Wand (pip3 install wand)
  * Pillow (pip3 install Pillow)
  * Tesseract (``brew install tesseract`` for mac or ``sudo apt install tesseract-ocr`` for ubuntu)
  * pyocr (pip3 install pyocr)
  * pip3 install docx2text
  * pip3 install pyenchant
  * nltk (pip3 install -U nltk)
  * install nltk data (http://www.nltk.org/data.html)
    - if ssl error - run ``/Applications/Python 3.6/Install Certificates.command`` in command line

# Running

  * Ensure all the above requirements are installed
  * To extract all available data points from a file ``python3 ./classifiers/sammi/main.py extract <<path_to_file>>``
  * For just professor info ``python3 ./classifiers/sammi/main.py professor_info <<path_to_file>>``
  * For just grade scale ``python3 ./classifiers/sammi/main.py grade_scale <<path_to_file>>``
  * To retrain Sammi (i.e. loop through all 'corpora' files and train based off of their given classification) ``python3 ./classifiers/sammi/main.py train``
  * To get the current stats for Sammi (i.e. the labels it knows about and the confidence it has in classifying those) ``python3 ./classifiers/sammi/main.py stats``

# Part Of Speech Tag List:

  * CC	coordinating conjunction
  * CD	cardinal digit
  * DT	determiner
  * EX	existential there (like: "there is" ... think of it like "there exists")
  * FW	foreign word
  * IN	preposition/subordinating conjunction
  * JJ	adjective	'big'
  * JJR	adjective, comparative	'bigger'
  * JJS	adjective, superlative	'biggest'
  * LS	list marker	1)
  * MD	modal	could, will
  * NN	noun, singular 'desk'
  * NNS	noun plural	'desks'
  * NNP	proper noun, singular	'Harrison'
  * NNPS	proper noun, plural	'Americans'
  * PDT	predeterminer	'all the kids'
  * POS	possessive ending	parent's
  * PRP	personal pronoun	I, he, she
  * PRP$	possessive pronoun	my, his, hers
  * RB	adverb	very, silently,
  * RBR	adverb, comparative	better
  * RBS	adverb, superlative	best
  * RP	particle	give up
  * TO	to	go 'to' the store.
  * UH	interjection	errrrrrrrm
  * VB	verb, base form	take
  * VBD	verb, past tense	took
  * VBG	verb, gerund/present participle	taking
  * VBN	verb, past participle	taken
  * VBP	verb, sing. present, non-3d	take
  * VBZ	verb, 3rd person sing. present	takes
  * WDT	wh-determiner	which
  * WP	wh-pronoun	who, what
  * WP$	possessive wh-pronoun	whose
  * WRB	wh-abverb	where, when
