import assemblyai as aai
import json
import os
import sys

# aai.settings.api_key = "b3260dded65446e6ad2edfb22e41d515"
# month = "September"
# ext = "MP4"

aai.settings.api_key = sys.argv[1]
month = sys.argv[2]
audioPath = sys.argv[3]

rootPath = fr"/Users/ryan/Library/Containers/com.xavware.BoardMeetingAssistant/Data/Documents/{month}"

try:
    os.makedirs(rootPath)
    # print(f"Created directory at {rootPath}")
except FileExistsError:
    # print("Directory already exists")
    pass

boostedWords = [
    # Board Members
    "Victoria Germano", "Stu Conklin", "Steve Giles", "Bob Pagano", "Pete Realmonte", "John Hadley", "Doug Vance", "John Stanley", "Bruce Young", "Anand Dash", "Sabine Watson", "Amanda Beelitz", "Justin Williams",

    #LMCC Members
    "Greg Yuskaitis", "Lynn Scott", "Steve Chase", "Debbie Hookway", "Randall Curry", "Kathy Romine", "Dean Reinauer",


    "Brian Metsinger", "Noel Turner", "Ryan Matts", "Jeff Jordan", "Shannon Mahoney", "Dave Schreck", "Elvis Jean", "Mark Scott", "Scott Heckenberer", "Lisa Heckenberer", "Greg Yuskaitis", "Debra Halick", "Cyd Linquito"
    # Keywords
    "LMCC", "Lake Mohawk Country Club", "Lake Mohawk"
    # "The Boardwalk Club", "BWC", "Hopatcong", "Sparta", "East Shore Trail", "North Shore Trail", 
    # "Log Cabin Terrace", "Springbrook Trail", "Manitou", "Manitou Bridge", "Manitou Island", "Papoose"
    ]

# print("Configuring transcriber...")
transcriber = aai.Transcriber()
config = aai.TranscriptionConfig(
    word_boost = boostedWords,
    speaker_labels=True, 
    
    speakers_expected = 10)

# p = "https://assembly.ai/wildfires.mp3"
# transcript = transcriber.transcribe(p, config)

# print("Transcribing file. This may take a few minutes...")
transcript = transcriber.transcribe(audioPath, config)




# j = transcript.json_response
# print(j)

## Step 2
with open(os.path.join(rootPath,'original.json'), "w") as file1:
    json.dump(transcript.json_response, file1, indent=4)

# print("Original JSON file created")
# print("Formatting updated JSON file...")
# t = transcript.json_response
# t['text'] = ""
# t['words'] = []
# t['sections'] = [{
#     'text': '',
#     'start': 0
# }]

# i = 0
# while i < len(t['utterances']):
#     t['utterances'][i]['words'] = []
#     t['utterances'][i]['speakerName'] = ''
#     i += 1

# with open(os.path.join(rootPath,'updatedData.json'), "w") as file1:
#     json.dump(t, file1, indent=4)

# print(json.dumps(j))