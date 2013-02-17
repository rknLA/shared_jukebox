mongoose = require 'mongoose'

TrackSchema = new mongoose.Schema
  user_id:
    type: mongoose.Schema.Types.ObjectId
    required: true
  track_metadata:
    service:
      type: String
      required: true
      index: true
    # use track_id for rdio track keys and soundcloud
    track_id:
      type: String
      required: true
    title:
      type: String
      required: true
    artist:
      type: String
      required: true
    album:
      type: String
      required: true
    icon:
      type: String
      required: true
  vote_count:
    type: Number
    default: 1
  votes: [mongoose.Schema.Types.ObjectId]
  submitted_at:
    type: Date
    default: Date.now
  started_at: Date
  finished_at: Date
  playing:
    type: Boolean
    default: false
  played:
    type: Boolean
    default: false

TrackSchema.static 'submit', (attrs, callback) ->
  unless attrs.track_metadata and attrs.track_metadata.service
    callback()
    return

  music_service = attrs.track_metadata.service
  id = attrs.track_metadata.track_id
  that = this
  this.findOne
    'track_metadata.track_id': id
    played: false
    'track_metadata.service': music_service
    (err, track) ->
      if track
        callback()
      else
        track = new that()
        track.track_metadata = attrs.track_metadata
        track.user_id = attrs.user_id
        track.votes = [attrs.user_id]
        track.vote_count
        track.started_at = null
        track.finished_at = null
        track.save (e, doc) ->
          if e
            throw e
          else
            callback doc

TrackSchema.static 'unplayedQueue', (query, callback) ->
  this.find
    played: false
    playing: false
    started_at: null
    finished_at: null
  , null,
    sort:
      vote_count: -1
    limit: if 'limit' of query then query.limit else 20
    skip: if 'offset' of query then query.offset else 0
  , (err, tracks) ->
    throw err if err
    callback tracks

TrackSchema.methods.vote = (user_id) ->
  vote_index = this.votes.indexOf user_id
  if vote_index is -1
    this.votes.push user_id
    this.vote_count += 1
  else
    this.votes.splice vote_index, 1
    this.vote_count -= 1

TrackSchema.static 'play', (track_id, callback) ->
  console.log 'play called on track id: ', track_id
  this.findById track_id, (err, track) ->
    throw err if err
    track.playing = true
    track.started_at = Date.now()
    track.save callback

TrackSchema.static 'finish', (track_id, callback) ->
  that = this
  console.log 'finish called on track_id: ', track_id
  if track_id is null or track_id is 'null' # hook to start the presenter
    console.log "Attempting to finish a null track"
    finishOutput =
      finishedTrack: ''
    that.unplayedQueue {limit: 4}, (queue) ->
      finishOutput.nextTrack = queue[0]
      finishOutput.topThree queue[1..]
      callback finishOutput
  else
    console.log "finishing a non-null track"
    this.findById track_id, (err, track) ->
      console.log "error finding track to finish: ", err
      throw err if err
      track.playing = false
      track.played = true
      track.finished_at = Date.now()
      track.save (err, savedTrack) ->
        console.log 'saved finished track error: ', err
        throw err if err
        finishOutput =
          finishedTrack: savedTrack
        that.unplayedQueue {limit: 4}, (queue) ->
          finishOutput.nextTrack = queue[0]
          finishOutput.topThree = queue[1..]
          callback finishOutput

Track = mongoose.model('Track', TrackSchema)
module.exports = mongoose.model('Track')
