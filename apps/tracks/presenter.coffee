User = require '../../models/user'
Track = require '../../models/track'

routes = (app) ->
  app.put '/tracks/:track_id/play', (req, res) ->
    accepted = req.get('Accept')
    if accepted == 'application/json'
      User.authenticate req, (currentUser) ->
        if currentUser
          Track.play req.params.track_id, (err, track) ->
            throw err if err
            res.status 202
            res.json(track)
        else
          res.status 401 # unauthorized
          res.send()
    else
      res.status 406 # not acceptable
      res.send()

  app.put '/tracks/:track_id/finish', (req, res) ->
    accepted = req.get('Accept')
    if accepted == 'application/json'
      User.authenticate req, (currentUser) ->
        if currentUser
          Track.finish req.params.track_id, (output) ->
            res.status 202
            res.json(output)
        else
          res.status 401 # unauthorized
          res.send()
    else
      res.status 406 # not acceptable
      res.send()




module.exports = routes
