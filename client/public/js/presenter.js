var document = window.document;
window.scrollTo(0, 1);

var url;
var local = "local.m.sharedcinema.com";
if(document.domain == local) {
	url = 'http://' + local;
}

else {
	url = 'http://m.sharedcinema.com';
}

console.log("Using this url: " + url);

$( function() {
  var userID,
    presenter;

  function fetchUser(callback) {
    console.log("Fetching user...");

    //Is userID in localstorage?
    var userID = localStorage.getItem('sc-userID');

    if(userID) {
      console.log("User was in cache");
      console.log(userID);
      callback(userID); return;
    } else {
      console.log("New user detected..getting ID");

      $.ajax({
        url: '/users',
        type: "POST",
        headers: {
          "Accept": 'application/json'
        },                                                          
        error: function(res) {
          console.log("There was an error fetching the ID");
          console.log(res.responseText);
        },
        success: function(res) {
          console.log("Got the user ID! " + res._id);

          var userID = res._id;
          localStorage.setItem('sc-userID', userID);
          if(typeof callback === "function") callback(userID);
        }
      });
    }
  }

  R.ready(function() {
    presenter.onUpdateTopThree(function(topThree) {
      renderPlaylist(topThree);
    });
    presenter.onNextTrackLoaded(function(nextTrack) {
      playTrack(nextTrack.track_metadata.track_id, nextTrack);
    });
    presenter.begin();

    R.player.on('change:playingTrack', function(e) {
      if (e === null) {
        //playing track changed to a null track;
        presenter.trackDidFinish();
      }
    });

  });


// initialize the presenter api interface
  fetchUser(function (userId) {
    presenter = new window.SharedCinema.PresenterModel(userId);
  });


  function playTrack(id, track) {
    console.log("playing video: " + id);
    //assuming rdio for now
    R.ready(function() {
      R.player.play({source: id});
      $('#current-track').attr("src", track.track_metadata.bigIcon);
    });

    var trackText = '"' + track.track_metadata.title + '"';
    trackText += ' - ' + track.track_metadata.artist;
    trackText += ' (' + track.track_metadata.album + ')';

    $('#video-title').html(trackText);
  }

  function renderPlaylist(tracks) {
    //console.log("rendering playlist")
    $.each(tracks, function(index, track) {

      if (index === 0) {
        //console.log("I am the second video: " + video.video_metadata.video_id)
        $("#video-2").attr("src", track.track_metadata.bigIcon);
      }

      if(index == 1) {
        //console.log("I am the third video: " + video.video_metadata.video_id)
        $("#video-3").attr("src", track.track_metadata.bigIcon);
      }

      if(index == 2) {
        //console.log("I am the forth video: " + video.video_metadata.video_id)
        $("#video-4").attr("src", track.track_metadata.bigIcon);
      }
    });
  }
});
