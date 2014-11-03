$(document).on('click','.twitter-handles-btn', function () {
	var id = $(this).attr('id');
	var target = $(this).data('target');
	var input = $(this).data('update');

	$('.option-group').hide();
	$(target).show();
	$('.active').removeClass('active');
	$(this).addClass('active');
	$(input).val(id);

	// disable selector if text area button clicked
	$('select#twitter_blast_handle_list_id').attr('disabled', (id === "textarea"));

});

$(document).ready( function () {
	var curr_val, blast_btn;

	/**
	setInterval(function () {
		$.ajax({
			url: '/twitter_blast/get_blasts',
			type: "GET",
			dataType: "html",
			success: function (xhr) {
				$('.recent-blasts-update').html(xhr);
			}
		});
	}, 5000);**/


	$('select#twitter_blast_blast_type').change( function () {
		var val = $(this).val();
		$('.active').removeClass('active');
		$('.option-group').hide();

		switch(val) {

			case 'follow_handles':
				$('a#list').show();
				$('.message-row').show();
				break;

			// get followers of user(s) from textarea or handle list
			case "get_followers":
				$('a#list').hide();
				$('.message-row').hide();
				break;

			// tweet to handles from textarea or handle list
			case "tweet_to_handles":
				$('a#list').show();
				$('.message-row').show();
				break;
		}
	});
	
	$('select#twitter_blast_handle_list').on('change', function () {
		var val = $(this).val();

		$.ajax({
			type: "GET",
			url: "twitter_blast/get_handle_list",
			dataType: "json",
			data: { id: val },
			success: function (xhr) {
				var handles =  xhr.handles;
				var handles_container = $('<div />');
				for(var i = 0; i < handles.slice(0,100).length; i++)
					handles_container.append(handles[i].text + " ");

				if (handles.length > 100) handles_container.append('...');
				$('.handle-list-handles').html(handles_container);
			},
			error: function (xhr) {
				$('.handle-list-handles').html('');
			}
		});
	});

	$('.new_twitter_blast').submit( function (event) {
		var loading_gif = $('<img />').attr('src','#{ image_url "ajax-loader.gif" }');
		blast_btn = $(this).find('.blast-btn');
		curr_val = blast_btn.html();
		blast_btn.html(loading_gif);
	}).on('ajax:complete', function () {
		blast_btn.html(curr_val);
	});

});