
class ProfessorPostProcessor:

    professor_name_key = ['prof','professor','instructor','dr','ms','mrs','mr','phd','prof.','dr.','ms.','mrs.','mr.']
    email_key = ['.edu','.com','.org']

    def get_professor_email(self,results):
        greatest_length = 0
        best_guess = None
        res = ''
        for result in results:
            length = len(result)
            if length > greatest_length:
                greatest_length = length
                best_guess = result
        if best_guess:
            for val in best_guess:
                if val[1] == 'ProfessorEmail':
                    res += val[0]
        return {'value':res.strip()}

    def get_professor_name(self,results):
        greatest_length = 0
        best_guess = None
        found_name_key = False
        res = ''
        for result in results:
            for val in result:
                # If the result has one of the professor name keys
                # its almost certainly the professor name
                if val[0].lower() in self.professor_name_key:
                    found_name_key = True
                    best_guess = result
            length = len(result)
            if length > greatest_length and not found_name_key:
                greatest_length = length
                best_guess = result
        if best_guess:
            for val in best_guess:
                if val[1] == 'ProfessorName' and val[0][0].isupper():
                    res += (val[0]+" ")
                if len(res.split(" ")) > 3 and sum("." == l for l in res) < 2:
                    break
                # if it has two periods, its probably includes professor prefix and middle name
                elif len(res.split(" ")) > 4 and sum("." == l for l in res) == 2:
                    break
        return {'value':res.strip()}

    def get_professor_phone(self,results):
        most_phone_values = 0
        best_guess = None
        res = ''
        for result in results:
            num_of_phone_values = sum(val[1] == 'ProfessorPhone' for val in result)
            if num_of_phone_values > most_phone_values:
                most_phone_values = num_of_phone_values
                best_guess = result
        if best_guess:
            for val in best_guess:
                if val[1] == 'ProfessorPhone' or val[0] == "(" or val[0] == ")":
                    res += val[0]
                if val[1] == 'None' and (val[0] != "(" or val[0] != ")"):
                    break
        return {'value':res.strip()}

    def get_office_hours(self,results):
        greatest_length = 0
        best_guess = None
        res = ''
        for result in results:
            # we dont just care about length of results as in others
            # here, we also care how many were labeled as OfficeHoursDay and OfficeHoursTime (need at least 2)
            length = len(result)
            num_of_office_values = sum((val[1] == 'OfficeHoursDay' or val[1] == 'OfficeHoursTime') for val in result)
            if length > greatest_length and num_of_office_values > 1:
                greatest_length = length
                best_guess = result
        if best_guess:
            for val in best_guess:
                if val[1] == 'OfficeHoursDay' and res and res.strip()[-1].isalpha():
                    res = res.strip()
                elif val[1] == 'OfficeHoursTime' and res and res.strip()[-1].isdigit():
                    res = res.strip()
                if val[1] == 'OfficeHoursDay' or val[1] == 'OfficeHoursTime':
                    res += (val[0]+" ")
        return {'value':res.strip()}

    def get_office_location(self,results):
        greatest_length = 0
        greatest_location_building_keys = 0
        greatest_location_room_keys = 0
        best_guess = None
        res = ''
        for result in results:
            # we dont just care about length of results as in others
            # here, we also care how many were labeled as OfficeLocation
            length = len(result)
            num_of_location_building_values = sum(val[1] == 'OfficeLocationBuilding'for val in result)
            num_of_location_room_values = sum(val[1] == 'OfficeLocationRoom'for val in result)
            if length > greatest_length:
                greatest_length = length
                best_guess = result
            elif length == greatest_length:
                if num_of_location_building_values > greatest_location_building_keys and num_of_location_room_values > greatest_location_room_keys:
                    greatest_length = length
                    greatest_location_building_keys = num_of_location_building_values
                    greatest_location_room_keys = num_of_location_room_values
                    best_guess = result
        if best_guess:
            for val in best_guess:
                if val[1] == 'OfficeLocationBuilding' or val[1] == 'OfficeLocationRoom':
                    res += (val[0]+" ")
        return {'value':res.strip()}

    def objectify(self,parsed_output):
        obj = {}
        potential_prof_names = []
        potential_prof_emails = []
        potential_prof_phones = []
        potential_office_hours = []
        potential_office_locations = []
        for subtree in parsed_output.subtrees():
            label = subtree.label()
            if label == 'NAME':
                potential_prof_names.append(subtree)
            elif label == 'EMAIL':
                potential_prof_emails.append(subtree)
            elif label == 'PHONE':
                potential_prof_phones.append(subtree)
            elif label == 'OFFICEHOURS':
                potential_office_hours.append(subtree)
            elif label == 'OFFICELOCATION':
                potential_office_locations.append(subtree)
        prof_name_obj = self.get_professor_name(potential_prof_names)
        obj["name"] = {"value": prof_name_obj["value"]}
        prof_email_obj = self.get_professor_email(potential_prof_emails)
        obj["email"] = {"value": prof_email_obj["value"]}
        prof_phone_obj = self.get_professor_phone(potential_prof_phones)
        obj["phone"] = {"value": prof_phone_obj["value"]}
        office_hours_obj = self.get_office_hours(potential_office_hours)
        obj["office_hours"] = {"value": office_hours_obj["value"]}
        office_location_obj = self.get_office_location(potential_office_locations)
        obj["office_location"] = {"value": office_location_obj["value"]}
        return obj
