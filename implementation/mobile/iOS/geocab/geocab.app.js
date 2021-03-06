//
//  geocab.app.js
//
//  Created by Joaz Vieira Soares on 05/05/15.
//  Copyright (c) 2014 Itaipu.
//

var geocabapp = function(){

	/**
	 * Atributos
	 */
	var layersAdd = [];
	var markersAdd = [];
    var assetsPath = "";
	var view;
	var map;
	var nativeInterface;

	/**
	 * Inicializa atributos
	 */		
	var loadAttributes = function(mapTarget){
	
		view = new ol.View({
			center: ol.proj.transform([-54.1394, -24.7568], 'EPSG:4326', 'EPSG:3857'),
			zoom: 7
		});
		
		map = new ol.Map({
			target: mapTarget,
			layers: [ new ol.layer.Tile({ source: new ol.source.OSM() }) ],
			interactions: ol.interaction.defaults({altShiftDragRotate:false, pinchRotate:false, keyboard: false}),
			view: view,
			control: ol.control.defaults({rotate: false})
		});		
			
	};
	
	/**
	 * Inicializa event handlers
	 */		
	var loadEventHandlers = function(){
		
		map.on('click', function(evt) {

			var feature = map.forEachFeatureAtPixel(evt.pixel, function(feature, layer) {
				return feature;
			});
			
			var listUrls = [];
			var listTitles = [];
			
			// Se a quantidade de camadas for maior que zero
			if ( layersAdd.length > 0) {
				for (var i in layersAdd) {
					var url = layersAdd[i].wmsSource.getGetFeatureInfoUrl(
						evt.coordinate, view.getResolution(), view.getProjection(), {
							'INFO_FORMAT': 'application/json'
						}
					);
					listUrls.push(decodeURIComponent(url));
					listTitles.push(layersAdd[i].title);
				}
			}
			
			if (feature && listUrls.length > 0) {
				app.showInformation(parseInt(feature.getProperties().markerId), feature.getProperties().markerUser, feature.getProperties().markerDate, feature.getProperties().layerName, listUrls, listTitles);
			} else if (!feature && listUrls.length > 0) {
				app.showInformation(null, null, null, null, listUrls, listTitles);
			} else if (feature && listUrls.length == 0) {
				var marker = feature.getProperties();
				nativeInterface.showMarker(parseInt(marker.markerId));
			}
			
		});		
		
	};	
	
	return {
		
		/**
		 * Inicializa componentes
		 */
		init : function(mapTarget, nativeObject){
			loadAttributes(mapTarget);
			loadEventHandlers();
			nativeInterface = nativeObject;
		},
		
		getNativeInterface : function(){
			return nativeInterface;
		},
        
        setAssetsPath : function(path){
            assetsPath = path;
        },
        
        getAssetsPath : function(){
            return assetsPath;
        },
		
		/**
		 * Mostra ou esconde uma camada no mapa
		 */
		showLayer : function(url, name, title, checked) {
		
			// Verifica se a camada est� selecionada
			if (checked == 'true') {
			
				var wmsSource = new ol.source.TileWMS({
					url: url,
					params: { 'LAYERS': name },
				});

				var wmsLayer = new ol.layer.Tile({
					source: wmsSource
				});

				// Adiciona a camada ao mapa
				map.addLayer(wmsLayer);

				// Adiciona a camada a lista global
				layersAdd.push({
					'wmsLayer': wmsLayer,
					'wmsSource': wmsSource,
					'name': name,
					'title': title
				});
				
			} else {
				// Percorre para remover a camada que foi desmarcada
				for (i in layersAdd) {
					if (layersAdd[i].name == name) {
						map.removeLayer(layersAdd[i].wmsLayer);
						layersAdd.splice(i, 1);
					}
				}
			}
		},

		/**
		 * Adiciona um marcador no mapa de acordo com sua localizacao
		 */
		addMarker : function(marker) {
            
            if ( typeof marker === 'string' )
				marker = JSON.parse(marker);

			var layerIcon = this.getAssetsPath() + marker.layer.icon.substring(marker.layer.icon.lastIndexOf('/')+1);
            
			var iconFeature = new ol.Feature({
				geometry: new ol.format.WKT().readGeometry(marker.wktCoordenate),
				markerId: marker.id
			});

			var iconStyle = new ol.style.Style({
				image: new ol.style.Icon(({
					size: [32, 37],
					src: layerIcon
				}))
			});

			var vectorSource = new ol.source.Vector({
				features: [iconFeature]
			});

			// adiciona o recurso na camada vetor  e aplica o estilo para toda a camada
			var vectorLayer = new ol.layer.Vector({
				source: vectorSource,
				style: iconStyle
			});

			// Adiciona a camada vetor na lista do mapa
			map.addLayer(vectorLayer);

			// Adiciona o marker a lista global
			markersAdd.push({
				vectorLayer : vectorLayer,
				marker : marker
			});

		},
        
        /**
         * Adiciona marcadores ao mapa
         */
        addMarkers : function(markers) {
            
            if ( typeof markers === 'string' )
                markers = JSON.parse(markers);
            
            for (pos in markers ) {
                this.addMarker(markers[pos]);
            }
            
        },
		
		/**
		 * Esconde um marcador do mapa a partir do nome
		 */	
		closeMarker : function(layerOrMarkerId) {
			for (i in markersAdd) {
				if (markersAdd[i].marker.id == layerOrMarkerId || 
					markersAdd[i].marker.layer.id == layerOrMarkerId) {
					map.removeLayer(markersAdd[i].vectorLayer);
				}
			}
		},
		
		/**
		 * Busca um marker pelo id
		 */
		findMarker : function(markerId){
			for (i in markersAdd) {
				if (markersAdd[i].marker.id == markerId) {
					return markersAdd[i].marker;
				}
			}
			return null;
		},
		
		/**
		 * Aproxima a �rea de visualiza��o
		 */		
		zoomToArea : function(latitude, longitude) {
			var pan = ol.animation.pan({ source: view.getCenter() });
			var coordinates = ol.proj.transform([longitude, latitude], 'EPSG:4326', 'EPSG:3857');
			map.beforeRender(pan);
			view.setCenter(coordinates);
			view.setZoom(18);
		},

		/**
		 * Mudan�a de estados
		 */	
		changeToActionState : function(){
			$("#action-state").show();
			$("#add-state").hide();
		},
		
		changeToAddState : function(){
			$("#action-state").hide();
			$("#add-state").show();
		},		
		
		changeToSaveState : function(){
			var coordinates = new ol.format.WKT().writeGeometry( new ol.geom.Point(map.getView().getCenter()) );
			nativeInterface.changeToAddMarker(coordinates);
		},

		hideStates : function(){
			$("#action-state").hide();
			$("#add-state").hide();
		}
	
	};

}();