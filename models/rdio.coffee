oauth = require 'oauth'
OAuth = oauth.OAuth

api_base_url = "http://api.rdio.com/1/"
request_token_url = "http://api.rdio.com/oauth/request_token"
access_token_url = "http://api.rdio.com/oauth/access_token"


Rdio = {
  initialize: (config) ->
    if not config.consumerKey
      throw new Error "Rdio requires a consumerKey in the initializer"
    if not config.consumerSecret
      throw new Error "Rdio requires a consumerSecret in the initializer"
    if not config.callbackUrl
      throw new Error "Rdio requires a callbackUrl to be passed to the initializer"

    @consumerKey = config.consumerKey
    @consumerSecret = config.consumerSecret
    @callbackUrl = config.callbackUrl

    @oauthToken = ''
    @oauthSecret = ''

    @_oa = new OAuth(request_token_url, access_token_url, @consumerKey, @consumerSecret, "1.0", @callbackUrl, "HMAC-SHA1")

    @_oa.getOAuthRequestToken (err, token, secret, results) =>
      if err
        console.log err
        return
      @oauthToken = token
      @oauthSecret = secret


  call: (method, params, callback) ->
    post_json = params
    post_json.method = method
    @_oa.post(api_base_url, @oauthToken, @oauthSecret,
              post_json, 'application/json', callback)
}


module.exports = Rdio

