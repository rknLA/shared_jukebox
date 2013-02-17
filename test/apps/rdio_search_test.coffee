querystring = require 'querystring'

describe "Rdio Search Endpoint", ->
  user = null

  before (done) ->
    User.register
      ip: '127.0.0.1'
      (u) ->
        user = u
        done()

  describe 'new complete searches', ->
    # oh good, a test that relies on a web service.
    searchResults = null
    searchResponse = null

    before (done) ->
      data =
        type: 'music'
        q: 'power'
        user_id: user.id
      dataStr = querystring.stringify data
      rest.get("http://localhost:#{app.settings.port}/search/tracks?#{dataStr}",
        headers:
          'Accept': 'application/json'
      ).on 'complete', (data, response) ->
        searchResults = data
        searchResponse = response
        done()

    it 'should respond with created', ->
      searchResponse.statusCode.should.equal 201

    it 'should have a search id', ->
      assert.notEqual searchResults._id, null

    it 'should have an array of track metadata', ->
      searchResults.results.length.should.equal 20

    describe 'Each Track', ->

      it 'should have a submission_id', ->
        assert ('submission_id' of searchResults.results[0]), "searched tracks should have submission_id fields, even if they're null"

      it 'should have a vote count', ->
        assert ('vote_count' of searchResults.results[0]), "searched tracks should have a vote_count, even if it's 0"

      it 'should have a vote list', ->
        assert ('votes' of searchResults.results[0]), "searched tracks should have a vote array, even if it's empty"
