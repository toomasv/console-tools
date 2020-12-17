Red []
extend system/view/VID/styles [
	splitter: [
		template: [
			type: 'base 
			color: beige ;0.0.0.254 
			options: [
				drag-on: down 
				cursor: resize-ew 
				position: left
			] 
			extra: 10
			actors: [
				master: none
				on-down: func [face event][probe face/flags probe face/options]
				;on-drag: func [face event][
					
				;]
				on-create: func [face event /local master size offset code][
					face/options/at-offset: 0x0
					either any [
						object? face/actors/master: master: face/data 
						all [
							block? face/data 
							object? face/actors/master: master: first face/data
						]
					] [
						face/offset: switch face/options/position [
							left [master/offset - as-pair face/extra 0] 
							top [master/offset - as-pair 0 face/extra] 
							right [master/offset + as-pair master/size/x 0] 
							bottom [master/offset + as-pair 0 master/size/y]
						] 
						face/size: switch face/options/position [
							left right [as-pair face/extra face/actors/master/size/y] 
							top bottom [as-pair face/actors/master/size/x face/extra]
						]
					][
						cause-error 'user 'message ["Splitter must have data facet pointing to face(s) to bind to (face! or block of face!s)"]
					]
				;	code: clear []
				;	size: master/size
				;	offset: master/offset
				;	append code switch face/options/position [
				;		left right    [face/offset/y: master/offset/y]
				;		top bottom    [face/offset/x: master/offset/x]
				;	append code switch face/options/position [
				;		left [master/offset/x: face/offset/x   master/size/x: master/size/x - (event/offset/x - offset/x)]
				;		;right  [face/offset/y: master/offset/y   master/offset/x: face/offset/x]
				;		;master/offset/y: face/offset/y master/size/y: size/y + (event/offset/y - offset/y)]
				;		;bottom [face/offset/x: master/offset/x   master/offset/y: face/offset/y]
				;	]
				]
			]
		] 
		;init: [
		;]
	]
]