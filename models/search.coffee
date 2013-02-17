querystring = require 'querystring'
rest = require 'restler'
mongoose = require 'mongoose'
async = require 'async'

app = require '../server'

Video = require './video'
Track = require './track'

SearchSchema = new mongoose.Schema
  user:
    type: mongoose.Schema.Types.ObjectId
    required: true
  query:
    type: String
    required: true
  results:
    type: Array
    required: true
  service:
    type: String
    required: true
  pageSize:
    type: Number
    required: true
    default: 20
  

consolidateVideoMetadata = (googleMetadata) ->
  consolidatedMetadata =
    title: googleMetadata.title.$t
    description: googleMetadata.media$group.media$description.$t
    video_id: googleMetadata.media$group.yt$videoid.$t

mergeSearchVideoWithDbVideo = (item, callback) ->
  consolidated = consolidateVideoMetadata item
  Video.findOne
    'video_metadata.video_id': consolidated.video_id
    played: false
    (err, vid) ->
      searchResult =
        video_metadata: consolidated
        submission_id: if vid then vid.id else null
        vote_count: if vid then vid.vote_count else null
        votes: if vid then vid.votes else []
      callback null, searchResult

mergeRdioSearchTrackWithDbTrack = (item, callback) ->
  item.track_id = item.key
  item.title = item.name
  delete item.key
  delete item.name
  Track.findOne
    'track.track_id': item.track_id
    'service': 'Rdio'
    played: false
    (err, track) ->
      if err
        callback err
        return
      searchResult =
        track_metadata: item
        submission_id: if track then track.id else null
        vote_count: if track then track.vote_count else 0
        votes: if track then track.votes else []
      callback null, searchResult

processRdioResults = (raw, callback) ->
  results = JSON.parse(raw)
  tracks = results.result.results
  async.map tracks, mergeRdioSearchTrackWithDbTrack, (err, results) ->
    if err
      console.log "AN ERROR IN PROCESS RDIO RESULTS", err
    throw err if err
    callback results

SearchSchema.static 'createWithTracksQuery', (attrs, callback) ->
  search = new this()
  search.user = attrs.user_id
  search.query = attrs.q
  search.service = 'Rdio'
  search.pageSize = 20

  rdioQuery =
    query: attrs.q
    count: search.pageSize
    types: 'Track'
    extras: '-*,name,artist,album,key,icon'
  rdioQueryStr = querystring.stringify rdioQuery

  app.settings.rdio.call 'search', rdioQuery, (err, res) ->
    console.log(err)
    throw err if err
    processRdioResults res, (results) ->
      search.results = results
      # do soundcloud search here
      search.save (e, doc) ->
        throw e if e
        callback doc

SearchSchema.static 'page', (search_id, page_number, callback) ->
  callback

Search = mongoose.model('Search', SearchSchema)

module.exports = mongoose.model('Search')
