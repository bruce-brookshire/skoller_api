# GENERAL
import os
import re
import sys
# CUSTOM
scriptpath = "./classifiers"
sys.path.append(os.path.abspath(scriptpath))
from professor.postprocessor import ProfessorPostProcessor

class ProfessorClassifier:

    # Put Most Specific (i.e. most meaningful) day keys at beginning of array as they are matched first in regex
    day_keys = ['Monday','monday','Tuesday','tuesday','Wednesday','wednesday','Thursday','thursday','Friday','friday',
                'Tues./Thurs.','Mon./Wed./Fri.','Tues/Thurs','Mon/Wed/Fri',
                'M/W','M/W/F','M/F','W/F','T/Th',
                'MTWR','MWF','MW','MF','TU/TH','TR','TU','TH',
                'Mon.','Tu.','Wed.','Th.','Fri.',
                'Mon','Tu','Wed','Th','Fri',
                'mon','tu','wed','th','fri',
                'M','W','F','T','R']
    office_hours_key = ['am','pm','office','hours']
    office_location_key = ['office','location','room','building','rm','rm.']
    professor_email_key = ['@','edu','org','.']
    professor_name_key = ['prof','professor','instructor','dr','ms','mrs','mr','phd','prof.','dr.','ms.','mrs.','mr.']
    professor_phone_key = ['-','(',')','0','1','2','3','4','5','6','7','8','9','x','X']

    def __init__(self):
        self.PostProcessor = ProfessorPostProcessor()

    # TESTS

    # Phone
    def extract_phone_numbers(self,string):
        r = re.compile(r'(\d{3}[-\.\s]??\d{3}[-\.\s]??\d{4}|\(\d{3}\)\s*\d{3}[-\.\s]??\d{4}|\d{3}[-\.\s]??\d{4})')
        return r.findall(string)

    # Email
    def extract_email_addresses(self,string):
        r = re.compile(r'[\w\.-]+@[\w\.-]+')
        return r.findall(string)

    # Office Hours
    def extract_day(self,string):
        days = "|".join(self.day_keys)
        r = re.compile(r'\b(?:'+days+')')
        return r.findall(string)

    def extract_time(self,string):
        r = re.compile(r'\d{1,2}(?:(?:am|pm|AM|PM)|(?::\d{1,2})(?:am|pm|AM|PM)?)')
        return r.findall(string)

    # Office Location
    def extract_office_location(self,string):
        r = re.compile(r'(\b[A-Z]+[a-z]*\s*)+\d{3,}[A-Z]*')
        return r.findall(string)

    # FEATURES (adds professor features to given features objectd)
    def professor_features(self,features,sentence,words,i):
        word = words[i]
        regex_phone_number_matches = self.extract_phone_numbers(sentence)
        regex_email_matches = self.extract_email_addresses(sentence)
        regex_day_matches = self.extract_day(sentence)
        regex_time_matches = self.extract_time(sentence)
        regex_office_location = self.extract_office_location(sentence)
        features["at-least-3-digits"] = sum(key.isdigit() for key in word) > 2
        features["seven-digits"] = sum(key.isdigit() for key in word) == 7
        features["ten-digits"] = sum(key.isdigit() for key in word) == 10
        features["has-professor-name-key"] = any(key in word.lower() for key in self.professor_name_key)
        features["has-multiple-professor-name-keys"] = sum(key in word.lower() for key in self.professor_name_key) > 1
        features["exact-day-match"] = word in self.day_keys
        features["follows-office-key"] = sum(w.lower() == "office" and words.index(w) < i and i - words.index(w) < 5 for w in words) > 0
        features["follows-hours-key"] = sum(w.lower() == "hours" and words.index(w) < i and i - words.index(w) < 5 for w in words) > 0
        features["matches-regex-phone-numbers"] = any(word in number for number in regex_phone_number_matches)
        features["matches-regex-email"] = any(word in email for email in regex_email_matches)
        features["matches-regex-day"] = any(word in day for day in regex_day_matches)
        features["matches-regex-time"] = any(word in time for time in regex_time_matches)
        features["matches-regex-office-location"] = any(word in loc for loc in regex_office_location)
        features["office-key"] = word.lower() == "office"
        features["only-phone-keys"] = sum(key in word.lower() for key in self.professor_phone_key) == len(word)
        features["phone-extension-format"] = sum(key.isdigit() for key in word) == len(word)-1 and "x" in word.lower()
        return features

    def extract(self,output):
        return self.PostProcessor.objectify(output)

# Allows Professor Classifier to Be Called as Script
if __name__ == "__main__":
    print('one sec')
