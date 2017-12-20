
class GradeScalePostProcessor:

    letter_key = ['A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-']

    def sort_grade_scale_text(self,text):
        arr = text.split("|")
        res = []
        for val in arr:
            val[0]

    def get_grade_scale(self,results):
        greatest_length = 0
        best_guess = None
        has_min_values = None
        res = {'A+': None,'A': None,'A-': None,'B+': None,'B': None,'B-': None,'C+': None,'C': None,'C-': None,'D+': None,'D': None,'D-': None}
        curr_res = ''
        for result in results:
            length = len(result)
            if length > greatest_length:
                greatest_length = length
                best_guess = result
        if best_guess:
            current_number = None
            current_letter = None
            letters_come_first = None
            grade_maxes = []
            for val in best_guess:
                # we need to see if letters come before or after grade scales
                if val[1] == 'GradeScaleLetter' and letters_come_first == None:
                    letters_come_first = True
                elif (val[1] == 'GradeScaleRange' or val[1] == 'GradeScaleMin' or val[1] == 'GradeScaleMax') and letters_come_first == None:
                    letters_come_first = False
                # then we need to actually segment the grades in the proper format
                if val[1] == 'GradeScaleLetter' and val[0] in self.letter_key:
                    # If letter come first, just append the value
                    if letters_come_first:
                        curr_res += (val[0]+",")
                        current_letter = val[0]
                    # If numbers come first append the value with the saved number
                    else:
                        res[val[0]] = val[0]+","+current_number if current_number else val[0]+","+grade_maxes[-1]
                elif val[1] == 'GradeScaleRange':
                    # If letters come first and the curr_res is expecting its next number, put it there
                    if letters_come_first and len(curr_res) > 0 and curr_res[-1] == ",":
                        curr_res += (val[0][:2])
                        res[current_letter] = curr_res
                        curr_res = ''
                    # If numbers come first and the curr_res is blank
                    elif not letters_come_first and curr_res == "":
                        current_number = val[0][:2]
                elif val[1] == 'GradeScaleMin':
                    # If letters come first and the curr_res is expecting its next number
                    if letters_come_first and len(curr_res) > 0 and curr_res[-1] == ",":
                        curr_res += (val[0])
                        res[current_letter] = curr_res
                        curr_res = ''
                    # If numbers come first and the curr_res is blank
                    elif not letters_come_first and curr_res == "":
                        current_number = val[0]
                # saving all references to grade scale max as sometimes the min is missing and we must use it
                elif val[1] == 'GradeScaleMax':
                    grade_maxes.append(val[0])
        final_val = ''
        for key,val in res.items():
            if val:
                final_val += (val+"|")
        return {'value':final_val.strip()}

    def objectify(self,parsed_output):
        potential_grade_scales = []
        for subtree in parsed_output.subtrees():
            label = subtree.label()
            if label == 'GRADESCALE':
                potential_grade_scales.append(subtree)
        grade_scale_obj = self.get_grade_scale(potential_grade_scales)
        return {"value": grade_scale_obj["value"]}
