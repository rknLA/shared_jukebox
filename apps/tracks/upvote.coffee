User = require '../../models/user'
Track = require '../../models/track'

routes = (app) ->
  app.post '/vote/track', (req, res) ->
    accepted = req.get('Accept')
    if accepted == 'application/json'
      trackId = req.body.track_id
      User.authenticate req, (currentUser) ->
        if currentUser
          Track.find {}, (err, tracks) ->
          Track.findOne
            'track_metadata.track_id': trackId
            played: false
            (err, track) ->
              throw err if err
              if track
                track.vote currentUser._id
                track.save (err) ->
                  throw err if err
                  res.status 200
                  res.send()
              else
                res.status 422
                res.send()
        else
          res.status 401 # unauthorized
          res.send()
    else
      res.status 406 # not acceptable
      res.send()

module.exports = routes
