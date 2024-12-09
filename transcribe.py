import assemblyai as aai
import json
import os
import sys

SECTION_GROUPS = { 
    'PROCEDURAL': {
        'sections': ['ATTENDANCE', 'AGENDA', 'MINUTES'],
        'markers': ['call to order', 'adoption of the agenda', 'approval of minutes', 'start with attendance'],
        'speakers_expected': 10
    },
    'REPORTS': {
        'sections': ['MANAGER', 'FINANCIAL', 'ENGINEERING'],
        'markers': ['manager\'s report', 'financial report', 'engineering report', 'treasurer\'s report'],
        'speakers_expected': 10
    },
    'BUSINESS': {
        'sections': ['OLD_BUSINESS', 'NEW_BUSINESS', 'OTHER_BUSINESS'],
        'markers': ['old business', 'new business', 'other business'],
        'speakers_expected': 10
    }
}

def identify_sections(audio_path, api_key, boosted_words):
    aai.settings.api_key = api_key
    transcriber = aai.Transcriber()
    
    base_config = aai.TranscriptionConfig(
        word_boost=boosted_words,
        speaker_labels=True,
        speakers_expected=10,
        auto_chapters=True
    )
    
    transcript = transcriber.transcribe(audio_path, config=base_config)
    
    response = {
        'audio_url': audio_path,
        'utterances': [
            {
                'text': u.text,
                'start': u.start,
                'end': u.end,
                'confidence': u.confidence,
                'speaker': u.speaker,
                'speakerName': None
            }
            for u in transcript.utterances
        ],
        'sections': {}
    }
    
    # Identify sections by start time only
    for utterance in transcript.utterances:
        text = utterance.text.lower()
        for group_name, group_info in SECTION_GROUPS.items():
            if any(marker.lower() in text for marker in group_info['markers']):
                response['sections'][group_name] = {
                    'start': utterance.start,
                    'name': group_name
                }
    
    return response

def transcribe_section(audio_path, api_key, boosted_words, section_name, start_time, end_time):
    aai.settings.api_key = api_key
    transcriber = aai.Transcriber()
    
    section_config = aai.TranscriptionConfig(
        word_boost=boosted_words,
        speaker_labels=True,
        speakers_expected=SECTION_GROUPS[section_name]['speakers_expected'],
        audio_start_from=start_time,
        audio_end_at=end_time
    )
    
    transcript = transcriber.transcribe(audio_path, config=section_config)
    return transcript.json_response

if __name__ == "__main__":
    command = sys.argv[1]
    api_key = sys.argv[2]
    audio_path = sys.argv[3]
    boosted_words = sys.argv[4].split(",")
    if command == "identify":
        result = identify_sections(audio_path, api_key, boosted_words)
        sys.stdout.write(json.dumps(result, indent=3))

    elif command == "transcribe":
        section_name = sys.argv[5]
        start_time = int(sys.argv[6])
        end_time = int(sys.argv[7])
        result = transcribe_section(audio_path, api_key, boosted_words, section_name, start_time, end_time)
        print(json.dumps(result))
