#ifndef _OAUTH_H
#define _OAUTH_H      1 

#ifndef DOXYGEN_IGNORE
// liboauth version
#define LIBOAUTH_VERSION "0.8.7"
#define LIBOAUTH_VERSION_MAJOR  0
#define LIBOAUTH_VERSION_MINOR  8
#define LIBOAUTH_VERSION_MICRO  7

//interface revision number
//http://www.gnu.org/software/libtool/manual/html_node/Updating-version-info.html
#define LIBOAUTH_CUR  6
#define LIBOAUTH_REV  0
#define LIBOAUTH_AGE  6
#endif


#ifdef __cplusplus
extern "C" {
#endif
	const char* oauth_consumer_key;
	const char* oauth_consumer_secret;
	
	typedef struct {
		char token[1024];
		char secret[1024];
	}OAuthToken;
	
	int parse_oauth(const char *reply, char *token, char *secret);
	//free the output
	char *oauth_sign_hmac_sha1 (const char *m, const char *k);
	
	//free the output
	char *oauth_url_escape(const char *string);
	
	//timestamp = time()*1000
	//free the output
	char* generate_authorization_header(const char* http_method, const char* url, 
										long long timestamp, const char* verify, OAuthToken* oauth_token);
    
    char* generate_authorization_params(const char* http_method, const char* url1, 
                                        long long timestamp, const char* verifier, OAuthToken* oauth_token);
	
#ifdef __cplusplus
}
#endif

#endif

