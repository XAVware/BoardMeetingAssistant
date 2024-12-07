//
//  Transcript.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 9/8/24.
//

import Foundation

struct AAITranscript: Codable {
//    let language_code: String?
    var audio_url: String?
//    let punctuate: Bool?
//    let format_text: Bool?
//    let dual_channel: Bool?
//    let webhook_url: MagicValue?
//    let webhook_auth_header_name: MagicValue?
//    let webhook_auth_header_value: MagicValue?
//    let audio_start_from: MagicValue?
//    let audio_end_at: MagicValue?
//    let word_boost: MagicValue?
//    let boost_param: MagicValue?
//    let filter_profanity: Bool?
//    let redact_pii: Bool?
//    let redact_pii_audio: Bool?
//    let redact_pii_audio_quality: MagicValue?
//    let redact_pii_policies: MagicValue?
//    let redact_pii_sub: MagicValue?
//    let speaker_labels: Bool?
//    let speakers_expected: Int?
//    let content_safety: Bool?
//    let content_safety_confidence: MagicValue?
//    let iab_categories: Bool?
//    let custom_spelling: MagicValue?
//    let disfluencies: Bool?
//    let sentiment_analysis: Bool?
//    let auto_chapters: Bool?
//    let entity_detection: Bool?
//    let summarization: Bool?
//    let summary_model: MagicValue?
//    let summary_type: MagicValue?
//    let auto_highlights: Bool?
//    let language_detection: Bool?
//    let language_confidence_threshold: MagicValue?
//    let language_confidence: MagicValue?
//    let speech_threshold: MagicValue?
//    let speech_model: MagicValue?
//    let id: MagicValue?
//    let status: MagicValue?
//    let error: MagicValue?
//    let text: MagicValue?
//    let words: [MagicValue]?

    var utterances: [AAIUtterance]
    
//    let confidence: MagicValue?
//    let audio_duration: MagicValue?
//    let webhook_status_code: MagicValue?
//    let webhook_auth: Bool?
//    let summary: MagicValue?
//    let auto_highlights_result: MagicValue?
//    let content_safety_labels: MagicValue?
//    let iab_categories_result: MagicValue?
//    let chapters: MagicValue?
//    let sentiment_analysis_results: MagicValue?
//    let entities: MagicValue?
}
