async = require 'async'

describe 'The Queue', ->

  user1 = null
  user2 = null
  user3 = null

  track1 = null
  track2 = null
  track3 = null
  playedTrack = null

  before (done) ->
    async.series [
      (callback) ->
        User.register
          ip: '127.0.0.1'
          (u) ->
            user1 = u
            callback()
    ,
      (callback) ->
        User.register
          ip: '127.0.0.2'
          (u) ->
            user2 = u
            callback()
    ,
      (callback) ->
        User.register
          ip: '127.0.0.3'
          (u) ->
            user3 = u
            callback()
    ,
      (callback) ->
        Track.submit
          user_id: user1._id
          track_metadata: Fixtures.track.tortoise
          (t) ->
            track1 = t
            callback()
    ,
      (callback) ->
        Track.submit
          user_id: user1._id
          track_metadata: Fixtures.track.monkey
          (t) ->
            track2 = t
            callback()
    ,
      (callback) ->
        Track.submit
          user_id: user1._id
          track_metadata: Fixtures.track.impala
          (t) ->
            track3 = t
            callback()
    ],
    (err, callback) ->
      track1.vote user2._id
      track1.save (err, tr) ->
        track1 = tr
        track2.vote user2._id
        track2.vote user3._id
        track2.save (err, tr) ->
          track2 = tr
          done()

  describe 'getting all unplayed tracks', ->
    queueResults = null
    queueResponse = null

    before (done) ->
      rest.get("http://localhost:#{app.settings.port}/tracks?user_id=#{user3._id}",
        headers:
          'Accept': 'application/json'
      ).on 'complete', (data, response) ->
        queueResults = data
        queueResponse = response
        done()

    it 'should respond with OK', ->
      queueResponse.statusCode.should.equal 200

    it 'should contain the total number of unplayed tracks in the queue', ->
      assert 'total_track_count' of queueResults
      queueResults.total_track_count.should.equal 3

    it 'should contain the number of unplayed tracks in this response', ->
      assert 'track_count' of queueResults
      queueResults.track_count.should.equal 3

    it 'should contain the queue starting index', ->
      assert 'offset' of queueResults
      queueResults.offset.should.equal 0

    it 'should contain submitted tracks in order of rank', ->
      assert 'tracks' of queueResults
      queueResults.tracks[0].track_metadata.track_id.should.equal Fixtures.track.monkey.track_id
      queueResults.tracks[1].track_metadata.track_id.should.equal Fixtures.track.tortoise.track_id
      queueResults.tracks[2].track_metadata.track_id.should.equal Fixtures.track.impapa.track_id


  describe 'with completed tracks', ->
    queueWithPlayedResults = null
    queueWithPlayedResponse = null

    before (done) ->
      Track.submit
        user_id: user1._id
        track_metadata: Fixtures.track.witch
        (t) ->
          playedTrack = t
          playedTrack.played = true
          playedTrack.save (err, doc) ->
            throw err if err
            rest.get("http://localhost:#{app.settings.port}/tracks?user_id=#{user3._id}",
              headers:
                'Accept': 'application/json'
            ).on 'complete', (data, response) ->
              queueWithPlayedResults = data
              queueWithPlayedResponse = response
              done()

    it 'should only display unplayed tracks', ->
      queueWithPlayedResults.tracks.length.should.equal 3
      queueWithPlayedResults.tracks[0].track_metadata.track_id.should.equal Fixtures.track.monkey.track_id
      queueWithPlayedResults.tracks[1].track_metadata.track_id.should.equal Fixtures.track.tortoise.track_id
      queueWithPlayedResults.tracks[2].track_metadata.track_id.should.equal Fixtures.track.impala.track_id



  describe "The Presenter's role", ->

    describe 'beginning playback', ->
      startingQueue = null
      firstTrack = null
      playResponse = null

      before (done) ->
        rest.get("http://localhost:#{app.settings.port}/tracks?user_id=#{user3._id}&limit=4",
          headers:
            'Accept': 'application/json'
        ).on 'complete', (data, response) ->
          startingQueue = data

          firstTrack = startingQueue.tracks[0]

          rest.put("http://localhost:#{app.settings.port}/tracks/#{firstTrack._id}/play?user_id=#{user3._id}",
            headers:
              'Accept': 'application/json'
          ).on 'complete', (data, response) ->
            playResponse = response
            if response.statusCode == 202
              firstTrack = data
            done()

      it "should respond with accepted", ->
        playResponse.statusCode.should.equal 202

      it "should set the track's started_at", ->
        assert.notEqual firstTrack.started_at, null

      it "should mark the track as playing", ->
        assert firstTrack.playing

      it "should not mark the track as played", ->
        assert !firstTrack.played
      
      it "should not set the track's finished_at", ->
        assert !firstTrack.finished_at

      describe 'finish to start', ->
        initQueue = null
        initFinishResponse = null
        initTrack = null
        formerTrack = null

        before (done) ->
          rest.put("http://localhost:#{app.settings.port}/tracks/null/finish?user_id=#{user3._id}",
            headers:
              'Accept': 'application/json'
          ).on 'complete', (data, response) ->
            initFinishResponse = response
            if response.statusCode == 202
              formerTrack = data.finishedTrack
              initTrack = data.nextTrack
              initQueue = data.topThree
            done()

        it 'should not have a former track', ->
          assert !formerTrack

        it 'should give the first track as next', ->
          assert initTrack
          assert initTrack.track_metadata.track_id.should.equal startingQueue.tracks[0].track_metadata.track_id

        it 'should provide the top three', ->
          assert initQueue
          assert initQueue[0].track_metadata.track_id.should.equal startingQueue.tracks[1].track_metadata.track_id



      describe 'finishing playback', ->

        updatedQueue = null
        finishResponse = null
        nextTrack = null

        before (done) ->
          rest.put("http://localhost:#{app.settings.port}/tracks/#{firstTrack._id}/finish?user_id=#{user3._id}",
            headers:
              'Accept': 'application/json'
          ).on 'complete', (data, response) ->
            finishResponse = response
            if response.statusCode == 202
                firstTrack = data.finishedTrack
                nextTrack = data.nextTrack
                updatedQueue = data.topThree
            done()

        it "should respond with accepted", ->
          finishResponse.statusCode.should.equal 202 # accepted

        it "should mark the current track as played", ->
          assert firstTrack.played
          
        it "should set the track's finished_at", ->
          assert.notEqual firstTrack.finished_at, null

        it "should get the latest queue", ->
          assert.notEqual updatedQueue, null
          updatedQueue.length.should.equal 3 # this test fails because there aren't enough mocked tracks 
          nextTrack.track_metadata.track_id.should.equal startingQueue.tracks[1].track_metadata.track_id
