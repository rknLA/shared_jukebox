describe 'Tracks Endpoint (submission)', ->
  user = null
  track = null

  before (done) ->
    User.register
      ip: '127.0.0.1'
      (u) ->
        user = u
        done()

  after (done) ->
    User.remove done

  describe 'when none exist', ->
    restData = null
    restResponse = null

    before (done) ->
      trackData = Fixtures.track.breeders
      rest.postJson("http://localhost:#{app.settings.port}/tracks", {
        user_id: user.id
        track_metadata: trackData 
      }, {
        headers:
          'Accept': 'application/json'
      }).on 'complete', (data, response) ->
        restData = data
        restResponse = response
        done()

    after (done) ->
      Track.remove done

    it 'should respond with created', ->
      restResponse.should.not.equal undefined
      restResponse.statusCode.should.equal 201

    it 'should have the right user_id', ->
      restData.user_id.should.equal user.id

    it 'should have the right track metadata', ->
      restData.track_metadata.track_id.should.equal 't1749260'

    it 'should have the right vote count', ->
      restData.vote_count.should.equal 1
      restData.votes.indexOf(user.id).should.not.equal -1

  describe 'when some are in the queue', ->
    existingTrack = null

    before (done) ->
      Track.submit
        user_id: user._id
        track_metadata: Fixtures.track.breeders
        (t) ->
          existingTrack = t
          done()

    after (done) ->
      existingTrack.remove done

    describe 'a new track', ->
      restData = null
      restResponse = null

      before (done) ->
        rest.postJson("http://localhost:#{app.settings.port}/tracks", {
          user_id: user.id
          track_metadata: Fixtures.track.backwards
        }, {
          headers:
            'Accept': 'application/json'
        }).on 'complete', (data, response) ->
          restData = data
          restResponse = response
          done()
      
      it 'should get created like normal', ->
        restResponse.statusCode.should.equal 201

      it 'should set the right user id', ->
        restData.user_id.should.equal user.id
      it 'should have the right track metadata', ->
        restData.track_metadata.track_id.should.equal 't20901321'
      it 'should have the right vote count', ->
        restData.vote_count.should.equal 1
        restData.votes.indexOf(user.id).should.not.equal -1

    describe 'a duplicate track', ->
      duplicateRestData = null
      duplicateRestResponse = null

      before (done) ->
        rest.postJson("http://localhost:#{app.settings.port}/tracks", {
          user_id: user.id
          track_metadata: Fixtures.track.breeders
        }, {
          headers:
            'Accept': 'application/json'
        }).on 'complete', (data, response) ->
          duplicateRestData = data
          duplicateRestResponse = response
          done()

      it 'should not get created', ->
        duplicateRestResponse.should.not.equal undefined
        duplicateRestResponse.statusCode.should.equal 409 # conflict
        #right now test fails here

      it 'should return the existing track', ->
        duplicateRestData.should.not.equal undefined
        duplicateRestData._id.should.equal existingTrack.id
        duplicateRestData.user_id.should.equal user.id
        duplicateRestData.track_metadata.track_id.should.equal 't1749260'
        duplicateRestData.vote_count.should.equal 1
        duplicateRestData.votes.indexOf(123).should.equal -1

