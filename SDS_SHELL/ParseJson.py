import json

# /Users/yujiang/Downloads/results.json
# {
# "employees": [
#         { "firstName":"John" , "lastName":"Doe" },
#         { "firstName":"Anna" , "lastName":"Smith" },
#         { "firstName":"Peter" , "lastName":"Jones" }
#         ]
# }

# /Users/yujiang/Downloads/results.txt
# Doe John
# Smith Anna
# Jones Peter

READ_FILE_PATH = "/Users/yujiang/Downloads/results.json"
WRITE_FILE_PATH = "/Users/yujiang/Downloads/results.txt"

def read_json_file():
    with open(READ_FILE_PATH, "r") as f:
        new_dict = json.load(f)
    return new_dict

def write_file(write_content_list):
    with open(WRITE_FILE_PATH, "w+") as f:
        for content in write_content_list:
            f.write("%s \n" % content)

if __name__ == '__main__':
    result_dict = read_json_file()

    print result_dict['employees']

    result_list = []
    for item in result_dict['employees']:
        result_format = "{} {}".format(item['lastName'], item['firstName'])
        result_list.append(result_format)

    print result_list

    write_file(result_list)