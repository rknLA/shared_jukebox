User = require '../../models/user'
Track = require '../../models/track'

routes = (app) ->
  app.post '/tracks', (req, res) ->
    accepted = req.get('Accept')
    if accepted == 'application/json'
      #make object
      trackId = req.body.track_metadata.track_id
      User.authenticate req, (currentUser) ->
        if currentUser
          Track.submit
            user_id: currentUser._id
            track_metadata: req.body.track_metadata
            (t) ->
              if t
                res.status(201)
                res.json(t)
              else
                Track.findOne
                  'track_metadata.track_id': trackId 
                  (err, track) ->
                    if err
                      res.status(422) # unprocessable entity
                      res.send(err)
                    else
                      res.status(409) # conflict
                      res.json(track)
        else
          res.status(401) # unauthorized
          res.send()
    else
      res.status(406) # not acceptable
      res.send()

module.exports = routes
