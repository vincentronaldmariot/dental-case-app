class LanguageService {
  static const String english = 'en';
  static const String tagalog = 'tl';

  static String currentLanguage = english;

  static void setLanguage(String language) {
    currentLanguage = language;
  }

  static String getCurrentLanguage() {
    return currentLanguage;
  }

  static String getText(String key) {
    switch (currentLanguage) {
      case tagalog:
        return _tagalogTexts[key] ?? _englishTexts[key] ?? key;
      case english:
      default:
        return _englishTexts[key] ?? key;
    }
  }

  static final Map<String, String> _englishTexts = {
    'self_assessment_title': 'Self-Assessment Dental Survey',
    'question_1': '1. Do you have any of the ones shown in the pictures?',
    'question_2':
        '2. Do you have tartar/calculus deposits or rough feeling teeth like in the images?',
    'question_3':
        '3. Do your teeth feel sensitive to hot, cold, or sweet foods?',
    'question_4': '4. Do you experience tooth pain?',
    'question_5':
        '5. Do you have damaged or broken fillings like those shown in the pictures?',
    'question_6': '6. Do you need to get dentures (false teeth)?',
    'question_7': '7. Do you have missing or extracted teeth?',
    'question_8':
        '8. When was your last dental visit at a Dental Treatment Facility?',
    'write_answer_here': 'Write your answer here',
    'submit_survey': 'SUBMIT SURVEY',
    'language_toggle_english': 'EN',
    'language_toggle_tagalog': 'TL',
    'language_tooltip': 'Toggle Language',
  };

  static final Map<String, String> _tagalogTexts = {
    'self_assessment_title': 'Sariling-Pagsusuri ng Dental',
    'question_1':
        '1. Mayroon ka bang alinman sa mga ipinapakita sa mga larawan?',
    'question_2':
        '2. Mayroon ka bang tartar/calculus deposits o magaspang na pakiramdam ng ngipin tulad sa mga larawan?',
    'question_3':
        '3. Ang iyong mga ngipin ba ay sensitibo sa mainit, malamig, o matamis na pagkain?',
    'question_4': '4. Nakakaranas ka ba ng sakit ng ngipin?',
    'question_5':
        '5. Mayroon ka bang sira o basag na mga filling tulad ng mga ipinapakita sa mga larawan?',
    'question_6': '6. Kailangan mo bang kumuha ng pustiso (peke na ngipin)?',
    'question_7': '7. Mayroon ka bang nawawala o na-extract na ngipin?',
    'question_8':
        '8. Kailan ang huling pagbisita mo sa isang Dental Treatment Facility?',
    'write_answer_here': 'Isulat ang iyong sagot dito',
    'submit_survey': 'IPASA ANG SURVEY',
    'language_toggle_english': 'EN',
    'language_toggle_tagalog': 'TL',
    'language_tooltip': 'Palitan ang Wika',
  };
}
