#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <ctype.h> // isxdigit
#include <sys/types.h>
#include <unistd.h>
#include <assert.h>

#include "oauth.h"
#include "hmac.h"

/**
 * Base64 encode one byte
 */
char oauth_b64_encode(unsigned char u) {
	if(u < 26)  return 'A'+u;
	if(u < 52)  return 'a'+(u-26);
	if(u < 62)  return '0'+(u-52);
	if(u == 62) return '+';
	return '/';
}

/**
 * Decode a single base64 character.
 */
unsigned char oauth_b64_decode(char c) {
	if(c >= 'A' && c <= 'Z') return(c - 'A');
	if(c >= 'a' && c <= 'z') return(c - 'a' + 26);
	if(c >= '0' && c <= '9') return(c - '0' + 52);
	if(c == '+')             return 62;
	return 63;
}

/**
 * Return TRUE if 'c' is a valid base64 character, otherwise FALSE
 */
int oauth_b64_is_base64(char c) {
	if((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
	   (c >= '0' && c <= '9') || (c == '+')             ||
	   (c == '/')             || (c == '=')) {
		return 1;
	}
	return 0;
}

/**
 * Base64 encode and return size data in 'src'. The caller must free the
 * returned string.
 *
 * @param size The size of the data in src
 * @param src The data to be base64 encode
 * @return encoded string otherwise NULL
 */
char *oauth_encode_base64(int size, const unsigned char *src) {
	int i;
	char *out, *p;
	
	if(!src) return NULL;
	if(!size) size= strlen((char *)src);
	out= (char*) calloc(sizeof(char), size*4/3+4);
	p= out;
	
	for(i=0; i<size; i+=3) {
		unsigned char b1=0, b2=0, b3=0, b4=0, b5=0, b6=0, b7=0;
		b1= src[i];
		if(i+1<size) b2= src[i+1];
		if(i+2<size) b3= src[i+2];
		
		b4= b1>>2;
		b5= ((b1&0x3)<<4)|(b2>>4);
		b6= ((b2&0xf)<<2)|(b3>>6);
		b7= b3&0x3f;
		
		*p++= oauth_b64_encode(b4);
		*p++= oauth_b64_encode(b5);
		
		if(i+1<size) *p++= oauth_b64_encode(b6);
		else *p++= '=';
		
		if(i+2<size) *p++= oauth_b64_encode(b7);
		else *p++= '=';
	}
	return out;
}

/**
 * Decode the base64 encoded string 'src' into the memory pointed to by
 * 'dest'. 
 *
 * @param dest Pointer to memory for holding the decoded string.
 * Must be large enough to receive the decoded string.
 * @param src A base64 encoded string.
 * @return the length of the decoded string if decode
 * succeeded otherwise 0.
 */
int oauth_decode_base64(unsigned char *dest, const char *src) {
	if(src && *src) {
		unsigned char *p= dest;
		int k, l= strlen(src)+1;
		unsigned char *buf= (unsigned char*) calloc(sizeof(unsigned char), l);
		
		/* Ignore non base64 chars as per the POSIX standard */
		for(k=0, l=0; src[k]; k++) {
			if(oauth_b64_is_base64(src[k])) {
				buf[l++]= src[k];
			}
		} 
		
		for(k=0; k<l; k+=4) {
			char c1='A', c2='A', c3='A', c4='A';
			unsigned char b1=0, b2=0, b3=0, b4=0;
			c1= buf[k];
			
			if(k+1<l) c2= buf[k+1];
			if(k+2<l) c3= buf[k+2];
			if(k+3<l) c4= buf[k+3];
			
			b1= oauth_b64_decode(c1);
			b2= oauth_b64_decode(c2);
			b3= oauth_b64_decode(c3);
			b4= oauth_b64_decode(c4);
			
			*p++=((b1<<2)|(b2>>4) );
			
			if(c3 != '=') *p++=(((b2&0xf)<<4)|(b3>>2) );
			if(c4 != '=') *p++=(((b3&0x3)<<6)|b4 );
		}
		free(buf);
		dest[p-dest]='\0';
		return(p-dest);
	}
	return 0;
}

/**
 * Escape 'string' according to RFC3986 and
 * http://oauth.net/core/1.0/#encoding_parameters.
 *
 * @param string The data to be encoded
 * @return encoded string otherwise NULL
 * The caller must free the returned string.
 */
char *oauth_url_escape(const char *string) {
	size_t alloc, newlen;
	char *ns = NULL, *testing_ptr = NULL;
	unsigned char in; 
	size_t strindex=0;
	size_t length;
	
	if (!string) return strdup("");
	
	alloc = strlen(string)+1;
	newlen = alloc;
	
	ns = (char*) malloc(alloc);
	
	length = alloc-1;
	while(length--) {
		in = *string;
		
		switch(in){
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
			case 'a': case 'b': case 'c': case 'd': case 'e':
			case 'f': case 'g': case 'h': case 'i': case 'j':
			case 'k': case 'l': case 'm': case 'n': case 'o':
			case 'p': case 'q': case 'r': case 's': case 't':
			case 'u': case 'v': case 'w': case 'x': case 'y': case 'z':
			case 'A': case 'B': case 'C': case 'D': case 'E':
			case 'F': case 'G': case 'H': case 'I': case 'J':
			case 'K': case 'L': case 'M': case 'N': case 'O':
			case 'P': case 'Q': case 'R': case 'S': case 'T':
			case 'U': case 'V': case 'W': case 'X': case 'Y': case 'Z':
			case '_': case '~': case '.': case '-':
				ns[strindex++]=in;
				break;
			default:
				newlen += 2; /* this'll become a %XX */
				if(newlen > alloc) {
					alloc *= 2;
					testing_ptr = (char*) realloc(ns, alloc);
					ns = testing_ptr;
				}
				snprintf(&ns[strindex], 4, "%%%02X", in);
				strindex+=3;
				break;
		}
		string++;
	}
	ns[strindex]=0;
	return ns;
}

/**
 * encode strings and concatenate with '&' separator.
 * The number of strings to be concatenated must be
 * given as first argument.
 * all arguments thereafter must be of type (char *) 
 *
 * @param len the number of arguments to follow this parameter
 * @param ... string to escape and added (may be NULL)
 *
 * @return pointer to memory holding the concatenated 
 * strings - needs to be free(d) by the caller. or NULL
 * in case we ran out of memory.
 */
char *oauth_catenc(int len, ...) {
	va_list va;
	int i;
	char *rv = (char*) malloc(sizeof(char));
	*rv='\0';
	va_start(va, len);
	for(i=0;i<len;i++) {
		char *arg = va_arg(va, char *);
		char *enc;
		int len;
		enc = oauth_url_escape(arg);
		if(!enc) break;
		len = strlen(enc) + 1 + ((i>0)?1:0);
		if(rv) len+=strlen(rv);
		rv=(char*) realloc(rv,len*sizeof(char));
		
		if(i>0) strcat(rv, "&");
		strcat(rv, enc);
		free(enc);
	}
	va_end(va);
	return(rv);
}



char *oauth_sign_hmac_sha1 (const char *m, const char *k) {
	HMAC_CTX ctx;
	HMAC_SHA_init(&ctx, k, strlen(k));
	HMAC_update(&ctx, m, strlen(m));
	return oauth_encode_base64(HMAC_size(&ctx), HMAC_final(&ctx));
}

int split_url_param(const char** next1 , const char** key1 , const char** qe1 , const char** split1 ,const char endflag )
{
	const char* next = *next1;
	const char* key = *key1;
	const char* split = *split1;
	const char* qe = *qe1;
	
	if( !next || *next == '\0' )
		return -1;
	
	key = next; 
	// 前面的空格除掉
	do
	{
		if( *key != 0x20 || *key == '\0' ) break;
		key++;
	}while(1);
	
	qe = strchr(key , '=' );
	if( !qe ) {
		*next1 = next;
		*key1 = key;
		*split1 = split;
		*qe1 = qe;
		return -1;
	}
	split = strchr( (qe+1) , endflag);
	
	if(split) next = (split + 1 );
	else next = 0;
	
	*next1 = next;
	*key1 = key;
	*split1 = split;
	*qe1 = qe;
	return 0;
}

int split_url_copy_keyval(char* val , const char* start , const char* end)
{
	if( !val || !start || *start == '\0' )
		return -1;
	
	if( end && end <= start )
		return -1;
	
	if( !end || *end == '\0' )
	{
		strcpy(val , start );
	}
	else
	{
		strncpy(val , start , end - start );		
		val[end - start] = 0;
	}
	return 0;
}

/**
 * split and parse URL parameters replied by the test-server
 * into <em>oauth_token</em> and <em>oauth_token_secret</em>.
 */
int wb_parse_oauth(const char *reply,
                   char *token,
                   char *secret,char* userid )
{
	int tokenok = 0 ,secretok = 0; 
	const char* key = 0;
	const char* qe  = 0;
	const char* split = 0;
	const char* s = reply;
	// 第一个参数
	while( 0 == split_url_param(&s , &key , &qe , &split ,'&') )
	{
		if( strncasecmp(key,"oauth_token_secret=",18 ) == 0 )
		{
			if (secret) { split_url_copy_keyval(secret ,(qe+1) , split); secretok=1; }
		}
		else if( strncasecmp(key,"oauth_token=",11 ) == 0 )
		{
			if (token) { split_url_copy_keyval(token , (qe+1) , split ) ; tokenok = 1; }
		}
		else if( strncasecmp(key,"user_id=",7 ) == 0 )
		{
			if (userid) { split_url_copy_keyval(userid , (qe+1) , split ) ; }
		}
	}

	return (tokenok || secretok);
}

int parse_oauth(const char *reply, char *token, char *secret) {
	return wb_parse_oauth(reply, token, secret, 0);
}


/**
 * string compare function for oauth parameters.
 *
 * used with qsort. needed to normalize request parameters.
 * see http://oauth.net/core/1.0/#anchor14
 */
int oauth_cmpstringp(const void *p1, const void *p2) {
	char *v1,*v2;
	int rv;

	v1=oauth_url_escape(* (char * const *)p1);
	v2=oauth_url_escape(* (char * const *)p2);
	
	rv = strcmp(v1, v2);
	free(v1);
	free(v2);
	return rv;
}



/* pre liboauth-0.7.2 and possible future versions that don't use OpenSSL or NSS */
char *oauth_gen_nonce() {
	char *nc;
	static int rndinit = 1;
	const char *chars = "abcdefghijklmnopqrstuvwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ" "0123456789_";
	unsigned int max = strlen( chars );
	int i, len;
	
	if(rndinit) {srand(time(NULL) 
					   * getpid()
					   ); rndinit=0;} // seed random number generator - FIXME: we can do better ;)
	
	len=15+floor(rand()*16.0/(double)RAND_MAX);
	nc = (char*) malloc((len+1)*sizeof(char));
	for(i=0;i<len; i++) {
		nc[i] = chars[ rand() % max ];
	}
	nc[i]='\0';
	return (nc);
}

char* oauth_sprintf(const char *format, ...) {
	char *buf = malloc(512);
	int size = 512;
	va_list ap;
	va_start(ap, format);
	va_list ap_copy;
	va_copy(ap_copy, ap);
	int result = vsnprintf(buf, size, format, ap_copy);
	va_end(ap_copy);
	if (result > 0 && result < size) 
		return buf;
	
	size = result + 1;
	free(buf);
	buf = realloc(buf, size);
	va_copy(ap_copy, ap);
	vsnprintf(buf, size, format, ap_copy);
	va_end(ap_copy);
	va_end(ap);
	return buf;
}

const char* oauth_consumer_key = "dbda88d1d417f605980fa784b6aad41004ddb4c35";
const char* oauth_consumer_secret = "ace0770a1bd908ca62e8422f436e34f1";

const char* oauth_version = "1.0";
const char* oauth_signature_method = "HMAC-SHA1";

#define MAX_PARAMS 20
char* generate_authorization_params(const char* http_method, const char* url1, 
									long long timestamp, const char* verifier, OAuthToken* oauth_token) {
   	char* nonce = oauth_gen_nonce();
	char* url = strdup(url1);
	char* params[MAX_PARAMS] = {0};
    
	int index = 0;
	params[index++] = oauth_sprintf("oauth_consumer_key=%s", oauth_consumer_key);
	params[index++] = oauth_sprintf("oauth_nonce=%s", nonce);
	params[index++] = oauth_sprintf("oauth_signature_method=%s", oauth_signature_method);
	params[index++] = oauth_sprintf("oauth_timestamp=%lld", timestamp);
	if (oauth_token) {
		params[index++] = oauth_sprintf("oauth_token=%s", oauth_token->token);
	}
	if (verifier) {
		params[index++] = oauth_sprintf("oauth_verifier=%s", verifier);
	}
	params[index++] = oauth_sprintf("oauth_version=%s", oauth_version);
	char* url_params = strstr(url, "?");
    char cc = '?';
	if (url_params) {
        cc = '&';
		*url_params++ = 0;
		
		char* token = strtok(url_params, "&");
		while (token) {
			if (index >= MAX_PARAMS) break;
			params[index++] = oauth_sprintf("%s", token);
			url_params = 0;
            token = strtok(NULL, "&");
		}
		assert(0 == token);
	}
	qsort(params, index, sizeof(params[0]), oauth_cmpstringp);
	char buff[2048] = {0};
	for (int i = 0; i < index - 1; i++) {
		sprintf(buff + strlen(buff), "%s&", params[i]);
	}
	sprintf(buff + strlen(buff), "%s", params[index - 1]);
	
	char buff2[1204*3];
	
	char* eurl = oauth_url_escape(url);
	char* ebuff = oauth_url_escape(buff);
	sprintf(buff2, "%s&%s&%s", http_method, eurl, ebuff);
	free(eurl);
	free(ebuff);
	char* okey;
	if (oauth_token) 
		okey = oauth_catenc(2, oauth_consumer_secret, oauth_token->secret);
	else
		okey = oauth_catenc(2, oauth_consumer_secret, "");
	
	char* sign = oauth_sign_hmac_sha1(buff2, okey);
	free(okey);
	char* esign = oauth_url_escape(sign);
	free(sign);
	
	char* enonce = oauth_url_escape(nonce);
	char* authorization_header = malloc(2048);
    sprintf(authorization_header, 
            "%coauth_consumer_key=%s&oauth_signature_method=%s&oauth_signature=%s&oauth_timestamp=%lld&oauth_nonce=%s&", 
             cc, oauth_consumer_key, oauth_signature_method, esign, timestamp, enonce);
	free(esign);
	
	if (oauth_token) {
		sprintf(authorization_header + strlen(authorization_header), "oauth_token=%s&", oauth_token->token);
	}
	if (verifier) {
		sprintf(authorization_header + strlen(authorization_header), "oauth_verifier=%s&", verifier);
	}
	sprintf(authorization_header + strlen(authorization_header), "oauth_version=%s", oauth_version);
	free(enonce);
	free(nonce);
	free(url);
	for (int i = 0; i < MAX_PARAMS; i++) {
		free(params[i]);
	}
	return authorization_header; 
}
char* generate_authorization_header(const char* http_method, const char* url1, 
									long long timestamp, const char* verifier, OAuthToken* oauth_token) {
	char* nonce = oauth_gen_nonce();
	char* url = strdup(url1);
	char* params[MAX_PARAMS] = {0};

	int index = 0;
	params[index++] = oauth_sprintf("oauth_consumer_key=%s", oauth_consumer_key);
	params[index++] = oauth_sprintf("oauth_nonce=%s", nonce);
	params[index++] = oauth_sprintf("oauth_signature_method=%s", oauth_signature_method);
	params[index++] = oauth_sprintf("oauth_timestamp=%lld", timestamp);
	if (oauth_token) {
		params[index++] = oauth_sprintf("oauth_token=%s", oauth_token->token);
	}
	if (verifier) {
		params[index++] = oauth_sprintf("oauth_verifier=%s", verifier);
	}
	params[index++] = oauth_sprintf("oauth_version=%s", oauth_version);
	char* url_params = strstr(url, "?");
	if (url_params) {
		*url_params++ = 0;
		
		char* token = strtok(url_params, "&");
		while (token) {
			if (index >= MAX_PARAMS) break;
			params[index++] = oauth_sprintf("%s", token);
			url_params = 0;
            token = strtok(NULL, "&");
		}
		assert(0 == token);
	}
	qsort(params, index, sizeof(params[0]), oauth_cmpstringp);
	char buff[2048] = {0};
	for (int i = 0; i < index - 1; i++) {
		sprintf(buff + strlen(buff), "%s&", params[i]);
	}
	sprintf(buff + strlen(buff), "%s", params[index - 1]);
	
	char buff2[1204*3];
	
	char* eurl = oauth_url_escape(url);
	char* ebuff = oauth_url_escape(buff);
	sprintf(buff2, "%s&%s&%s", http_method, eurl, ebuff);
	free(eurl);
	free(ebuff);
//	NSLog(@"%s", buff2);
	char* okey;
	if (oauth_token) 
		okey = oauth_catenc(2, oauth_consumer_secret, oauth_token->secret);
	else
		okey = oauth_catenc(2, oauth_consumer_secret, "");
	
	char* sign = oauth_sign_hmac_sha1(buff2, okey);
	free(okey);
	char* esign = oauth_url_escape(sign);
	free(sign);
	
	char* enonce = oauth_url_escape(nonce);
	char* authorization_header = malloc(2048);
	sprintf(authorization_header, 
			"OAuth realm=\"\", oauth_consumer_key=\"%s\", oauth_signature_method=\"%s\", oauth_signature=\"%s\", oauth_timestamp=\"%lld\", oauth_nonce=\"%s\", ", 
			oauth_consumer_key, oauth_signature_method, esign, timestamp, enonce);
	free(esign);
	
	if (oauth_token) {
		sprintf(authorization_header + strlen(authorization_header), "oauth_token=\"%s\", ", oauth_token->token);
	}
	if (verifier) {
		sprintf(authorization_header + strlen(authorization_header), "oauth_verifier=\"%s\", ", verifier);
	}
	sprintf(authorization_header + strlen(authorization_header), "oauth_version=\"%s\"", oauth_version);
	free(enonce);
	free(nonce);
	free(url);
	for (int i = 0; i < MAX_PARAMS; i++) {
		free(params[i]);
	}
	return authorization_header;
}





