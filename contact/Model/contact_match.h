#ifndef MOMO_UTILS_CONTACT_MATCH_H_
#define MOMO_UTILS_CONTACT_MATCH_H_

#include <vector>
#include <string>

#if _WIN32_WCE
#include "third_party/sqlite/sqlite3.h"
#else
#include "sqlite3.h"
#endif

const int kMatchHeavyBase            = 2;             // ��ͨƥ��
const int kMatchHeavyTailNumber      = 8;             // ����β��ƥ��
const int kMatchHeavyOneOnOne        = 12;            // ÿ��һ��ƴ������ĸ
const int kMatchHeavyNotBeCut        = 3;             // �м�û�ж�
const int kMatchHeavyWholeSpell      = 3;             // һ���ֵ�ȫ��ƴ��
const int kMatchHeavyLastName        = 2;             // ƥ�䵽�ն���ӷ�

int name_match(const bool fuzzy, const bool keyword_is_digit, 
               const int pinyin_num, const char* pinyin_combination[],
               const char* keyword, std::string* result);

int contact_match(int isFuzzy, 
				  const wchar_t* contact_name,
                  const char* pattern,
                  int isDigital,
                  std::string* result);

int number_match(const char* phone_number,
                 const char* pattern,
                 std::string* result);

void contact_match(sqlite3_context * ctx, int argc, sqlite3_value ** argv);

#endif // MOMO_UTILS_CONTACT_MATCH_H_