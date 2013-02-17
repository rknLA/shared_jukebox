User = require '../../models/user'
Track = require '../../models/track'

routes = (app) ->
  app.get '/tracks', (req, res) ->
    accepted = req.get('Accept')
    if accepted == 'application/json'
      User.authenticate req, (currentUser) ->
        if currentUser
          Track.unplayedQueue {}, (tracks) ->
            if tracks 
              output =
                offset: 0
                total_track_count: tracks.length
                track_count: tracks.length
                results: tracks
              res.status 200
              res.send output
            else
              res.status 422
              res.send()
        else
          res.status 401 # unauthorized
          res.send()
    else
      res.status(406) # not acceptable
      res.send()

module.exports = routes
