#include <string>
#if _WIN32_WCE
#include "momo/utils/contact_match.h"
#include "momo/utils/pinyin.h"

#else
#include <CoreFoundation/CoreFoundation.h>
#include "pinyin.h"
#include "contact_match.h"
typedef unsigned char byte;
#endif

#ifdef UNITTEST
int count_ = 0;
#endif

inline bool char_match(const bool fuzzy, const bool keyword_is_digit,
                       const char ch, const char keyword) {
  if (!fuzzy) {
    if (keyword_is_digit)
      return  (get_key_digit(ch) == keyword);
    else
      return  (ch == keyword);
  } else {
    if (keyword_is_digit)
      return ( (get_key_digit(ch) == keyword) || 
      (ch == 'l' && keyword == get_key_digit('n')) ||
      (ch == 'f' && keyword == get_key_digit('h')) ||
      (ch == 'r' && keyword == get_key_digit('l')) );
    else
      return ( (ch == keyword) || 
      (ch == 'l' && keyword == 'n') ||
      (ch == 'f' && keyword == 'h') ||
      (ch == 'r' && keyword == 'l') );
  }
}

int name_match(const bool fuzzy, const bool keyword_is_digit,
               const int pinyin_num, const char* pinyin_combination[],
               const char* keyword, std::string* result) {
  size_t key_pos = 0;
#ifdef UNITTEST
  count_++;
#endif
  bool match_one_on_one = true;
  bool match_not_be_cut = true;
  int score = kMatchHeavyBase;
  if (NULL != result) *result = "";

  for (int index = 0; index < pinyin_num; ++index) {
    // Each word within name
    const char* s = pinyin_combination[index];
    if (s == NULL) continue;
    bool match_head = false;
    size_t last_key_pos = key_pos;
    bool fuzzy_zhshch = false;

    // Each charactor in name
    for (unsigned int i = 0; i < strlen(s); ++i) {
      // match
      if (char_match(fuzzy, keyword_is_digit, s[i], keyword[key_pos])) {
        if (i == 0) {
          match_head = true;
        } else {
          if (!match_head) {
            int pos_b = key_pos - i;
            if (pos_b < 0) {
              // does not match from middle, try the next word
              break;
            }
            if (!memcmp(s, keyword + pos_b, i)) {
              match_head = true;
              last_key_pos -= i;
              if (NULL != result ) {
                for (int j = result->length() - 1; j >= (int) (result->length() - i) && j >= 0; --j) 
                  result->at(j) = tolower(result->at(j));
              }
            } else {
              break;
            }
          }
        }
        key_pos++;
      } else {
        // does not match, try the next word.
        if (match_head) {
          if (fuzzy && i == 1 && s[1] == 'h' && (s[0] == 'z' || s[0] == 'c' || s[0] == 's')) {
            fuzzy_zhshch = true;
            continue;
          }
          break;
        }
      }
    } // end for this word

    if (last_key_pos != key_pos) {
      size_t match_count = key_pos - last_key_pos;
      std::string word = s;
      if (fuzzy_zhshch && match_count > 1) match_count++;

      // only take initial or whole word
      if (match_count > 1 && match_count != word.length()) {
        key_pos = last_key_pos + 1;
        if (s[1] == 'h') key_pos++;
        match_count = key_pos - last_key_pos;
      }
      if (match_one_on_one && match_count > 1) match_one_on_one = false;
      if (match_count == word.length()) score += kMatchHeavyWholeSpell;
      if (index == 0) score += kMatchHeavyLastName;
      if (NULL != result ) {
        for (size_t j = 0; j < match_count; j++) 
          word[j] = toupper(word[j]);
        if (result->length() > 0) result->append(" ");
        result->append(word);
      }
    } else {
      match_one_on_one = false;
      match_not_be_cut = false;
      if (NULL != result ) {
        if (result->length() > 0) result->append(" ");
        result->append(s);
      }
    }

    // found. done. try the next name
    if (key_pos == strlen(keyword)) {
      // Add back words to result
      if (NULL != result ) {
        for (int j = index + 1; j < pinyin_num; j++) {
          if (pinyin_combination[j] == NULL) continue;
          match_one_on_one = false;
          match_not_be_cut = false;
          if (result->length() > 0) result->append(" ");
          result->append(pinyin_combination[j]);
        }
      }
      if (match_one_on_one) score += kMatchHeavyOneOnOne;
      if (match_not_be_cut) score += kMatchHeavyNotBeCut;
      return score;
    }
  } // end for pinyin_num

  if (NULL != result) result->clear();
  return 0;
}

#define MAX_NAME_LEN 8

// contact_match(曾维丞, 992), return 4, result="Zeng Wei Cheng"
int contact_match(int isFuzzy, 
				  const wchar_t* contact_name,
                  const char* pattern,
                  int isDigital,
                  std::string* result) {
  struct multi_pinyin pinyin_list[MAX_NAME_LEN];
  byte counter[MAX_NAME_LEN];
  const char* pinyin_combination[MAX_NAME_LEN];

  int name_len = wcslen(contact_name);
  if (name_len > MAX_NAME_LEN || name_len == 0 || pattern[0] == '\0')
    return 0;

  memset(counter, 0, MAX_NAME_LEN);
  memset(pinyin_list, 0, sizeof(pinyin_list));

  for (int i = 0; i < name_len; ++i) {
    get_pinyin(contact_name[i], &pinyin_list[i]);
  }

  bool all_done = false;
  while (!all_done) {
    memset(pinyin_combination, 0, sizeof(pinyin_combination));
    for (int i = 0; i < name_len; ++i) {
      pinyin_combination[i] = pinyin_list[i].pinyin[counter[i]];
    }
	  
	int score = name_match((isFuzzy != 0), (isDigital != 0), name_len, pinyin_combination, pattern, result);
    //int score = name_match(true, (isDigital != 0), name_len, pinyin_combination, pattern, result);
    //int score = name_match(true, true, name_len, pinyin_combination, pattern, result);
    if (score > 0) return score;

    // get next combination
    for (int add_index = name_len - 1; add_index >= 0; add_index--) {
      counter[add_index]++;
      if (counter[add_index] >= pinyin_list[add_index].count) {
        if (add_index == 0) {
          all_done = true;
          break;
        }
        // need to carry digit  
        counter[add_index] = 0;
        continue;
      } 
      break;
    }
  }

  return 0;
}

// This is a sqlite3 customized function, see contact_manager for usage.
void contact_match(sqlite3_context * ctx, int argc, sqlite3_value ** argv) {
  DCHECK(argc == 6);
  DCHECK(sqlite3_value_type(argv[0]) == SQLITE_TEXT);
  DCHECK(sqlite3_value_type(argv[1]) == SQLITE_INTEGER);
  DCHECK(sqlite3_value_type(argv[2]) == SQLITE_TEXT);
  DCHECK(sqlite3_value_type(argv[3]) == SQLITE_TEXT);
  DCHECK(sqlite3_value_type(argv[4]) == SQLITE_INTEGER);//isDigital
  DCHECK(sqlite3_value_type(argv[5]) == SQLITE_INTEGER);//isFuzzy

  const char* contact_name = reinterpret_cast<const char*>(sqlite3_value_text(argv[0]));
  int property = sqlite3_value_int(argv[1]);
  const char* value = reinterpret_cast<const char*>(sqlite3_value_text(argv[2]));
  const char* pattern = reinterpret_cast<const char*>(sqlite3_value_text(argv[3]));
  int isDigital = sqlite3_value_int(argv[4]);
  int isFuzzy = sqlite3_value_int(argv[5]);

  // Use MultiByteToWideChar than UTF8ToWide, to speed up convertion
  wchar_t contact_name_wide[MAX_NAME_LEN] = {0};

#if _WIN32_WCE
  int count = MultiByteToWideChar(CP_UTF8, 0, 
                                  contact_name, strlen(contact_name),
                                  contact_name_wide, MAX_NAME_LEN);

#else
    CFStringRef str = CFStringCreateWithCString(NULL, contact_name, kCFStringEncodingUTF8);
    CFIndex length = CFStringGetLength(str);
    CFRange rangeToProcess = CFRangeMake(0, length);
    
    CFStringGetBytes(str, rangeToProcess, kCFStringEncodingUTF32, 0, FALSE, (UInt8 *)contact_name_wide, sizeof(contact_name_wide), NULL);
    CFRelease(str);
#endif

  //int score = contact_match(contact_name_wide, pattern, isDigital, NULL);
	int score = contact_match(isFuzzy, contact_name_wide, pattern, isDigital, NULL);
  //LOG(INFO) << contact_name_wide;

  if (score == 0 && property == 1) 
    score = number_match(value, pattern, NULL);
  sqlite3_result_int(ctx, score);
}

// number_match(13901230876, 0876), return 1, result="1 ???????0876"
int number_match(const char* phone_number,
                 const char* pattern,
                 std::string* result) {
//  if (strlen(pattern) < 3)
//    return 0;
  const char* p = strstr(phone_number, pattern);
  if (p == NULL)
    return 0;
  int score = kMatchHeavyBase; // 匹配中加分
  if (p + strlen(pattern) == phone_number + strlen(phone_number))
    score += kMatchHeavyTailNumber; // 匹配尾部再加分
  if (NULL != result) {
    result->assign(strlen(phone_number), '?');
    result->replace(p - phone_number, strlen(pattern), pattern);
  }
  return score;
}