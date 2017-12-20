
class GradeScalePostProcessor:

    letter_key = ['A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','F']

    def filter_invalid_keys(self,res):
        iterable = dict(res)
        for key in iterable:
            if key not in self.letter_key:
                del res[key]
        return res

    def get_grade_scale(self,parsed_output):
        res = ''
        current_grade_scale_min_value = None
        letters_after_range = False
        total_prob = 0
        total_prob_count = 0
        for i,result in enumerate(parsed_output):
            value, tag, prob = result[0], result[1], result[2]*100
            if tag != 'None':
                if tag == 'GradeScaleLetter' and value in self.letter_key and prob > 99.99 and (res == "" or res[-1] == "|"):
                    if current_grade_scale_min_value:
                        res += (value+","+current_grade_scale_min_value+"|")
                    else:
                        res += (value+",")
                    total_prob += prob
                    total_prob_count += 1
                elif tag == 'GradeScaleRange' or tag == 'GradeScaleMin' or tag == 'GradeScaleMax':
                    min_val = value[:2] if len(value) > 2 and value.find(".") == -1 else value
                    min_val = min_val[:-1] if min_val[-1] == "+" else min_val
                    # If res is blank, this is first grade scale thing and ranges come first (assuming it meets some min prob threshold)
                    #  > 50 is an extra guard to make sure it doesn't grab this value too soon
                    if not res and min_val.isdigit() and float(min_val) > 80:
                        letters_after_range = True
                    if letters_after_range:
                        current_grade_scale_min_value = min_val
                        total_prob += prob
                        total_prob_count += 1
                    elif res and res[-1] == ",":
                        res += (min_val+"|")
                        total_prob += prob
                        total_prob_count += 1
            # stop if all letters grabbed
            if sum(l in res for l in self.letter_key) == len(self.letter_key):
                break
        return {"value": res, "probability": total_prob/total_prob_count if total_prob_count > 0 else 0}

    def objectify(self,parsed_output):
        obj = {}
        obj["grade_scale"] = self.get_grade_scale(parsed_output)
        return obj
