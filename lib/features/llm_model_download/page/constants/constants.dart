// download_page/config/constants.dart

// OAuth Configuration for HuggingFace
const String hfClientId = 'd1049160-528c-48ea-88a4-5823a69e7e78';
const String hfRedirectUri = 'com.example.rememberme://oauthredirect';
const String authEndpoint = 'https://huggingface.co/oauth/authorize';
const String tokenEndpoint = 'https://huggingface.co/oauth/token';
const String scope = 'openid profile read-repos';

// Model Download Configuration
const String modelName = 'gemma-4-E2B-it.litertlm';
const String modelFullName = 'Gemma 4 E2B IT Litert LM';
const String downloadUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/$modelName?download=true';
const String modelCardUrl =
    'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm';
// SharedPreferences Keys
const String downloadStateKey = 'download_state';
const String downloadTaskIdKey = 'download_task_id';
const String authTokenKey = 'auth_token';
const String codeVerifierKey = 'code_verifier';
