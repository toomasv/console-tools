Red [
	Description: "Suite of console tools"
	Author: "Toomas Vooglaid"
	Date: "June 2020"
]
clear-reactions
#include %concat.red
#include %info.red
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
	cons:           system/console
	sources:        %../source/red/
	loaded:         none
	bsp: lsp: content: none
	hour: minute: sec: dial: none
	
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
	mark-found: function [face found /with txt] [
		if found bind [
			idx: index? found
			end: find/match found any [txt face/text]
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
		at (pos: as-pair sz/x - toolbox - 17 0) tools: panel 300x0 hidden
			with [menu: ["Detach" detach "Attach" attach]]
			on-menu [
				switch event/picked [
					detach [
						tools-lay: layout compose [size (tools/size)] 
						append tools-lay/pane take/part found: find window/pane tools 3
						clear found 
						face/offset: 0x0 
						scr/offset: as-pair tools-lay/size/x - 10
						scr/size/y: tools-lay/size/y
						view/flags/options tools-lay 'resize [
							text: "Console-tools" 
							actors: object [
								on-resizing: func [face event][
									tools/size/x: face/size/x - 10
									scr/size/y: face/size/y
								]
							]
						]
					]
					attach [
						tools-lay/visible?: no
						append tail window/pane take/part tools-lay/pane 3
						append window/pane lsp
						tools/offset/x: lsp/offset/x: window/size/x - tools/size/x - 17
						scr/offset: as-pair window/size/x - 27 0
						scr/size/y: window/size/y
						unview tools-lay
					]
				]
				'done
			] []
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
				face/actors/on-down face none
				'stop
			]
			react later [
				lsp/offset/x: tools/offset/x: window/size/x - tools/size/x - 17
			]
	] tools-ctx
	tools-ctx/mark: skip tail lsp/draw -2 
	figures: [circle ellipse box line]
	colors: load %Paired.png
	
	sp: charset " ^-"
	ws: charset " ^/^-"
	nonws: negate ws
	opn: charset "[("
	cls: charset ")]"
	cls2: union ws cls
	brc: union opn cls
	brc2: union brc charset "{}"
	skp: union ws brc
	skp2: union skp charset "/"
	skp3: union skp2 charset ":"
	skp4: union skp3 charset "'"
	com-check: charset {^/;}
	skip-chars: charset "#$&"
	opn-brc: charset "{[(^"" ;"
	opp: "[][()({}{^"^""
	delim: union ws charset "[(:'{"
	
	console-prompt: cons/prompt
	console-result: cons/result

	par: charset {[]();}
	wspar: union ws par

	helper-ctx: context [
		rt: inspector: last-word: colors: clrs: cfg: col-num: style: scheme: sty: lh: curtop: watching?: look: watch: none
		
		line-points: func [str i1 i2 /local rest next-rest out first-line len stop pos start][
			pos: 1000
			out: clear []
			if 1 < len: length? first-line: trim/tail copy/part str start: next-rest: rest: find/tail str newline [
				repend out ['line lh + caret-to-offset rt i1    lh + caret-to-offset rt i1 + len]
			]
			;while [
			;	next-rest: find/tail/part rest newline i2 - index? rest
			;][
			;	stop: find rest nonws
			;	pos:  min pos (index? stop) - (index? rest)
			;	rest: next-rest
			;]
			;repend out ['line start: -3x0 + caret-to-offset rt (index? start) + pos   as-pair start/x second caret-to-offset rt index? rest]
			until [
				rest: next-rest
				stop: find rest nonws
				pos: min pos (index? stop) - (index? rest)
				not next-rest: find/tail/part rest newline i2 - index? rest
			]
			repend out ['line start: caret-to-offset rt (index? start) + pos   as-pair start/x second caret-to-offset rt index? rest];lh/y + 
			if 1 < len: length? trim/tail copy/part last-line: find rest nonws len: i2 - i1: index? last-line [
				repend out ['line lh + caret-to-offset rt i1    lh + caret-to-offset rt 12];i1 + len]
			]
			out
		]
		segments: func [str i1 i2 clr /local rest out len stop][
			out: clear []
			len: length? trim/tail copy/part str rest: find/tail str newline
			repend out [as-pair i1 len 'backdrop clr]
			until [
				stop: find rest nonws
				either rest: find/tail/part rest newline i2 - index? rest [
					repend out [as-pair index? stop (index? rest) - (index? stop) - 1 'backdrop clr]
				][
					len: length? trim/tail copy/part stop i2 - index? stop
					repend out [as-pair index? stop len 'backdrop clr]
				]
				not rest
			]
			out
		]
		stylize: func [str i1 i2 clr][
			switch sty [
				;backdrop [repend rt/data [as-pair i1 i2 - i1 sty clr]] ;full block
				backdrop [
					either multiline?: find/part str newline i2 - i1 [  ;rugged block
						append rt/data segments str i1 i2 clr
					][
						repend rt/data [as-pair i1 i2 - i1 sty clr]
					]
				]
				line [
					either multiline?: find/part str newline i2 - i1 [
						append rt/draw append compose [pen (clr)] line-points str i1 i2
					][
						repend rt/draw ['pen clr 'line lh + caret-to-offset rt i1 lh + caret-to-offset rt i2]
					]
					rt/draw: rt/draw
				]
				hybrid [
					either multiline?: find/part str newline i2 - i1 [
						repend rt/data [as-pair i1 i2 - i1 'backdrop clr + 96]
					][
						repend rt/draw ['pen clr 'line lh + caret-to-offset rt i1 lh + caret-to-offset rt i2]
					]
					rt/draw: rt/draw
				]
				text [repend rt/data [as-pair i1 i2 - i1 clr]]
			]
		]
		get-color: func [n][
			either cfg = 1 [snow - (n * 16)][pick colors as-pair n * cfg - (cfg / 2) 10]
		]
		set-color: func [s1 arg n render /local clr i1 i2 s2][ 
			clr: get-color n
			either attempt [i2: index? s2: arg-scope s1 arg][
				while [find ws s1/1][s1: next s1]
				i1: index? s1
				if render [stylize s1 i1 i2 clr]
				s1: :s2
			][rt/data/3: red]
		]
		left-scope: func [str [string!] /local i [integer!]][i: 0
			until [str: back str not find/match str ws]
			either #")" = str/1 [find/reverse str "("][find/reverse/tail str skp]
		]
		arg-scope: func [
			str [string!] 
			arg [none! word! lit-word! get-word!] ;block! datatype! typeset!
			/left /right
			/local el el2 s0 s1 s2 i2 _  
		][;probe reduce [copy/part str 20 arg]
			either left [
				s1: left-scope str
				s0: left-scope s1
				el: attempt/safer [load/next s0 '_]
				if op? attempt [get/any el][s1: arg-scope/left s0 none]
			][
				;probe str
				if el: attempt/safer [load/next str 's1][
					;probe el
					el2: either any [right parse s1 [any [#" " | #"^-"] newline ["==" | ">>"] (e: tail s1) :e]] [none][attempt/safer [load/next s1 's2]]
					either all [word? el2 op? attempt/safer [get/any el2]][
						s1: arg-scope s2 none
					][
						either find/match str "#include " [
							s1: arg-scope s1 none
						][
							if any [not arg word? arg][; don't go for lit-word and get-word args
								switch type?/word el [
									set-word! set-path! [s1: arg-scope s1 none]
									word! [if any-function? get/any el [s1: scope str false]]
									path! [
										case [
											any-function? get/any first el [s1: scope str false]
											get-function el [s1: scope str false]
										]
										;if any [
										;	any-function? get/any first el
										;	get-function el
										;][s1: scope str]
									]
								]
							]
						]
					]
				]
			]
			s1
		]
		scope: func [
			str [string!] 
			render [logic!]
			/color col 
			/local fn fnc inf clr arg i1 i2 s0 s1 s2 multi-line? n 
		][
			if all [any [find/match str "==" find/match str ">>"] str/-1 = newline][return none]
			fn: load/next str 's1
			n: 0
			sty: pick style/data style/selected - 1 * 2 + 2
			case [
				all [word? fn any-function? get/any :fn] [fnc: fn]
				all [path? fn fn1: get-function fn 1 = length? fn1] [fnc: fn/1]
				all [path? fn fn1] [fnc: fn1]
				'else [fnc: none]
			]
			either fnc [
				inf: info :fnc
				 
				either op! = inf/type [
					i2: -1 + index? str
					clr: get-color n: n + 1
					s0: arg-scope/left str none
					i1: index? s0
					if render [stylize s0 i1 i2 clr]
					i2: index? s2: arg-scope/right s1 none 
					while [all [s1/1 find ws s1/1]][s1: next s1]
					i1: index? s1
					clr: get-color n: n + 1
					s0: arg-scope/left str none
					if render [stylize s0 i1 i2 clr]
				][
					foreach arg inf/arg-names [
						s1: set-color s1 arg n: n + 1 render
					]
				]
				if all [path? fn any [word? fnc (length? fn) > (length? fnc)]][
					foreach ref either word? fnc [next fn][skip fn length? fnc] [
						if 0 < length? refs: inf/refinements/:ref [
							foreach arg extract inf/refinements/:ref 2 [
								s1: set-color s1 arg n: n + 1 render
							]
						]
					]
				]
				show rt
				s1
			][
				arg: none
				if find [set-word! set-path!] type?/word fn [
					s1: set-color s1 arg n: n + 1 render
				]
			]
		]
		is-string?: func [start][find "^"{" start/1] 
		end-of-string: function [start][
			n: 0
			rule: switch start/1 [
				#"^"" [[#"^""
					some [
					  [#"^/" | end start] e: (cause-error 'user 'message rejoin ["Invalid string " copy/part start e]) 
					| {"} e: (s: tail start) :s ;"
					| skip
					]
				]]
				#"{" [[
					some [
					  ["^^{" | "^^}"]
					| #"{" (n: n + 1)
					| #"}" (n: n - 1) opt [if (n = 0) e: (s: tail start) :s]
					| skip
					]
				]]
			]
			parse start rule
			e
		]
		;--------------
		comment {
		make-transparent: function [img alpha][
			tr: copy at enbase/base to-binary alpha 16 7
			append/dup tr tr to-integer log-2 length? img
			append tr copy/part tr 2 * (length? img) - length? tr
			make image! reduce [img/size img/rgb debase/base tr 16]
		]
		
		screen_size: make-transparent make image! window/size - 20x0 255
		drag: .8
		max_age: 3.0
		particles: copy []
		random/seed now/time/precise
		draw_blk: none
		i: none

		explode: func [xy speed /local angle radius][
			particle_color: 255.255.255.0 - random 128.128.128.0
			speed: 1 + (-0.5 + random 1.0) * speed
			loop 50 + random 100 [
				append particles reduce [
					xy/x
					xy/y
					speed * (radius: (random 1.0) ** .5) * sin (angle: random 2 * pi)
					speed * radius * cos angle
					random max_age
					particle_color
				]
			]
		]

		draw_screen: func [/local xy][
			draw_blk: compose [fill-pen 255.255.255.100 box 0x0 (window/size - 20x0)]
			foreach [x y vx vy age part_col] particles [
				xy: to-pair reduce [x y]
				append draw_blk compose [
					pen (pc: (part_col - (random 32.32.32.32) * (age / max_age)))
					fill-pen (pc)
					circle (xy) ((random 2) * (age / max_age))
				]
			]
			draw screen_size draw_blk
		]

		update: func [dt /local particle][
			new_particles: copy []
			drag: drag ** dt
			foreach [x y vx vy age part_col] particles [
				if positive? age [
					vx: vx * drag
					vy: vy * drag
					particle: reduce [
						x + vx
						y + vy
						vx
						vy
						age - dt
						part_col
					]
					append new_particles particle
				]
			]
			particles: new_particles
		]

		explode random window/size - 20x0 1.5
		period: .01
		speed: 1.5
		}
		
	]
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
										list: text-list 280x400 font tool-font focus data cons/history extra 1 select 1
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
												;delete [remove-lines selection/extra];remove at console/history face/selected]
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
												either lnk?/data [
													st: offset-to-caret rt ofs
													if all [
														found: find/reverse at rt/text st "http"
														;found: find/match found "http" 
														txt: either e: find found brc2 [copy/part found e][copy found]
													][
														browse to-url txt
													]
												][
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
								link-layer: add-layer [
									at 3x0 rt: rich-text 252.252.240 hidden draw []
									wrap all-over with [
										text: concat copy/part at term/lines curtop: term/top tail term/lines newline ;screen-cnt
										size: as-pair window/size/x - 20 term/line-y;window/size - 20 
										font: gui-console-ctx/font
									]
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
										fnd: field 230 focus extra [] on-enter [
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
										react [face/size/x: tools/size/x - 70]
										lnk?: check "Link" on-change [
											either face/data [
												/local [lns hs txt]
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
															found: find/reverse found "http"
															if found [
																txt: either e: find found brc2 [copy/part found e][copy found]
																mark-found/with face found txt
															]
															not found
														]
													]
													any [
														all [
															not all?/data
															all [
																found: find/reverse found "http"
																txt: either e: find found brc2 [copy/part found e][copy found]
																mark-found/with face found txt
																;browse to-url txt
																;true
															]
														]
														sm > max-y
														head? lns
													]
												]
											][
												
											]
										]
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
									either object? :target [
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
									act: compose/deep case [
										object? :target [[
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
										]]
										string? :target [[term/refresh]]
										;[[system/view/auto-sync?: off foreach win term/windows [probe win/pane/1/text show win] system/view/auto-sync?: on]];
										true [[
											loaded: load face/text
											attempt/safer [(def) either block? loaded [compose loaded][:loaded]]
											term/refresh
										]]
									]
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
								;system/view/auto-sync?: off
								gui-console-ctx/console/actors/on-scroll: func [face [object!] event [event!]] bind bind [
									terminal/scroll event
									rt/actors/scroll rt event
								] gui-console-ctx helper-ctx
								gui-console-ctx/console/actors/on-wheel: func [face [object!] event [event!]] bind bind [
									either event/ctrl? [
										terminal/zoom event
									] [
										terminal/scroll event
										rt/actors/scroll rt event
									]
								] gui-console-ctx helper-ctx
								add-layer bind compose [
									at 3x0 rt: rich-text 252.252.240 options [tool: helper] draw []
									wrap all-over with [
										text: concat copy/part at term/lines curtop: term/top tail term/lines newline ;screen-cnt
										size: as-pair window/size/x - 20 term/line-y;window/size - 20 
										font: gui-console-ctx/font
										data: reduce [1x0 'backdrop silver]
										menu: [
											"Set context"     set-context 
											"Forget contexts" global-context
											"Watch"           watch
											"Evaluate"        evaluate
										]
										actors: object [
											fix: start: strt: expr-end: expr-len: start-idx: end-idx: fixed-len: wrd: src: block: cur-word: watch?: none
											contexts: clear [] indexes: clear [] path: clear [] current: clear [] n: 0
											on-over: func [face event /local end txt ret len new-text pos diff][
												all [
													event/away? 
													;any [fix not empty? indexes]
													rt/offset/y > 0
													curtop: diff: rt/offset/y / term/line-h
													attempt [new-text: concat copy/part at term/lines term/top diff newline]
													len: 1 + length? new-text
													renew-text face event
													case [
														fix [
															change face/data as-pair start-idx + len fixed-len
															start: at face/text face/data/1/x
															expr-end: scope start true
														]
														not empty? indexes [
															forall indexes [if integer? indexes/1 [indexes/1: indexes/1 + len]]
														]
													]
													show rt
												]
												either fix [
													either event/down? [ ;Prolong selection 
														end: any [find at face/text offset-to-caret rt event/offset wspar tail start]
														if last-word <> end-idx: index? end [
															;if attempt/safer [loaded: load copy/part start end][
																change face/data as-pair start-idx: index? start end-idx - start-idx
																last-word: end-idx
															;]
														]
													][
														strt: any [
															find/tail/reverse at event/face/text offset-to-caret event/face event/offset wspar 
															head event/face/text
														]
														if last-word <> idx: index? strt [
															if all [indexes found: find/tail indexes idx][
																sidx: first found 
																report :sidx at face/text idx true;false
															]
															last-word: idx
														]
													]
												][
													pos: offset-to-caret event/face event/offset
													if attempt [scanned: scan/next at face/text pos][
														either all [scanned find reduce [map! paren! block! hash!] first scanned] [
															start: at face/text pos
															end: second scanned
														][
															start: any [
																find/tail/reverse at face/text pos wspar 
																head face/text
															]
															end: any [all [is-string? start end-of-string start] find start wspar tail start] 
														]
														attempt/safer [txt: copy/part start (index? end) - (index? start)]
														;if not all [find/match ["==" ">>"] txt txt/-1 = newline][
														;	probe copy/part skip txt -2 5
															change face/data as-pair start-idx: index? start expr-len: (index? end) - start-idx
															if last-word <> face/data/1 [
																face/data/3: silver
																clear at face/data 4
																clear at face/draw 3
																either all [indexes found: find/tail indexes index? start][ 
																	sidx: first found 
																	report :sidx start true;false
																][
																	all [
																		attempt/safer [wrd: load txt]
																		report :wrd start true
																	]
																]
																last-word: first face/data
															]
														;]
													]
												]
											]
											on-wheel: func [face event][
												gui-console-ctx/console/actors/on-wheel gui-console-ctx/console event
												;scroll face event
											]
											scroll: func [face event][
												either any [fix not empty? contexts] [
													if 0 <> diff: curtop - term/top [
														face/offset/y: to integer! face/offset/y + (diff * term/line-h)
														curtop: term/top
													]
												][
													renew-text face event
												]
											]
											on-down: func [face event][hlp-txt/color: either fix: not fix [fixed-len: face/data/1/y silver][snow]]
											on-up: func [face event][]
											on-dbl-click: func [face event][
												add-note select first select pick helper-tab/pane helper-tab/selected 'pane 'text
											]
											on-menu: func [face event /local code n s][
												fix: yes 
												hlp-txt/color: silver 
												fixed-len: face/data/1/y
												switch event/picked [
													set-context [
														either set-word? wrd [
															register wrd 
															mark-context wrd
														][]
													]
													global-context [
														clear indexes
														clear contexts
													]
													watch [
														either set-word? wrd [
															helper-tab/selected: 2
															clear watch/text
															register/watch wrd
															foreach entry look/data [
																if attempt [val: get/any :entry][
																	append watch/text rejoin [form entry ": " mold val newline]
																]
															]
														][]
													]
													evaluate [
														len: max fixed-len (index? expr-end) - (index? start)
														parse code: copy/part start len [some [remove [newline [console-prompt | console-result]] | skip]]
														if attempt [code: load/all code] [
															inspector/text: mold do bind code console-ctx
															if watching? [
																clear watch/text
																foreach entry look/data [
																	if attempt [val: get/any :entry][
																		append watch/text rejoin [form entry ": " mold val newline]
																	]
																]
															]
														]
													]
												]
												'done
											]
											renew-text: func [face event /diff][
												if 0 <> diff: curtop - term/top [
													clear at face/data 4 face/data/1: 0x0 clear at face/draw 3
													append clear face/text concat copy/part at term/lines curtop: term/top tail term/lines newline ;screen-cnt
													face/offset: 3x0
													switch event/type [;as-pair window/size/x - 20 
														wheel scroll [face/size/y: term/line-y + (diff * term/line-h)]
														over [face/size/y: term/line-y]
													]
												]
											]
											report: func ['wrd start render /local ctx ret in-ctx][
												all [
													any [fn: info :wrd set-word? :wrd set-path? :wrd]
													expr-end: scope start render
													expr-len: (index? expr-end) - (index? start)
												]
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
													;probe reduce ["wrd:" wrd]
													;this: :wrd
													inspector/text: copy/part help-string :wrd 2000
												]
											]
											register: func [wrd /watch /local loaded n s blk][
												if watch?: watch [watching?: yes]
												expr-len: (index? expr-end) - (index? start)
												unless watch? [ 
													append contexts reduce [
														to word! wrd 
														as-pair index? start expr-len
																
													]
												]
												do loaded: load/all copy/part start expr-len
												block: find find start ws nonws 
												src: copy/part block expr-end
												cur-word: to word! wrd
												transcode/trace src :lex
												clear path
												;probe indexes
											]
											lex: func [e i t l o /local pth ret][
												[scan open close]
												switch e [
													scan [
														switch/default t [
															#[set-word!][
																cur-word: load copy/part at src o/1 o/2 - o/1 - 1
																pth: to path! append copy path cur-word
																either watch? [
																	append look/text rejoin [form pth space]
																][
																	repend indexes [(index? block) + o/1 - 1 pth]
																]
															]
															#[word!][
																switch/default copy/part at src o/1 o/2 - o/1 [
																	"object" "context" [
																		i: find/tail at src o/2 #"[" 
																		append path cur-word
																		insert current 'object
																	]
																	"make" []
																	"func" "function" "has" []
																	"does" []
																	"is" [
																		i: find at src o/2 #"["
																		i: second scan/next i
																	]
																][
																	if current/1 = 'block [
																		pth: to path! append copy path n: n + 1
																		either watch? [
																			append look/text rejoin [form pth space]
																		][
																			repend indexes [(index? block) + o/1 - 1 pth]
																		]
																	]
																]
															]
														][
															if current/1 = 'block [
																pth: to path! append copy path n: n + 1
																either watch? [
																	append look/text rejoin [form pth space]
																][
																	repend indexes [(index? block) + o/1 - 1 pth]
																]
															]
														]
														return no
													]
													open [
														switch t [
															#[string!] []
															#[block!] #[hash!] [
																append path either 'block = first current [n][cur-word] 
																insert current 'block 
																n: 0
															]
															#[map!] [
																append path either 'block = first current [n][cur-word] 
																insert current 'map
															]
														]
														return yes
													]
													close [
														remove back tail path 
														ret: either 'object = first current [no][yes]
														remove current
														return ret
													]
												]
											]
											mark-context: func [wrd /local found end maxpos last-idx end-point][
												either found: find/tail/part start newline expr-end[
													maxpos: (index? found) - 1 - (index? start)
													end: caret-to-offset rt (index? start) + maxpos
													end-point: caret-to-offset rt index? expr-end
													until [
														last-idx: index? found 
														either found: find/tail/part found newline expr-end [
															if maxpos < (pos: (index? found) - 1 - last-idx) [
																end: caret-to-offset rt (index? found) - 1
																maxpos: pos
															]
														][
															if  (index? expr-end) - last-idx > maxpos [
																end: end-point
															]
														]
														not found
													]
													end: as-pair end/x end-point/y
												][
													end: caret-to-offset rt contexts/:wrd/1 + contexts/:wrd/2
												]
												repend rt/draw ['box caret-to-offset rt contexts/:wrd/1 end + term/line-h]
											]
										]
									] react [face/size/x: window/size/x - 20]
									
									;Fireworks!
									;at 0x0 i: image (helper-ctx/draw_screen) options [tool: helper]
									;rate 32
									;on-time [
									;	update period
									;	i/image: draw_screen
									;	show i
									;	if 1 = random 30 [
									;		explode random window/size - 20x0 speed
									;	]
									;]
								] helper-ctx
								add-tool bind [
									panel options [tool: helper] [
										hlp-txt: text "Helper" 60
										button "Console" [focus-console]
										button "Note"    [add-note select first select pick helper-tab/pane helper-tab/selected 'pane 'text]
										button "Close"   [system/view/silent?: no close-tool face/parent]
										return
										check "Show" 60 data #[true] on-change [if rt/visible?: face/data [
											clear at rt/data 4
											rt/data/1: 0x0
											append clear rt/text concat copy/part at term/lines term/top term/screen-cnt newline
										]]
										style: drop-list data ["backdrop" backdrop "line" line "hybrid" hybrid "text" text] select 1
										on-change [
											switch face/selected [
												1 [;backdrop
													clear face/draw
													colors: load %Pastel2.png
													cfg: colors/size/x / 8
												]
												2 3 [;line/hybrid
													lh: as-pair 0 term/line-h
													append rt/draw [line-width 2]
													colors: load %Category10.png
													cfg: colors/size/x / 10
												]
												4 [;text
													clear face/draw
													colors: load %Category10.png
													cfg: colors/size/x / 10
												]
											]
										]
										on-created [
											face/actors/on-change face none
										]
										return
										helper-tab: tab-panel 280x420 [
											"inspect" [
												inspector: box 260x400 top left wrap font tool-font
												react [face/parent/size: tools/size - 40 face/size: face/parent/size]
											]
											"watch" [
												below
												look: field 260 ""
												watch: box 260x300 top left wrap font tool-font ""
												react [
													face/parent/size: tools/size - 40 
													look/size/x: face/size/x: face/parent/size/x 
													face/size/y: face/parent/size/y - face/offset/y
												]
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
											switch pick face/data event/picked [
												"inspect" [
													system/view/silent?: yes
													rt/text: concat copy/part at term/lines term/top term/screen-cnt newline
													rt/size: as-pair window/size/x - 20 pick size-text rt 2
													rt/visible?: yes
													watching?: no
												] 
												"watch" [
													watching?: yes
													rt/visible?: yes
												]
												"keys" [
													system/view/silent?: no
													rt/visible?: no
													watching?: no
												]
											]
										]
										at 10x0 separator 280x10 loose 
											react [
												face/offset/y: face/parent/size/y - 10
												face/size/x: tools/size/x - 20
												face/extra/mark/1/x: to integer! face/size/x / 2 - 10
												face/extra/mark/2/x: face/extra/mark/1/x + 20
											]
									]
								] helper-ctx
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
		add-note probe concat reverse copy lines newline
		;foreach line lines [add-note line]
	]
	
	set 'replay function [act /to stop][
		case [
			integer? act [
				foreach line reverse copy/part next cons/history act [
					do line
				]
			]
			issue? act [
				foreach line reverse copy/part either to [
					find/tail cons/history stop
				][
					next cons/history
				] find cons/history mold act [
					do line
				]
			]
		]
	]
	
	;;Don't mess with history :)
	;remove-lines: function [lines][
	;	foreach line lines [remove find cons/history line]
	;]
	
	;Call tools
	set 'note     func [act /to stop][
		case [
			act = 'last  [add-note second cons/history]
			integer? act [foreach line reverse copy/part next cons/history act [add-note line]]
			issue? act   [
				foreach line reverse copy/part either to [
					find/tail cons/history stop
				][
					next cons/history
				] find/tail cons/history mold act [
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
	set 'live     func [what] [console/with add 'live :what]
	set 'reminder does [console add 'reminder]
	set 'remind   func [spec [block!]] [write %reminds.txt new-line/all/skip sort/skip append reminds/tasks spec 2 true 2]
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
	
] ()