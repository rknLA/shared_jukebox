oauth = require 'oauth'
OAuth = oauth.OAuth

api_base_url = "http://api.rdio.com/1/"
request_token_url = "http://api.rdio.com/oauth/request_token"
access_token_url = "http://api.rdio.com/oauth/access_token"

Rdio = (config) ->
  if not config.consumerKey
    throw new Error "Rdio requires a consumerKey in the initializer"
  if not config.consumerSecret
    throw new Error "Rdio requires a consumerSecret in the initializer"
  if not config.callbackUrl
    throw new Error "Rdio requires a callbackUrl to be passed to the initializer"

  @consumerKey = config.consumerKey
  @consumerSecret = config.consumerSecret
  @callbackUrl = config.callbackUrl


  @call = (method, params, callback) ->
    console.log this
    oa = new OAuth(request_token_url, access_token_url, @consumerKey, @consumerSecret, "1.0", @callbackUrl, "HMAC-SHA1")
    oa.getOAuthRequestToken (err, token, secret, results) =>
      if err
        console.log err
        callback err
        return
      console.log token
      console.log secret
      post_json = params
      post_json.method = method
      oa.post(api_base_url, '', '',
              post_json, 'application/json', callback)

  return this

module.exports = Rdio

