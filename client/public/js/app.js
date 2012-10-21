//;(function($, window, undefined) {

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

var lastSearchResults;

console.log("Using this url: " + url);

$.ajaxSetup({
	cache : false
});

/*$(document).delegate("#vote", "pageinit", function(event) {
	$(".iscroll-wrapper", this).bind( { 
		"iscroll_onpulldown" : function(event, data) {
			console.log("pull down detected")
			fetchUser(function(userID) {
		      refreshVideoQueue(userID, function(newQueue) {
		        renderItems('#video-list', newQueue, data, function() {
		        	alert("I was pulled and got new content")
		        });
		      });
		    });
		}
	});
});*/

$(document).bind('pageinit', function() {
    
    //document.addEventListener("deviceready", function() {

    	$(document).on('pageshow', '#vote', function() {
		    $('[href="#search"]').removeClass('ui-btn-active');
		    $('[href="#vote"]').addClass('ui-btn-active'); //Need this for first time load

		    fetchUser(function(userID) {
		      refreshVideoQueue(userID, function(newQueue) {
		        renderItems('#video-list', newQueue, false);
		      });

		      var timer = null;
		      clearTimeout(timer);

		      timer = setTimeout(function() {
				  refreshVideoQueue(userID, function(newQueue) {
			        renderItems('#video-list', newQueue, false);
			      });
		      }, 3000);
		    });
		});

		$(document).on('pageshow', '#search', function() {
			$('[href="#vote"]').removeClass('ui-btn-active');
			$('[href="#search"]').addClass('ui-btn-active'); //Need this for first time load

			fetchUser(function(userID) {
				setupVideoSearch(userID);
			});
		});

    //}, true); 

});

function ajaxErrorCallback(errorMessage) {
  return function(res) {
    console.log(errorMessage);
    if(res.status == 401) {
      localStorage.clear();
      location.reload();
    }
    console.log(res.responseText)
  }
};


function fetchUser(callback) {
	console.log("Fetching user...");

	//Is userID in localstorage?
	var userID = localStorage.getItem('sc-userID');

	if(userID) {
		console.log("User was in cache");
		console.log(userID)
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
				console.log("There was an error fetching the ID")
				console.log(res.responseText)
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

/* I don't think we use this one anymore */
function getPlaylist(userID, callback) {
	console.log("getting playlist")

	$.ajax({
		url: '/search',
		type: "GET",
		data: {
			q: "katie%20perry",
			user_id: userID
		},
		headers: {
			Accept: 'application/json'
		},                                                             
		success: function(res) {
			console.log("Got the playlist");
			videos = res.videos;
			if(typeof callback === "function") {
				console.log(res)
				callback(res);
			}
		},
		error: ajaxErrorCallback("There was an error getting the playlist")
	});
}

function renderItems(id, res, data, callback) {
	data = (data || false);

	console.log("Rendering Video Items...");

	fetchUser(function(userID) {
		var list = $(id);
		console.log(res)
  lastSearchResults = res;
		list.html('');

		function thumbClick(videoMetaData) {
			var _this = this;

			(function(id, videoMetaData, userID) {
				console.log("Thumb button clicked");
		          if (! 'description' in videoMetaData) {
							  videoMetaData.description = ""; //Need this for back-end bug
		          }
				//fetchUser(function(userID) {
					if(id == '#video-list') {
						console.log("Trying to upvote video")
						upvoteVideo(videoMetaData, userID, function() {
							console.log("Video upvoted")
							console.log(_this)
							$(_this).addClass('voted');
							var count = $(_this).parent().find('.video-list-right').find('.vote-count-value');
							var value = count.val();
							count.html(value + 1);
						})
					}

					else {
						console.log("Trying to submit video")
						submitVideo(videoMetaData, userID, function() {
							console.log("Video submitted...do")
							console.log(_this)
							$(_this).addClass('voted');
						})
					}
					
				//});
			} (id, videoMetaData, userID))
		}

		$.each(res.videos, function(index, video) {
			//List element
			var li = document.createElement('li');

			//Anchor element
			var a  = document.createElement('a');
			a.href = '#';
			//a.innerHTML = video.video_metadata.title;

			//Left
			var left = document.createElement('div');
			left.className += ' video-list-left';

			//Image
			var img = document.createElement('img');
			img.className += ' video-list-img';
			if(video.video_metadata.thumbnail[0] && video.video_metadata.thumbnail[0].url) {
				img.src = video.video_metadata.thumbnail[0].url;
			}
			
			left.appendChild(img);

			//Right
			var right = document.createElement('div');
			right.className += ' video-list-right';

			//Title
			var h3 = document.createElement('h3');
			h3.innerHTML = video.video_metadata.title;
			right.appendChild(h3);

			//Description
			var span = document.createElement('span');
			//span.innerHTML = video.video_metadata.description;
			span.innerHTML = "";
			right.appendChild(span);

			//Append left and right to anchor
			a.appendChild(left);
			a.appendChild(right);

			//Thumb
			var thumb = document.createElement('button');
			thumb.className += ' thumb';

			if(id == '#video-list') {
				if(!$.inArray(userID, video.votes)) {
					thumb.className += ' voted';
				}

			} else {
				if(!$.inArray(userID, video.votes)) {
					thumb.className += ' voted';
				}
			}

			thumb.type = 'button';
			thumb.innerHTML = '&nbsp;';
			thumb.onclick = function(e) {
				thumbClick.call(this, video.video_metadata);
			};
			a.appendChild(thumb);

			//Append anchor to list
			li.appendChild(a);

			//Vote Count
			var voteCount = document.createElement('span');
			voteCount.className += " vote-count";
			if(video.vote_count == 1) {
				span.innerHTML = "<span class='vote-count-value'>" + video.vote_count + "</span><span> vote</span>";
			}

			if(video.vote_count > 1) {
				span.innerHTML = "<span class='vote-count-value'>" + video.vote_count + "</span><span> votes</span>";
			}
			li.appendChild(voteCount);

			//Append list element to list
			list.append(li);
		});

		list.listview('refresh');
		if(data) data.iscrollview.refresh();

		if(typeof callback === "function") callback();
	});
}

function setupVideoSearch(userID) {
	console.log("Setting up the video search...");

	var timer = null;
	var $searchInput = $('#search .ui-input-search [data-type=search]');

	$searchInput.keyup(function(e) {
		var _this = this;
		console.log("Keyup detected...");
		//Only make video search when user stops typing for > half a second
		clearTimeout(timer); 
		timer = setTimeout(function() {
			console.log("Timer cleared..fetching videos...");
			$.ajax({
				url: '/search',
				type: "GET",
				data: {
					q: $(_this).val(),
					user_id: userID
				},
				headers: {
					Accept: 'application/json'
				},                                                             
				success: function(res) {
					console.log("Got the videos");
					renderItems('#search-list', res, false);
				},
      error: ajaxErrorCallback("Failed fetching the videos...")
			});
		}, 500);
	});
}

function submitVideo(videoMetaData, userID, callback) {
	console.log("Submitting a video")

	$.ajax({
		url: '/videos',
		data: {
			video_metadata: videoMetaData,
			user_id: userID
		},
		type: "POST",
		headers: {
			"Accept": 'application/json'
		},                                                          
    error: ajaxErrorCallback("There was an error submitting the video"),
		success: function(res) {
			console.log("Submitted the video successfully!");

			if(typeof callback === "function") callback(userID);
		}
	});
}

function refreshVideoQueue(userID, callback) {
  console.log("Refreshing the video queue");

  $.ajax({
    type: 'GET',
    url: '/videos',
    headers: {
      'Accept': 'application/json'
    },
    data: {
      user_id: userID
    },
    error: ajaxErrorCallback("There was an error refreshing the video queue"),
    success: function(res) {
      console.log("Queue updated successfully!");

      if(typeof callback === "function") callback(res);
    }
  });
};

function upvoteVideo(videoMetaData, userID, callback) {
	$.ajax({
		url: '/vote',
		data: {
			//video_metadata: videoMetaData,
			user_id: userID,
			youtube_video_id: videoMetaData.video_id
		},
		type: "POST",
		headers: {
			"Accept": 'application/json'
		},                                                          
    error: ajaxErrorCallback("There was an error voting for video"),
		success: function(res) {
			console.log("Voted for video successfully!");

			if(typeof callback === "function") callback();
		}
	});
}

//}(jQuery, window));
