
geocabapp.marker = function(){

	var element;
	var initialTop;
	var templateAttribute = "<div><h2 class='marker-label'>{{label}}</h2><p class='marker-value'>{{value}}</p></div>";
	var templateImage = "<div><h2 class='marker-label'>{{label}}</h2><p class='marker-value-img'><img src='{{value}}'></p></div>";
	var currentMarker;
	var currentUser;

	/**
	 * Captura os eventos do touch
	 */
	var swipeStatus = function(event, phase, direction, distance) {
		console.log("Distancia " + distance + " Direction " + direction + " Phase " + phase);
		var duration = 0;
		var speed = 500;
		
		// Se esta em movimento e a direção é pra cima ou para baixo
		if (phase == "move" && direction == "up") {
			scrollToPosition(initialTop - distance, duration);
		} else if (phase == "move" && direction == "down") {
			scrollToPosition(distance, duration);
		
		// Se foi cancelado o movimento e a direção é pra cima ou para baixo
		} else if (phase == "cancel" && direction == "up") {
			scrollToPosition(initialTop, speed);
		} else if (phase == "cancel" && direction == "down") {
			scrollToPosition(0, speed);
			
		// Se o evento terminou e a direção é pra cima ou para baixo
		} else if (phase == "end" && direction == "up") {
			scrollToPosition(0, speed);
		} else if (phase == "end" && direction == "down") {
			scrollToPosition(initialTop, speed);
		}
	}
	
	/**
	 * Atualiza a posição do painel
	 */
	var scrollToPosition = function(distance, duration) {
		element.css("transition-duration", (duration / 1000).toFixed(1) + "s");
		element.css("top", distance);
	}	
	
	var swipeOptions = {
		triggerOnTouchEnd: true,
		swipeStatus: swipeStatus,
		allowPageScroll: "none",
		threshold: 150
	};
	
	var loadInitialTop = function(){
		initialTop = element.parent().height() - 80;
		scrollToPosition(initialTop, 500);
	};
	
	var loadSwipeElement = function(){
		$(".marker-info-header", element).swipe(swipeOptions);
	};
	
	var loadMarkerAttributes = function(marker, image){
		if ( typeof marker === 'string' )
			marker = JSON.parse(marker);
			
        if ( marker.layer !== undefined && marker.layer !== null)
			$(".marker-title", element).html(marker.layer.title);
		
		var html = "";
		var boolField = { Yes : 'Sim', No : 'Não' };
		
		// Atributos
		for (j in marker.markerAttributes ) {
			var attr = marker.markerAttributes[j];
			html += templateAttribute
				.replace("{{label}}", attr.attribute.name)
				.replace("{{value}}", attr.attribute.type == 'BOOLEAN' ? boolField[attr.value] : attr.value);
		}		

		// Imagem
		if ( image !== undefined && image !== "" ){
			html += templateImage.replace("{{label}}", "Imagem").replace("{{value}}", image);
		}
		
		$(".marker-info-content",element).html(html);
		
	};
	
	var loadMarkerActions = function(marker){
		if ( typeof marker === 'string' )
			marker = JSON.parse(marker);
			
		$(".marker-action").hide();
		$(".marker-status").hide();
		
		if ((currentUser.role == 'ADMINISTRATOR' || currentUser.role == 'MODERATOR') || 
			(marker.status == 'PENDING' && currentUser.id == marker.user.id)){
			$(".marker-action.remove").show();
			$(".marker-status").show();
		}
		
		if ((currentUser.role == 'ADMINISTRATOR' || currentUser.role == 'MODERATOR') || 
			(marker.status == 'PENDING' && currentUser.id == marker.user.id)){
			$(".marker-action.update").show();
			$(".marker-status").show();
		}
		
		if ((currentUser.role == 'ADMINISTRATOR' || currentUser.role == 'MODERATOR') && 
			(marker.status == 'ACCEPTED' || marker.status == 'PENDING')){
			$(".marker-action.refuse").show();
		}
		
		if ((currentUser.role == 'ADMINISTRATOR' || currentUser.role == 'MODERATOR') && 
			(marker.status == 'REFUSED' || marker.status == 'PENDING')){
			$(".marker-action.approve").show();
		}
		
		var status = { PENDING : 'STATUS PENDENTE', REFUSED : 'STATUS RECUSADO', ACCEPTED : 'STATUS APROVADO' };
		$(".marker-status").html(status[marker.status]);
	
	};
	
	var hideElement = function(){
		var parentHeight = element.parent().height();
		element.css("top", parentHeight);
	};
	
	return {
		
		init : function(el){
			element = $("#"+el);
			loadSwipeElement();
			hideElement();
		},
		
		show : function(marker, image, loggedUser){
            currentMarker = typeof marker === 'string' ? JSON.parse(marker) : marker;
			currentUser = typeof loggedUser === 'string' ? JSON.parse(loggedUser) : loggedUser;
            
            $.extend(true, currentMarker, geocabapp.findMarker(currentMarker.id));
			
			this.loadAttributes(currentMarker,image);
			this.loadActions(currentMarker);
			
			geocabapp.hideStates();
			loadInitialTop();			
		},
        
        showOptions : function(markerId, attributes, image, userId, userRole){
            var marker = { id : markerId, markerAttributes : JSON.parse(attributes) };
            var user = { id : userId, role: userRole };
            this.show(marker, image, user);
        },
		
		loadActions : function(marker){
			loadMarkerActions(marker);
		},
		
		loadAttributes : function(marker, image){
			loadMarkerAttributes(marker, image);
		},		
		
		hide : function(){
			hideElement();
			geocabapp.changeToActionState();
			geocabapp.getNativeInterface().showOpenMenuButton();
		},
		
		update : function(){
			geocabapp.getNativeInterface().changeToUpdateMarker(JSON.stringify(currentMarker));
		},	
		
		remove : function(){
			geocabapp.getNativeInterface().changeToRemoveMarker(JSON.stringify(currentMarker));
		},		
		
		approve : function(){
			geocabapp.getNativeInterface().changeToApproveMarker(JSON.stringify(currentMarker));
		},
		
		refuse : function(){
			geocabapp.getNativeInterface().changeToRefuseMarker(JSON.stringify(currentMarker));
		},		
	
	};

}();