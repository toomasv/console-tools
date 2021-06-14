Red []
;info-ctx: context [
	get-function: function [path][
		if path? path [
			path: copy path 
			while [
				not any [
					tail? path 
					any-function? attempt [get/any either last? path [path/1][path]] ;1 = length?
				]
			][
				clear back tail path
			] 
			return either empty? path [none][path]
		] none
	]
	info: func ['fn	/local intr ars refs locs ret arg ref typ irefs rargs rf fnc][
		intr: copy "" ars: make block! 10 refs: make block! 20 locs: copy [] ret: copy [] irefs: copy [] typ: ref-arg: ref-arg-type: none
		;if path? fn [irefs: copy next to-block fn fn: first fn]
		if path? fn [
			either fnc: get-function fn [
				irefs: copy skip fn: to-block fn length? fnc 
				either 1 = length? fnc [fn: fn/1][fn: fnc]
			][return none]
		]
		if lit-word? fn [fn: to-word fn]
		unless all [value? fn any [word? fn path? fn] any-function? get fn] [
			return none;cause-error 'user 'message ["Only function types accepted for `info`!"]
		]
		out: make map! copy []
		specs: spec-of get fn 
		parse specs [
			opt [set intr string!]
			any [set arg [word! | lit-word! | get-word!] 
				opt [set typ block!] 
				opt string! (
					put ars arg either typ [typ][[any-type!]]
				)
			]
			any [set ref refinement! [
				if (ref <> /local) (put refs r: to-word ref make block! 10) 
					opt string! 
					any [set ref-arg [word! | lit-word! | get-word!] opt [set ref-arg-type block!]
						(put refs/:r ref-arg either ref-arg-type [ref-arg-type][[any-type!]])
					]
					opt string!
				|	any [set loc word! (append locs loc) opt string!] 
					opt [set-word! set ret block!]
			]]
		]
		rargs: extract ars 2
		foreach rf irefs [append rargs extract refs/:rf 2]
		
		make object!  [
			name: 		either path? fn [last fn][to-word fn]
			intro: 		intr 
			args: 		ars 
			refinements: refs 
			runtime-refs: irefs
			locals: 	locs 
			return: 	ret 
			spec: 		specs 
			type: 		type? get fn
			arg-num: 	length? args
			arg-names: 	extract args 2
			arg-types: 	extract next args 2
			ref-names: 	extract refinements 2
			ref-types: 	extract next refinements 2
			ref-num:	(length? refinements) / 2
			runtime-args: rargs
			arity:		(length? runtime-args) / 2
		]
	]
;]