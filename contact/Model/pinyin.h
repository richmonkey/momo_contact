#ifndef PINYIN_H_
#define PINYIN_H_

#include <string>
#include <vector>

#if _WIN32_WCE
#include "base/logging.h"

#else
#define DCHECK(x) (void)0
#endif


#define MAX_PINYIN_NUM 10  // Chinese charactor only has less then 5 spelling
#define MAX_PINYIN_LEN 8  // Max length of spelling

struct multi_pinyin {
  int count;
  const char* pinyin[MAX_PINYIN_NUM];
};

// Get phonetic string for chinese string
std::string get_pinyin(const std::wstring& hanzhi);

// Get phonetic abbreviations string for chinese string
std::string get_pinyin_abbr(const std::wstring& hanzhi);

// Get the key pad number related to the name phonetic
inline char get_key_digit(const char pinyin) {
  DCHECK(pinyin >= 'a' && pinyin <= 'z');
  if (pinyin >= '0' && pinyin <= '9') return pinyin;
  static char key_digit_map[] = {
    '2', '2', '2',        //ABC
    '3', '3', '3',        //DEF
    '4', '4', '4',        //GHI
    '5', '5', '5',        //JKL
    '6', '6', '6',        //MNO
    '7', '7', '7', '7',   //PQRS
    '8', '8', '8',        //TUV
    '9', '9', '9', '9',   //WXYZ
  };

  return key_digit_map[pinyin - 'a'];
}

std::string get_key_digit(const std::string& pinyin);

// Get phonetic string for chinese character
void get_pinyin(const wchar_t hanzhi, char* pinyin, int count);

void get_pinyin(const wchar_t hanzhi, struct multi_pinyin* pinyin);

#endif // PINYIN_H_
