(function() {
  var PresenterAPI;

  window.SharedCinema || (window.SharedCinema = {});

  window.SharedCinema.PresenterModel = PresenterAPI = (function() {

    function PresenterAPI(user_id) {
      this.topThree = [];
      this.currentTrack = null;
      this.userId = user_id;
      this.blockAsyncTopThreeUpdate = false;
    }

    PresenterAPI.prototype.begin = function(nextTrackCallback, topThreeCallback) {
      if (topThreeCallback) this.onUpdateTopThree(topThreeCallback);
      if (nextTrackCallback) this.onNextTrackLoaded(nextTrackCallback);
      return this.trackDidFinish();
    };

    PresenterAPI.prototype.trackDidFinish = function() {
      var trackId,
        _this = this;
      this.blockAsyncTopThreeUpdates = true;
      trackId = this.currentTrack && '_id' in this.currentTrack ? this.currentTrack._id : 'null';
      return $.ajax({
        type: 'PUT',
        url: "/tracks/" + trackId + "/finish",
        headers: {
          'Accept': 'application/json'
        },
        data: {
          user_id: this.userId
        },
        error: this.handleAjaxError,
        success: function(data, response) {
          _this.setTopThree(data.topThree);
          return _this.queueNextTrack(data.nextTrack);
        }
      });
    };

    PresenterAPI.prototype.queueNextTrack = function(track) {
      this.currentTrack = track;
      if (typeof this.notifyNextTrackListener === 'function') {
        this.notifyNextTrackListener(this.currentTrack);
      }
      return $.ajax({
        type: 'PUT',
        url: "/tracks/" + track._id + "/play?user_id=" + this.userId,
        headers: {
          'Accept': 'application/json'
        },
        error: this.handleAjaxError,
        success: function(data, response) {
          return this.blockAsyncTopThreeUpdates = false;
        }
      });
    };

    PresenterAPI.prototype.setTopThree = function(topThree) {
      this.topThree = topThree;
      if (typeof this.notifyTopThreeListener === 'function') {
        this.notifyTopThreeListener(this.topThree);
      }
      return this.setPollTopThree(1000);
    };

    PresenterAPI.prototype.handleAjaxError = function(response, description) {};

    PresenterAPI.prototype.setPollTopThree = function(time) {
      var _this = this;
      return this.topThreeTimeout = setTimeout(function() {
        return $.ajax({
          type: 'GET',
          url: "/tracks?user_id=" + _this.userId + "&limit=3",
          headers: {
            'Accept': 'application/json'
          },
          error: _this.handleAjaxError,
          success: function(data, response) {
            return _this.setTopThree(data.results);
          }
        });
      }, time);
    };

    PresenterAPI.prototype.onUpdateTopThree = function(callback) {
      this.notifyTopThreeListener = callback;
      return this;
    };

    PresenterAPI.prototype.onNextTrackLoaded = function(callback) {
      this.notifyNextTrackListener = callback;
      return this;
    };

    PresenterAPI.prototype.trackFinished = function() {
      return this.updateFromFinishedTrack;
    };

    return PresenterAPI;

  })();

}).call(this);
