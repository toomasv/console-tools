Red [
	Description: "Suite of console tools"
	Author: "Toomas Vooglaid"
	Last: 11-Jun-2020
]
clear-reactions
#include %concat.red
ctx: context [
	console-ctx: self
	tool-font: make font! [size: 10 name: "Consolas"]
	extend system/view/VID/styles [
		drawing-box: [
			template: [
				type: 'base
				color: transparent
				options: [tool: figure]
				menu: [
					;"Edit" [               ;TBD
					;	"Pen"        pen
					;	"Fill-pen"   fill
					;	"Line-width" line
					;	"Points"     points
					;]
					"Arrange" [
						"Top"      top
						"Forward"  forward
						"Backward" backward
						"Bottom"   bottom
					]
					"Remove" remove
				]
				actors: [
					ofs: df: none
					on-menu: func [face event][
						switch event/picked [
							pen      []
							fill     []
							line     []
							points   []
							
							top      [move find window/pane face tail window/pane]
							forward  [swap found: find window/pane face next found]
							backward [swap found: find window/pane face back found]
							bottom   [move find window/pane face next head window/pane]
							
							remove   [console remove face]
						]
						focus-console
					]
					on-down: func [face event][
						ofs: event/offset
						system/view/auto-sync?: off
					]
					on-over: func [face event][
						if event/down? [
							df: event/offset - ofs
							case [
								event/ctrl? [
									parse face/draw [any [
									  ['circle | 'ellipse] s: change pair! (s/1 + df) 
									| ['square | 'box | 'rectangle] s: change [2 pair!] (reduce [s/1 + df s/2 + df]) 
									| ['line | 'arrow] s: change [some pair! e:] (pairs: copy/part s e forall pairs [pairs/1: pairs/1 + df])
									| skip
									]]
									ofs: event/offset
								]
								bounding-box = 'large [
									face/draw/translate: face/draw/translate + df
									ofs: event/offset
								]
								bounding-box = 'small [
									face/offset: face/offset + df
								]
							]
							show face
						]
					]
					on-up: func [][system/view/auto-sync?: on]
				]
			]
		]
		separator: [
			template: [
				type:    'base
				color:   0.0.0.254
				options: [type: separator cursor: resize-ns]
				draw:    [pen silver line-width 3 line-cap round line 0x5 20x5]
				actors:  [
					ofs: ofs1: tsz: none
					on-down: func [face event][
						ofs: ofs1: event/face/offset/y 
						tsz: tools/size/y 
						system/view/auto-sync?: off 'done
					]
					on-up:   func [face event][system/view/auto-sync?: on]
					on-drag: function [face event][
						face/offset/x: 10
						df: event/face/offset/y - ofs
						df1: event/face/offset/y - ofs1
						face/parent/size/y: face/offset/y + 10
						face/extra/last/size/y: face/offset/y - face/extra/last/offset/y
						tools/size/y: lsp/size/y: tsz + df1 
						adjust-lsp-mark
						if not empty? next face/extra/rest [
							foreach tool next face/extra/rest [
								tool/offset/y: tool/offset/y + df 
							]
						]
						self/ofs: event/face/offset/y
						adjust-scroller
						show [lsp tools scr]
						'done 
					]
				]
			]
			init: [
				face/extra: reduce [
					'last last face/parent/pane 
					'rest tail tools/pane 
					'mark skip tail face/draw -2
				]
			]
		]
	]
	if not exists?  %notes.txt [write %notes.txt ""]
	notes-file:     %notes.txt
	notes-visible?: no
	notes-face:     none
	notes-saved?:   yes
	reminds-saved?: yes
	size: 100x100            ;default size for figures
	position: 'center        ;default position for figures
	content: text:  none
	bounding-box:   'small ;'large ;
	toolbox: 300    ;default width of toolbox
	window:         gui-console-ctx/win
	term:           gui-console-ctx/terminal
	sources:        %../source/red/
	loaded:         none
	bsp: lsp: content: none
	hour: minute: sec: dial: none
	ws: charset " ^-^/]"
	ws1: charset " ^-^/])"
	par: charset {[]();}
	wspar: union ws par
	
	;adapted from @rebolek's `where`
	definitions: clear []
	extract-def: function [from][;name
		w: tail from
		match: [
			(p: 1) some [#"]" if (0 = p: p - 1) e: :w 
			| #"[" (p: p + 1) 
			| #";" thru [newline | end] 
			| skip
			]
		]
		parse from [
			s: 2 [thru #"[" match :e] (return copy/part s e)  ;Finds only first definition in file
		]
	]
	find-where: function [path name] bind [
		files: read path
		foreach file files [
			file: rejoin [path file]
			case [
				find [%.red %.reds] suffix? file [
					if found: find read file rejoin [name ": func"][
						keep file
						append definitions extract-def found
					]
				]
				dir? file [
					find-where file name
				]
			]
		]
		none
	] :collect
	where: function [
		"Return file where function is defined or NONE, if the definition can't be found"
		name
		/in
			path "Start search in this path (default is current directory)"
	][
		clear definitions
		root: any [path %./]
		collect [find-where root name]
	]
	;^^^^^^^^
	
	notes-ctx: object [content: none]
	reminder-ctx: object [
		content: hour: minute: sec: clk: tasks: alert: none
	]
	reminds: deep-reactor [
		tasks: either exists? %reminds.txt [
			sort/skip load %reminds.txt 2
		][
			write %reminds.txt "" copy []
		]
	]
	live-ctx: object [
		live-type?: target: args1: def: act: loaded: none
	]
	colors: none
	finder-ctx: object [
		all?: cl: clr: clrs: fnd: drw?: img: chw: chw2: h: sm: max-y: none
	]
	define-ctx: object [
		name: places: def: found: data: none
	]
	styles-ctx: object [
		clr: clrs: sty: colors: cfg: none
	]
	
	adjust-scroller: func [/local rel][
		scr/visible?: 1 > rel: window/size/y / max 1 tools/size/y  ;tools-size
		if scr/visible? [
			scr/selected: to percent! rel ;tools-size
		]
	]
	orig: [
		line-width 1 
		pen gray 
		fill-pen 240.240.240.128 
		translate 0x0
		rotate 0 0x0 
		scale 1 1 
		skew 0 0 
	]
	add-shape: function [dr /with spec /tool type][
		bounding-box: self/bounding-box
		position: self/position
		size: self/size
		ofs: 10x10
		fixed: false
		sz: gui-console-ctx/console/size 
		{spec [any [
		      'fixed ;don't try to be smart adjusting layout
		    | ['bounding-box | 'bb] <size: 'large | 'small | pair!>
			| 'at <offset: pair! | 'center | 'top | 'bottom | 'left | 'right | 'top-left | 'top-right | 'bottom-left | 'bottom-right | 'enter> 
			| <size: pair!> 
			| 'pen [tuple! | word!] 
			| <fill-pen: tuple! | word!> 
			| <line-width: integer!>
			| 'translate [pair! | 'x integer! | 'y integer | integer!]
			| 'rotate <angle: integer! | float!> opt <center: pair!>
			| 'scale [<x: number!> <y: number!> | ['x | 'y] number! | number!]
			| 'skew  [<x: number!> <y: number!> | ['x | 'y] number! | number!]
		]]}
		orig: copy self/orig
		if all [with not empty? spec] [
			parse spec [;s: (probe s)
				any [(s: none)
				  'fixed (fixed: true)
				| ['bounding-box | 'bb] s: ['large | 'small | pair!] (bounding-box: s/1)
				| 'at s: [pair! | 'center | 'top | 'bottom | 'left | 'right | 'top-left | 'top-right | 'bottom-left | 'bottom-right | 'enter] (position: s/1)
				| opt 'size pair! s: (size: s/-1)
				| 'pen s: [word! | tuple!] (orig/pen: s/1)
				| opt 'line-width integer! s: (orig/line-width: s/-1)
				| 'translate s: [pair! (orig/translate: s/1) | ['x | 'y] integer! (orig/translate/(s/1): s/2) | integer! (orig/translate: to pair! s/1)]
				| 'rotate s: [integer! | float!] (orig/rotate: s/1) opt [pair! (change skip find/tail orig 'rotate s/2)]
				| 'scale s: [
					2 number! (change find/tail orig 'scale copy/part s 2) 
					| 'x number! (orig/scale: s/2)
					| 'y number! (change next find/tail orig 'scale s/2)
					| number! (change find/tail orig 'scale reduce [s/1 s/1])
					]
				| 'skew s: [
					2 [integer! | float!] (change find/tail orig 'scale copy/part s 2) 
					| 'x [integer! | float!] (orig/scale: s/2)
					| 'y [integer! | float!] (change next find/tail orig 'scale s/2)
					| [integer! | float!] (change find/tail orig 'scale reduce [s/1 s/1])
					]
				| opt 'fill-pen [word! | tuple!] s: (orig/fill-pen: s/-1)
				]
			|	s: (cause-error 'user 'message rejoin ["Figure's spec faulty at: " s])
			]
		]
		
		pos: either pair? position [
			position
		][
			switch position [
				center       [sz / 2 - (size / 2)]
				top          [as-pair sz/x / 2 - (size/x / 2) 0]
				bottom       [as-pair sz/x / 2 - (size/x / 2) sz/y - size/y]
				left         [as-pair 0 sz/y / 2 - (size/y / 2)]
				right        [as-pair sz/x - size/x - 17 sz/y / 2 - (size/y / 2)]
				top-left     [0x0]
				top-right    [as-pair sz/x - size/x - 17 0]
				bottom-left  [as-pair 0 sz/y - size/y]
				bottom-right [sz - size - 17x0]
				enter        [gui-console-ctx/caret/offset]
			]
		]
		
		dr: append copy orig compose bind dr :add-shape
		either bounding-box = 'large [
			dr/translate: dr/translate + pos
		][
			either fixed [
				if bounding-box = 'small [bounding-box: size]
			][
				bounding-box: either word? bounding-box [
					size + dr/line-width
				][
					max bounding-box size + dr/line-width
				]
				dr/translate: max dr/translate to pair! dr/line-width / 2
			]
		]
		append window/pane ret: layout/only compose/only/deep case [
			bounding-box = 'large [
				[at 0x0 drawing-box (sz) all-over draw (dr)]                    ;with large bounding-box
			]
			pair? bounding-box [
				[at (pos) drawing-box (bounding-box) all-over draw (dr)]
			]
		] 
		if tool [ret/1/options: reduce [quote tool: type]]
		first ret
	]
	add-tool: function [spec [block!]][
		if not tools/parent [
			append window/pane reduce [tools lsp]
		]
		cnt: length? tools/pane
		y: either cnt > 0 [
			lst: last tools/pane
			lst/offset/y + lst/size/y
		][0]
		append tools/pane layout/only spec
		new: last tools/pane
		new/offset: as-pair 0 y
		new/size/x: tools/size/x - 10
		tools/size/y: lsp/size/y: tools/size/y + new/size/y
		adjust-scroller
		adjust-lsp-mark
		if not tools/visible? [tools/visible?: yes]
		new
	]
	add-layer: function [spec [object! block!]][
		either object? spec [
			insert ret: next window/pane spec
		][
			insert next window/pane ret: layout/only bind spec self
		]
		first ret
	]
	add-face: func [spec [block!]][
		append window/pane layout/only bind compose/deep spec self
		last window/pane
	]
	
	close-tool: function [face][
		type: face/options/tool
		switch type [
			notes [
				any [
					notes-saved? 
					all [
						confirm "Save notes?" 
						save-notes last face/pane
					]
				] 
			]
			reminder [
				any [
					reminds-saved? 
					all [
						confirm "Save reminds?" 
						save-reminds last face/pane
					]
				] 
			]
		]
		remove-each tool next window/pane [ 
			all [tool/options tool/options/tool = type]
		]	
		rest: find tools/pane face
		if (index? rest) < (length? tools/pane) [
			foreach tl next rest [
				tl/offset/y: tl/offset/y - face/size/y
			]
		]
		console remove face ;either type = 'finder [type][face]
	]
	save-notes: func [content][
		write notes-file content/text 
		notes-saved?: yes
	]
	save-reminds: func [content][
		write %reminds.txt content/text 
		reminds/tasks: load %reminds.txt
		reminds-saved?: yes
	]
	confirm: function [msg][
		response: no
		view [
			title "Confirm"
			text msg return
			button "Yes" [unview response: yes]
			button "No"  [unview]
		]
		response
	]
	is-notes?: func [obj][
		all [
			obj/pane 
			not empty? obj/pane 
			obj/pane/1/type = 'text 
			obj/pane/1/text = "Notes"
		]
	]
	is-live?: func [obj][
		all [
			obj/pane 
			not empty? obj/pane
			obj/pane/1/type = 'text 
			obj/pane/1/text = "Live"
		]
	]
	focus-console: does [window/selected: gui-console-ctx/console ]
	mark-found: function [face found] [
		if found bind [
			idx: index? found
			end: find/match found face/text
			edx: index? end
			shape: reduce switch pick shp/data shp/selected [
				"line"    [
					['line as-pair  idx * chw - chw2 
									y: max-y - sm ;+ (2 * h) 
						   as-pair  edx * chw - chw2 
									y
					]
				]
				"box"     [
					['box as-pair   idx * chw - chw2 
									(y: max-y - sm) - h
						  as-pair   edx * chw - chw2 
									y
					]
				]
				"ellipse" [
					['ellipse as-pair   idx * chw - chw2 - 3
										(y: max-y - sm) - h
							  as-pair   (edx - idx) * chw + 7;- chw2 
										h
					]
				]
				"arrow"   [
					[compose/deep [
						rotate 45.0 (strt: as-pair edx * chw - chw2 y: max-y - sm) [
							line (strt) (strt + 40x0)
							line (strt + 7x3) (strt) (strt + 7x-3)
						]
					]]
				]
			]
			append finder-layer/draw compose [
				pen (clr/draw/fill-pen) 
				(shape)
			]
		] finder-ctx
	] 
	
	
	fld: none
	
	
	tools: none
	sz: gui-console-ctx/console/size
	tools-ctx: object [pos: target: mark: none]
	scr: none
	adjust-lsp-mark: does bind [		
		mark/1/y: to integer! lsp/size/y / 2 - 10
		mark/2/y: mark/1/y + 20
	] tools-ctx
	append window/pane layout/only bind compose [
		at (pos: as-pair sz/x - toolbox - 17 0) tools: panel 300x0 hidden []
			react later [
				tools/offset: as-pair lsp/offset/x 0 
			]
		at (as-pair window/size/x - 27 0) scr: scroller (as-pair 10 window/size/y) hidden 
			react [
				face/offset/x: window/size/x - 27 
				face/size/y: window/size/y 
				face/steps: 34 / window/size/y
				adjust-scroller
			]
			with [steps: 34 / window/size/y][
				tools/offset/y: lsp/offset/y: min 0 to-integer negate face/data * tools/size/y
			]
		at (pos) lsp: box 10x0 0.0.0.254 all-over loose extra #[false] cursor 'resize-we
			draw [pen silver line-width 3 line-cap round line 5x0 5x20]
			on-drag [
				face/offset/y: 0 
				tools/offset/x: face/offset/x
				tools/size/x: window/size/x - face/offset/x - 17
				foreach tool tools/pane [tool/size/x: tools/size/x - 10]
				show [face tools]
			] 
			on-down [system/view/auto-sync?: off]
			on-up   [system/view/auto-sync?: on]
			on-dbl-click [
				either face/extra [
					face/offset/x: tools/offset/x: face/extra
					tools/size/x: window/size/x - face/offset/x - 17
					face/extra: none
				][
					face/extra: face/offset/x
					face/offset/x: tools/offset/x: window/size/x - 27
					tools/size/x: 10
				]
				show [face tools]
				system/view/auto-sync?: on
				'stop
			]
			react later [
				lsp/offset/x: tools/offset/x: window/size/x - tools/size/x - 17
			]
	] tools-ctx
	tools-ctx/mark: skip tail lsp/draw -2 
	figures: [circle ellipse box line]
	colors: load %Paired.png
	
	;helper-ctx
	rt: inspector: last-word: none
	
	set 'console func ['op [word!] what [object! word! block!] /with 'args /as type /local spec][
		switch op [
			add [
				switch type?/word what [
					word! [
						switch what [
							circle        [add-shape/with [circle  (size / 2) (size/x / 2)] args]    ;(ofs + 40x40)
							ellipse       [add-shape/with [ellipse 0x0 (size - 0x20)] args]   ;(ofs) (80x70)
							square        [add-shape/with [box     0x0 (as-pair size/x size/x)] args] ;(ofs) (ofs + 80)
							rectangle box [add-shape/with [box     0x0 (size - 0x20)] args] ;(ofs) (ofs + 80x70)
							line          [add-shape/with [line    0x0 (as-pair size/x 0)] args] ;(ofs) (ofs + 80x0)
							arrow         [add-shape/with [line    0x5 (end: as-pair size/x 5) line (end - 10x5) (end) (end - 10x-5)] args] ;(ofs) (end: ofs + 80x0)
							figure        [
								spec: clear []
								case/all [
									args/bounding-box [append spec take/part find args 'bounding-box 2]
									args/bb [append spec take/part find args 'bb 2]
									args/at [append spec take/part find args 'at 2]
									args/size [append spec take/part find args 'size 2]
								]
								add-shape/with args spec
							]
							
							notes         [
								if not notes-visible? [
									notes-visible?: yes
									notes-face: add-tool bind [
										panel options [tool: notes]
										[
											text "Notes" 60 
											button "Console" [focus-console]
											button "Save"    [save-notes content]
											button "Close"   [close-tool face/parent]
											return
											content: area white 280x200 wrap font tool-font 
											with [text: read notes-file]
											on-change [notes-saved?: no]
											react [face/size/x: tools/size/x - 20]
											at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
										]
									] notes-ctx
								]
							]
							history       [
								add-tool [
									panel options [tool: history] [
										text "History" 60 
										button "Console" [focus-console]
										button "Close"   [close-tool face/parent]
										text "Sel:" 30 selection: text "1" extra []
										return
										list: text-list 280x400 font tool-font focus data system/console/history extra 1 select 1
										with [
											menu: [
												"Note"   note
												"Edit"   edit
												;"Delete" delete
											]
										]
										on-menu [
											line: pick face/data face/selected
											switch event/picked [
												note   [add-lines selection/extra]
												edit   [unview append clear term/line line focus-console]
												;NB! deleting history gets out of sync with terminal/lines??
												;delete [remove-lines selection/extra];remove at system/console/history face/selected]
											]
										]
										on-down [
											case [
												all [event/shift? event/ctrl?] [
													append clear back tail selection/extra 
														copy/part at face/data min face/extra event/picked 
															absolute event/picked - face/extra + 1 
													face/extra: event/picked
												]
												event/shift? [
													append clear selection/extra 
														copy/part at face/data min face/extra event/picked 
															absolute event/picked - face/extra + 1 
													face/extra: event/picked
												]
												event/ctrl? [append selection/extra pick face/data event/picked]
												true [append clear selection/extra pick face/data event/picked]
											]
											selection/data: length? selection/extra
										]
										react [face/size/x: tools/size/x - 20]
										at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
										do [append clear selection/extra pick list/data list/selected]
									]
								] 
							]						
							finder        [
								draw-layer: add-layer compose [
									at 0x0 box (window/size - 17x0) 0.0.0.254 hidden options [tool: finder] all-over 
									draw [line-width 2 scale 1 1] 
									with [
										;extra: gui-console-ctx/scroller/position
										;offset: is [probe as-pair 0 extra - gui-console-ctx/scroller/position]
										actors: object bind [
											ofs: none  ;latest offset
											sel: none  ;last point/element of latest figure
											dsh: none  ;draw-shape
											txt: none  ;draw-text
											cl: none
											fsy: term/line-h
											fsx: term/char-width
											;print ["line-cnt:" term/line-cnt "page-cnt:" term/page-cnt "top:" term/top]
											last-top: term/top
											scx: 1
											scy: 1
											on-wheel: func [face event /local x y df][
												gui-console-ctx/console/actors/on-wheel gui-console-ctx/console event
												system/view/auto-sync?: off
												either event/ctrl? [
													event/face/draw/4: scx: term/char-width / fsx
													event/face/draw/5: scy: term/line-h / fsy
													parse face/draw [any ['transform 4 skip s: (s/1: as-pair scx * s/-6/x scy * s/-6/y) | skip]]
												][
													df: last-top - term/top ;Better than using event/picked * 3, because in cleared console df may be < 3
													if any [term/top > 1 last-top > 1] [
														y: to integer! (df / scy * term/line-h)
														parse face/draw [any [
															['line | 'box] s: 2 pair! (s/1/y: s/1/y + y s/2/y: s/2/y + y)
														|	['ellipse | 'circle | 'text] s: pair! (s/1/y: s/1/y + y)
														|	'transform 4 skip s: pair! (s/1/y: round/to s/-6/y * scy 1)
														|	skip
														]]
													]
													last-top: term/top
												]
												show face
												system/view/auto-sync?: on
												'done
											]
											on-down: func [face event][
												set-focus face
												ofs: as-pair event/offset/x / scx event/offset/y / scy
												dsh: pick shp/data shp/selected
												cl: clr/draw/fill-pen
												append face/draw compose/deep switch dsh [
													"line"    [
														[pen (cl) line (ofs) (ofs)]
													]
													"box"     [
														[pen (cl) box (ofs) (ofs)]
													]
													"ellipse" [
														[pen (cl) ellipse (ofs) 0x0]
													]
													"arrow"   [
														[pen (cl) line (ofs) (ofs) transform 0x0 0 1 1 (as-pair ofs/x * scx ofs/y * scy) [line -7x-3 0x0 -7x3]]
													]
													"text"    [
														[pen (cl) text (ofs) (copy "")]
													]
												]
												sel: back tail face/draw
												if dsh = "text" [txt: sel/1]
											]
											on-up: func [face event][ofs: none]
											on-over: func [face event /local df][
												if event/down? [
													system/view/auto-sync?: off
													eofs: as-pair event/offset/x / scx event/offset/y / scy
													df: eofs - ofs
													switch dsh [
														"line"     [sel/1/x: eofs/x]
														"box"      [sel/1: eofs]
														"ellipse"  [sel/1: df]
														"arrow"    [
															sel/-7: eofs
															sel/-1: as-pair sel/-7/x * scx sel/-7/y * scy 
															sel/-4: arctangent2 df/y df/x
														]
													]
													show face
													system/view/auto-sync?: on
												]
											]
											on-key: func [face event][
												if dsh = "text" [
													switch/default event/key [
														up down page-up page-down []
														left    [txt: back txt]
														right   [txt: next txt]
														delete  [txt: remove txt]
														#"^H"   [txt: remove back txt]
														home    [txt: head txt]
														end     [txt: tail txt]
													][
														if char? event/key [
															txt: insert txt event/key 
															face/draw: face/draw
														]
													]
												]
											]
										] finder-ctx
									]
									react [
										face/size/x: window/size/x - 17 
									]
								] 
								finder-layer: add-layer compose [
									at 0x0 box (window/size) options [tool: finder] draw [
										line-width 2 
										pen red 
									] react [face/size: window/size]
								] 
								add-tool bind [
									panel options [tool: finder] [
										text "Finder" 60 
										button "Console" [focus-console]
										button "Clear"   [either drw?/data [clear at draw-layer/draw 6][clear at finder-layer/draw 5]]
										button "Close"   [close-tool face/parent]
										return
										space 9x10
										all?: check "All" 30 shp: drop-list 60 select 1 data ["line" "box" "ellipse" "arrow" "text"]
										clr: box 22x22 draw [pen gray fill-pen red box 0x0 21x21]
											on-down [clrs/visible?: yes]
										drw?: check "Draw" 44 on-change [draw-layer/visible?: face/data]
										button "<" 15 [clear find/reverse tail draw-layer/draw 'pen]
										button "Image" [
											img: window
											img: to-image img
											img: copy/part at img 10x30 window/size - 20x-20
											write-clipboard draw img/size compose [image img (as-pair 1 img/size/y) (as-pair img/size/x 1)]
											save %screenshot.png img
											view/tight [title "Console-tools screenshot" image img]
										]
										at 10x0 clrs: box 280x24 hidden draw [image colors 0x0 280x23] on-down [ ;Color picker ribbon
											clr/draw/fill-pen: pick colors as-pair event/offset/x * 1.89 10
											face/visible?: no
										]
										return
										fnd: field 280 focus extra [] on-enter [
											/local [lns hs]
											h: term/line-h
											lns: tail term/lines
											hs:  tail term/heights
											sm: 0
											max-y: term/line-y  + (2 * h)
											chw: term/char-width
											chw2: chw / 2 + 1 
											until [
												lns: back lns 
												found: tail lns/1
												hs: back hs 
												sm: sm + hs/1 
												any [
													not all?/data
													until [
														found: find/reverse found face/text
														if found [mark-found face found]
														not found
													]
												]
												any [
													all [
														not all?/data
														all [
															found: find/reverse found face/text
															mark-found face found
														]
													]
													sm > max-y
													head? lns
												]
											]
											;if not all?/data [ ;Redo on scroll?
											;	append/only face/extra reduce [pick shp/data shp/selected clr/draw/fill-pen face/text]
											;]
										]
										react [face/size/x: tools/size/x - 20]
										do [clrs/offset/y: clr/offset/y]
									]
								] finder-ctx
								;react/link func [drl scr][drl/offset/y: scr/position - drl/extra] [draw-layer gui-console-ctx/scroller]
							]
							reminder      [
								task-mark: [push [rotate 0 50x50 line 50x99 50x97]]
								add-tool bind [
									panel options [tool: reminder] [
										text "Remind" 60 
										button "Console" [focus-console]
										button "Save"    [save-reminds content]
										button "Close"   [close-tool face/parent]
										return
										clk: box 100x100 with [
											actors: object [
												on-time: func [face event /local time found ] [
													;/local [time]
													time: now/time 
													minute/2/2: 6 * time/minute 
													hour/2/2: 15 * time/hour + (minute/2/2 / 24)
													sec/2/2: 6 * time/second
													if found: find/skip reminds/tasks time 2 [
														alert/text: found/2
													]
												] 
											]
											draw: compose [
												fill-pen white 
												pen gray 
												line-cap round 
												circle 50x50 45.0 
												(
													d: [push [rotate 0 50x50 line 50x5 50x7]]
													collect [repeat i 24 [
														e: copy/deep d
														e/2/6/y: either i - 1 % 2 = 0 [8][6]
														e/push/rotate: i - 1 * 15
														keep e
													]]
												)
												hour: push [rotate 0 50x50 line-width 3 line 50x50 50x80] 
												minute: push [rotate 0 50x50 line-width 2 line 50x50 50x10] 
												sec: push [rotate 0 50x50 pen Red line-width 1 line 50x50 50x10] 
											] 
											rate: 1
										]
										at 0x0 tasks: box 100x100 draw [line-width 2 pen red]
										at 10x0 alert: box 100x50 "" wrap
										calendar 
										return
										content: area 280 wrap font tool-font
											react [
												face/size/x: tools/size/x - 20
												clear at tasks/draw 5
												foreach [time task] reminds/tasks [
													t: copy/deep task-mark
													t/2/2: 15 * time/hour + (6 * time/minute / 24)
													append tasks/draw t
												]
												face/text: mold new-line/all/skip reminds/tasks true 2
											]
											on-change [notes-saved?: no]
										at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
										do [
											tasks/offset: clk/offset 
											alert/offset/y: clk/offset/y + clk/size/y 
											clk/draw: clk/draw
										]
									]
								] reminder-ctx
							]
							live          [
								if with bind [
									system/view/silent?: yes
									target: get args
									either object? target [
										live-type?: 'object
										args1: collect [
											foreach [key val] body-of target [
												switch/default key [
													type: parent: font: para: state: pane: edge: on-change*: on-deep-change*: on-face-deep-change*: []
												][
													keep key keep/only case [
														none? :val [to-issue "[none]"]
														logic? :val [to-issue rejoin ["[" val "]"]]
														lit-word? :val [to-word val]
														object? :val [to-paren reduce [val]]
														true [:val]
													]
												]
											]
										]
									][
										def: case [word? args [to set-word! args] path? args [to set-path! args]]
										args1: get args
									]
									act: compose/deep either live-type? = 'object [[
										if attempt/safer [loaded: load face/text][
											foreach [key val] loaded [
												attempt/safer [
													key: to-word key
													target/:key: case [
														paren? :val [
															do bind to-block val console-ctx
														]
														set-word? :val [none]
														true [:val]
													]
												]
											]
										]
									]][[
										loaded: load face/text
										attempt/safer [(def) either block? loaded [compose loaded][:loaded]]
										term/refresh
									]]
									add-tool compose/deep/only [
										panel options [tool: live] [
											text "Live" 60
											button "Console" [focus-console]
											button "Close"   [close-tool face/parent]
											return
											area 280x280 font tool-font wrap with [
												text: either string? :args1 [args1][mold args1]
											] 
											on-change (act)
											react [face/size/x: tools/size/x - 20]
											at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
										]
									]
								] live-ctx
							]
							define        [
								add-tool bind [
									panel options [tool: define][
										text "Define" 60
										button "Console" [focus-console]
										button "Close"   [close-tool face/parent]
										return below
										name: field 280 on-enter [/local [found place]
											either empty? found: where/in :face/text sources [
												clear places/data
												clear def/text
											][
												data: copy found
												forall data [data/1: form find/match data/1 sources]
												places/data: data
												places/selected: 1
												def/text: pick definitions 1
											]
										]
										places: text-list 280x100 data []
											on-change [
												def/text: pick definitions face/selected
											]
											react [face/size/x: tools/size/x - 20]
										def: area 280x280 "" font tool-font
											react [face/size/x: tools/size/x - 20]
										at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
									]
								] define-ctx
							]
							helper        [
								system/view/silent?: yes
								console-ctx/rt: add-layer [at 3x0 rich-text 252.252.252 loose options [tool: helper]
									wrap all-over with [
										text: concat copy/part at term/lines term/top term/screen-cnt newline 
										size: gui-console-ctx/win/size - 20 
										font: gui-console-ctx/font
										data: reduce [1x0 'backdrop silver]
										actors: object [
											fix: none
											on-over: func [face event /local start end wrd txt ret][
												if not fix [
													start: any [
														find/tail/reverse at event/face/text offset-to-caret event/face event/offset wspar 
														head event/face/text
													]
													end: any [find start wspar tail start]
													attempt/safer [txt: copy/part start (index? end) - (index? start)]
													if last-word <> txt [
														if attempt/safer [wrd: load txt] [
															if path? wrd [
																either value? first wrd [
																	either any-function? get first wrd [
																		wrd: first wrd
																	][
																		if not attempt/safer [get wrd][
																			wrd: first wrd
																		]
																	]
																][
																	wrd: first wrd
																]
															]
															either all [any [word? wrd path? wrd] attempt/safer [ret: get wrd] word? :ret][
																ctx: context? ret
																in-ctx: either system/words = ctx [
																	"in global context"
																][
																	rejoin ["in context " mold copy/part body-of ctx 20]
																] 
																inspector/text: rejoin [help-string :wrd in-ctx]
															][
																inspector/text: copy/part help-string :wrd 2000
															]
															last-word: txt
														]
													]
													change face/data as-pair start: index? start (index? end) - start
												]
											]
											on-wheel: func [face event][
												gui-console-ctx/console/actors/on-wheel gui-console-ctx/console event
												append clear face/text concat copy/part at term/lines term/top term/screen-cnt newline
											]
											on-down: func [face event][hlp-txt/color: either fix: not fix [silver][snow]]
										]
									]
								]
								add-tool [
									panel options [tool: helper] [
										hlp-txt: text "Helper" 60
										button "Console" [focus-console]
										button "Close"   [system/view/silent?: no close-tool face/parent]
										button "Note"    [add-note select first select pick helper-tab/pane helper-tab/selected 'pane 'text]
										return
										;text "Subject:" 50 drop-list data ["keys" "inspect"] select 1
										helper-tab: tab-panel 280x420 [
											"inspect" [
												inspector: box 260x400 top left wrap font tool-font
												react [face/parent/size: tools/size - 40 face/size: face/parent/size]
											]
											"keys" [
												box 260x400 top left font tool-font %%{#"^M"  [exit-ask-loop] 
	#"^H"  [delete-text/backward ctrl?] 
	#"^~"  [delete-text/backward yes] 
	#"^-"  [unless empty? line [do-completion line char]] 
	left   [move-caret/event -1 event] 
	right  [move-caret/event 1 event] 
	up     [either ctrl? [scroll-lines 1] [fetch-history 'prev]] 
	down   [either ctrl? [scroll-lines -1] [fetch-history 'next]] 
	insert [if event/shift? [paste exit]] 
	delete [either event/shift? [cut] [delete-text ctrl?]] 
	#"^A" home [
		   if shift? [select-text 0 - pos] pos: 0
	] 
	#"^E" end  [
		   if shift? [select-text (length? line) - pos] 
		   pos: length? line
	] 
	#"^C"  [copy-selection exit] 
	#"^V"  [paste exit] 
	#"^X"  [cut] 
	#"^Z"  [undo undo-stack redo-stack] 
	#"^Y"  [undo redo-stack undo-stack] 
	#"^["  [exit-ask-loop/escape] 
	#"^L"  [clean] 
	#"^K"  [clear line pos: 0]
	}%% react [face/parent/size: tools/size - 40 face/size: face/parent/size]]
										
										]
										react [face/size/x: tools/size/x - 20]
										on-change [
											either "inspect" = pick face/data event/picked bind [
												system/view/silent?: yes
												rt/text: concat copy/part at term/lines term/top term/screen-cnt newline
												rt/size: as-pair gui-console-ctx/win/size/x - 20 pick size-text rt 2
												rt/visible?: yes
											] console-ctx bind [
												system/view/silent?: no
												rt/visible?: no
											] console-ctx
										]
										at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
									]
								]
							]
							styles        [
								pan: clear at [origin 0x0] 3
								foreach [key val] body-of term/theme [
									append pan compose/deep [
										check data #[true] 80 
										with [text: (form key)]
										on-change [
											/local [key val pos]
											pos: find/tail face/parent/pane face
											key: to word! face/text
											val: select first pos 'data
											either face/data [
												append term/theme/:key val
											][
												clear term/theme/:key
											]
											;term/update-theme
											term/refresh
										]
										;pad 0x5  text 70 with [text: (form key)]
										;pad 0x-5 
										field 100 with [
											text: (mold val)
											data: [(val)]
										] on-change [
											/local [key chk]
											chk: first back find face/parent/pane face
											key: to word! chk/text
											if chk/data [
												append clear term/theme/:key face/data
											]
											term/update-theme
											;term/refresh
										]
										box 22x22 with [
											draw: compose [pen gray fill-pen (first val) box 0x0 21x21]
										]
										on-down [
											clr: :face
											clrs/offset/y: face/parent/offset/y + face/offset/y
											clrs/visible?: yes
											term/update-theme
										]
									]
								] 
								styles-ctx/colors: load %solar.png
								styles-ctx/cfg: 1.285
								
								add-tool bind compose/deep/only [
									panel options [tool: styles] [
										text   "Styles" 60
										button "Console" [focus-console]
										button "Close"   [close-tool face/parent]
										button "Save"    [
											if file: request-file/save/title/file "Save theme" "*.theme" [
												save file make map! collect [
													foreach [chk val clr] sty/pane [
														if chk/data [
															keep to-set-word chk/text
															keep/only val/data
														]
													]
												]
											]
										]
										return
										text "Scheme" 60 drop-list data [
											"Solar"  [%solar.png] 
											"Paired" [%Paired.png]
										] select 1
										on-change [
											colors: load first pick face/data 2 * face/selected
											cfg: colors/size/x / 280
											clrs/draw: clrs/draw
										]
										check  "Show" 50 data #[true] on-change [term/color?: face/data term/refresh]
										button "Use"  37 [
											if file: request-file/title/filter "Select theme" ["Themes" "*.theme" "All" "*.*"][
												term/theme: load file
												term/update-theme
											]
										]
										return
										sty: panel 3 (pan)
										at 10x0 clrs: box 280x24 hidden draw [image colors 0x0 280x27] 
										on-down [ ;Color picker ribbon
											/local [found val]
											clr/draw/fill-pen: pick colors as-pair event/offset/x * cfg 10 ;1.285   1.89 
											found: find sty/pane clr
											if found [
												found: first back found
												val: found/data
												change val clr/draw/fill-pen
												found/actors/on-change found none
											]
											face/visible?: no
										]
									]
								] styles-ctx
								term/color?: yes
							]
						]
					]
					block! [switch/default type [tool [add-tool what] layer [add-layer what]][add-face what]]
				]
			]
			remove clear delete [
				case [
					object? what [
						if is-notes? what [
							self/notes-visible?: no
						]
						either found: find window/pane what [
							take found
						][
							take find tools/pane what
						]
					]
					word? what [
						either what = 'all [
							clear next window/pane
							clear tools/pane
							self/notes-visible?: no
						][
							wh: form what
							if "s" = w: back tail wh [remove w]
							if find ["square" "rectangle"] wh [wh: "box"]
							wh: to-word wh
							either find figures wh [
								faces: next window/pane
								remove-each tool faces [
									all [
										found: find tool/draw wh 
										any [
											wh <> 'box
											all [
												df: found/3 - found/2
												any [
													all [sq: find [square squares] what  df/1 = df/2]
													all [not sq df/1 <> df/2]
												]
											]
										]
									]
								]
							][
								switch what [
									notes [
										self/notes-visible?: no
										notes-face: none
									]
									live [system/view/silent?: no]
								]
								remove-each tool tools/pane [
									tool/options/tool = what
								]
							]
						]
					]
				]
				tools/size/y: lsp/size/y: either empty? tools/pane [
					tools/visible?: no 
					0
				][
					lst: last tools/pane 
					lst/offset/y + lst/size/y 
				] 
				adjust-scroller
				adjust-lsp-mark
				focus-console
			]
			defaults [
				parse what [
					any [
					  'sources set sources file!             ;where to find sources
					| 'tool-font set p skip (
						switch type?/word p [
							integer! [tool-font/size: p tool-font] 
							string!  [tool-font/name: p]
							word!    [tool-font/style: p]
							block!   [foreach [key val][tool-font/:key: val]]
						]
					  )
					| 'toolbox set toolbox integer! (
						tools/offset/x: lsp/offset/x: window/size/x - toolbox - 17
						tools/size/x: toolbox
						foreach tool tools/pane [tool/size/x: toolbox - 10]
					  )
					| 'bounding-box set bounding-box ['large | 'small | pair!]
					| 'size set size pair!
					| 'fill-pen set p skip (orig/fill-pen: p)
					| 'pen set p skip (orig/pen: p)
					| 'line-width set p skip (orig/line-width: p)
					| 'rotate set p [integer! | float!] (orig/rotate: p) opt [set p pair! (change next find/tail orig 'rotate p)]
					| 'scale s: [
						2 number! (change/part find/tail orig 'scale copy/part s 2) 
					  | 'x number! (orig/scale: s/2)
					  | 'y number! (change next find/tail orig 'scale s/2)
					  | number! (change/part find/tail orig 'scale reduce [s/1 s/1] 2) 
					  ]
					| 'skew s: [
						2 [integer! | float!] (change/part find/tail orig 'skew copy/part s 2) 
					  | 'x [integer! | float!] (orig/skew: s/2)
					  | 'y [integer! | float!] (change next find/tail orig 'skew s/2)
					  | [integer! | float!] (change/part find/tail orig 'skew reduce [s/1 s/1] 2) 
					  ]
					| 'translate [
						set p pair! (orig/translate: p)
					  | 'x set p integer! (orig/translate/x: p)
					  | 'y set p integer! (orig/translate/y: p)
					  | set p integer! (orig/translate: to-pair p)
					  ]
					]
				]
			]
		]
	]
	
	;Simple shapes
	set 'circle    func [/with spec][either block? spec [console/with add 'circle :spec][console add 'circle]]
	;set 'circles   func [n [integer!]][] ;TBD?
	set 'ellipse   func [/with spec][either block? spec [console/with add 'ellipse :spec][console add 'ellipse]]
	set 'square    func [/with spec][either block? spec [console/with add 'square :spec][console add 'square]]
	set 'rectangle func [/with spec][either block? spec [console/with add 'rectangle :spec][console add 'rectangle]]
	set 'box       func [/with spec][either block? spec [console/with add 'box :spec][console add 'box]]
	set 'line      func [/with spec][either block? spec [console/with add 'line :spec][console add 'line]]
	set 'arrow     func [/with spec][either block? spec [console/with add 'arrow :spec][console add 'arrow]]
	set 'figure    func [spec][console/with add 'figure :spec]
	
	set 'animate func [face action /rate r][face/actors: make face/actors [on-time: func [face event] action] if rate [face/rate: r]]
	set 'stop func [what][foreach face what [face: get face face/rate: none]]
	
	set 'animate-all func [spec /local face action rate sw def][ ;TBD
		parse spec [any [
			set face word! (face: get face) 
			any [set sw set-word! set def block! (do compose [(sw) (def)])]
			set action block! 
			opt [[integer! | time!] s: (rate: s/-1)]
			(animate/rate face action rate)
		]]
	]

	;Note funcs
	append-note: func [line][
		if notes-visible? bind [
			append content/text rejoin [mold/all/only load line newline]
			notes-saved?: no
		] notes-ctx
	]
	add-note: func [line][
		either notes-visible? [
			append-note line
		][
			write/append notes-file rejoin [mold/all/only load line newline]
		]
	]
	add-lines: function [lines][
		foreach line lines [add-note line]
	]
	
	set 'replay function [act /to stop][
		case [
			integer? act [
				foreach line reverse copy/part next system/console/history act [
					do line
				]
			]
			issue? act [
				foreach line reverse copy/part either to [
					find/tail system/console/history stop
				][
					next system/console/history
				] find system/console/history mold act [
					do line
				]
			]
		]
	]
	
	;;Don't mess with history :)
	;remove-lines: function [lines][
	;	foreach line lines [remove find system/console/history line]
	;]
	
	;Call tools
	set 'note     func [act /to stop][
		case [
			act = 'last  [add-note second system/console/history]
			integer? act [foreach line reverse copy/part next system/console/history act [add-note line]]
			issue? act   [
				foreach line reverse copy/part either to [
					find/tail system/console/history stop
				][
					next system/console/history
				] find/tail system/console/history mold act [
					add-note line
				]
			]
			string? act  [add-note mold act]
			act = 'time [time: now/time add-note rejoin [time/hour ":" time/minute]]
			act = 'date [add-note form now/date]
			true [add-note mold/all/only act]
		]
	]
	set 'notes    does [console add 'notes]
	set 'history  does [console add 'history]
	set 'finder   does [console add 'finder]
	set 'live     func [what][console/with add 'live :what]
	set 'reminder does [console add 'reminder]
	set 'remind   func [spec [block!]][write %reminds.txt new-line/all/skip sort/skip append reminds/tasks spec 2 true 2]
	set 'define   does [console add 'define]
	set 'helper   does [console add 'helper]
	set 'styles   does [console add 'styles]
	if 'switch = first menu-body: body-of :window/actors/on-menu [
		append window/menu [
			"Tools" [
				"Notes"    notes 
				"History"  history 
				"Finder"   finder 
				"Live"     live 
				"Reminder" reminder 
				"Define"   define 
				"Helper"   helper
				"Styles"   styles
			]
		]
		change/only menu-body 'switch/default
		append/only menu-body [
			either 'live = event/picked [
				pos: window/size / 2 - 40x40
				live-face: box/with [gray]
				live 'live-face
			][
				do event/picked
			]
		]
		window/actors/on-menu: func spec-of :window/actors/on-menu bind menu-body gui-console-ctx
	]
	
]