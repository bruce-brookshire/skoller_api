
class ProfessorPostProcessor:

    professor_name_key = ['prof','professor','instructor','dr','ms','mrs','mr','phd','prof.','dr.','ms.','mrs.','mr.']
    email_key = ['.edu','.com','.org']

    def get_professor_email(self,parsed_output):
        prof_email = ""
        prof_prob = 0
        prof_prob_count = 0
        for i,result in enumerate(parsed_output):
            value, tag, prob = result[0], result[1], result[2]*100
            if tag != "None" and prob > 80:
                if tag == "ProfessorEmail" and value == "@" and not prof_email:
                    prof_email += parsed_output[i-1][0]
                if tag == "ProfessorEmail" and (any(suffix in value for suffix in self.email_key)) and not prof_email:
                    prof_email += parsed_output[i-2][0]
                    prof_email += parsed_output[i-1][0]
                if tag == "ProfessorEmail":
                    prof_email += value
                    prof_prob += prob
                    prof_prob_count += 1
                    # Only get the first email, since its probably the professors
                    if len(value) > 2 and value[-4:] in self.email_key:
                        break
        return {"value": prof_email, "probability": prof_prob/prof_prob_count if prof_prob_count > 0 else 0}

    def get_professor_name(self,parsed_output):
        prof_name = ""
        prof_prob = 0
        prof_prob_count = 0
        for i,result in enumerate(parsed_output):
            value, tag, prob = result[0], result[1], result[2]*100
            if tag != "None" and prob > 80:
                if tag == "ProfessorName":
                    prof_name += (value+" ")
                    prof_prob += prob
                    prof_prob_count += 1
                if len(prof_name.split(" ")) > 3:
                    break
        return {"value": prof_name, "probability": prof_prob/prof_prob_count if prof_prob_count > 0 else 0}

    def get_professor_phone(self,parsed_output):
        prof_phone = ""
        prof_prob = 0
        prof_prob_count = 0
        for i,result in enumerate(parsed_output):
            value, tag, prob = result[0], result[1], result[2]*100
            if tag != "None" and prob > 80:
                if tag == "ProfessorPhone":
                    prof_phone += (value.replace('-',''))
                    prof_prob += prob
                    prof_prob_count += 1
                    if len(prof_phone) >= 7:
                        break
        return {"value": prof_phone, "probability": prof_prob/prof_prob_count if prof_prob_count > 0 else 0}

    def get_office_hours(self,parsed_output):
        office_hours = ''
        prob_val = 0
        prob_count = 0
        day_i = None
        for i,result in enumerate(parsed_output):
            value, tag, prob = result[0], result[1], result[2]*100
            if tag == "OfficeHoursDay":
                if day_i is None and prob > 99:
                    day_i = i
                if day_i and (i - day_i) < 20:
                    office_hours += (value+" ")
                    prob_val += prob
                    prob_count += 1
            elif tag == "OfficeHoursTime" or tag == "OfficeHoursSeparator":
                if office_hours and day_i and (i - day_i) < 20:
                    office_hours += (value+" ")
                    prob_val += prob
                    prob_count += 1
        return {"value": office_hours, "probability": prob_val/prob_count if prob_count > 0 else 0}

    def get_office_location(self,parsed_output):
        office_location = ""
        prof_prob = 0
        prof_prob_count = 0
        for i,result in enumerate(parsed_output):
            value, tag, prob = result[0], result[1], result[2]*100
            if tag != "None" and prob > 90:
                if tag == "OfficeLocation":
                    office_location += value
                    prof_prob += prob
                    prof_prob_count += 1
                    if any(char.isdigit() for char in office_location) and any(char.isalpha() for char in office_location):
                        break
        return {"value": office_location, "probability": prof_prob/prof_prob_count if prof_prob_count > 0 else 0}

    def objectify(self,parsed_output):
        obj = {}
        # NAME
        prof_name_obj = self.get_professor_name(parsed_output)
        obj["name"] = {"value": prof_name_obj["value"], "probability": prof_name_obj["probability"]}
        # EMAIL
        prof_email_obj = self.get_professor_email(parsed_output)
        obj["email"] = {"value": prof_email_obj["value"], "probability": prof_email_obj["probability"]}
        # PHONE
        prof_phone_obj = self.get_professor_phone(parsed_output)
        obj["phone"] = {"value": prof_phone_obj["value"], "probability": prof_phone_obj["probability"]}
        # OFFICE HOURS
        office_hours_obj = self.get_office_hours(parsed_output)
        obj["office_hours"] = {"value": office_hours_obj["value"], "probability": office_hours_obj["probability"]}
        # OFFICE LOCATION
        office_location_obj = self.get_office_location(parsed_output)
        obj["office_location"] = {"value": office_location_obj["value"], "probability": office_location_obj["probability"]}
        return obj
