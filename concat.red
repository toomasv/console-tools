Red [
	Author: "Toomas Vooglaid"
	Date: 2018-08-04
	Last: 2018-10-20
	Purpose: "Concatenating any-strings with provided delimiter"
]
concat: function [
	arg1 [any-string! any-block!] 
	arg2 [series! any-word! any-path! char!] 
	/with 
		dlm [char! string! block!]
	/last
][
	; In case we are concatenating block
	if all [any-block? arg1 not with][
		set [arg1 arg2 dlm] reduce [copy to-string first arg1 next arg1 arg2]
	]
	; Always concatenating to first any-string (string!, url!, email!, tag!, file!)
	if not any-string? arg1 [arg1: form arg1]
	; Nothing to concatenate
	if empty? arg2 [return arg1]
	dlm: any [dlm space] 
	cycle: no
	total: limit: count: cyc-count: last-counted: 0
	; at least 1 element in arg2 
	either any-block? arg2 [
		repeat i length? arg2 [
			k: i - total - count
			; Add delimiter
			append arg1 case [
				; We are in cycle
				cycle [
					k: j
					if limit > 0 [count: count + 1]
					cycle: cycle % cyc-len + 1 
					cyc-dlm/:cycle
				]
				; Complex delimiter
				block? dlm [
					case/all [
						all [limit > 0 count = limit][
							total: total + limit - 1 
							last-counted: k
							k: k + 1 
							limit: count: 0
						]
						integer? dlm/:k [limit: take at dlm k]
						count < limit [count: count + 1]
					]
					case [
						; Cycling delimiter
						block? dlm/:k [
							either all [1 = length? arg2 last] [
								; In case we have only one element to concatenate, 
								; use last delimiter if forced
								system/words/last dlm
							][
								j: k
								cyc-dlm: dlm/:k 
								cyc-len: length? cyc-dlm 
								cyc-dlm/(cycle: 1)
							]
						]
						; Simple delimiter
						dlm/:k [dlm/:k]
						'else [either last-counted = length? dlm [space][system/words/last dlm]]
					]
				]
				'else [dlm]
			]
			if cycle [
				case/all [
					all [limit = 0 k < length? dlm][
						nums: parse at dlm k + 1 [
							collect some [
								integer! s: [
									if (block? s/1) keep (s/-1 * length? s/1) 
								| 	keep (s/-1)
								] skip 
							| 	block! s: keep (length? s/-1) 
							| 	skip keep (1)
							]
						]
						sum: 0
						foreach n nums [sum: sum + n]
						limit: (length? arg2) - i - sum + 1 / cyc-len
					]
					limit > 0 [
						case/all [
							cycle = cyc-len [cyc-count: cyc-count + 1]
							cyc-count = limit [
								total: total + (limit * cyc-len) - 1
								last-counted: k
								limit: count: cyc-count: 0
								cycle: no
							]
						]
					]
				]
			]
			; Add next arg
			append arg1 arg2/:i
		]
	][	; arg2 is not block
		rejoin [arg1 dlm arg2]
	]
]
comment [
concat "Niccolò" "Paganini"
;== "Niccolò Paganini"

concat "Pippilotta" ["Delicatessa" "Windowshade" "Mackrelmint" "Ephraim's Daughter" "Longstocking"]
;== {Pippilotta Delicatessa Windowshade Mackrelmint Ephraim's Daughter Longstocking}

concat/with "other" [than reality based] "-"
;== "other-than-reality-based"

concat/with "behold" [-of -equal -lists][-mixing -two -sized]
;== "behold-mixing-of-two-equal-sized-lists"

concat/with <p> ["class" {"pretty"}][" " "="]
;== <p class="pretty">

concat/with concat/with %/C [Users Toomas Documents Red utils] "/" [concat red] [/ .]
;== %/C/Users/Toomas/Documents/Red/utils/concat.red

concat/with to-url 'https [github com red red search]["://" . /]
;== https://github.com/red/red/search

browse concat/with https://github.com/red/red/search [o desc q FEAT s committer-date type Commits][? = [& =]]

concat "a" [b c d e f g h i j k l m]
;== "a b c d e f g h i j k l m"

concat/with "a" [b c d e f g h i j k l m] "."
;== "a.b.c.d.e.f.g.h.i.j.k.l.m"

concat/with "a" [b c d e f g h i j k l m] "->"
;== "a->b->c->d->e->f->g->h->i->j->k->l->m"

concat/with "a" [b c d e f g h i j k l m] ["->" "->" "->" ":" ":" " "]
;== "a->b->c->d:e:f g h i j k l m"

concat/with "a" [b c d e f g h i j k l m] [3 "->" 2 "."]
;== "a->b->c->d.e.f g h i j k l m"

concat/with "a" [b c d e f g h i j k l m n] [["->" " "]]
;== "a->b c->d e->f g->h i->j k->l m->n"

concat/with "a" [b c d e f g h i j k l m n] [3 ["->" " "]]
;== "a->b c->d e->f g h i j k l m n"

concat/with "a" [b c d e f g h i j k l m n] [3 [-> " "] [= " "]]
;== "a->b c->d e->f g=h i=j k=l m=n"

concat/with "a" [b c d e f g h i j k l m n] [3 ["->" " "] 2 [= " "]]
;== "a->b c->d e->f g=h i=j k l m n"

concat/with "a" [b c d e f g h i j k l m n] [3 "->" 2 [= " "]]
;== "a->b->c->d=e f=g h i j k l m n"

concat/with "a" [b c d e f g h i j k l m n] [3 "->" 2 =]
;== "a->b->c->d=e=f g h i j k l m n"

concat/with "a" [b c d e f g h i j k l m n] [3 "->" =]
;== "a->b->c->d=e=f=g=h=i=j=k=l=m=n"

concat/with "a" [b c d e f g h i j k l m n] [3 "->" 1 =]
;== "a->b->c->d=e f g h i j k l m n"

concat/with "a" [b c d e f g h i j k l m n] [[", "] " and "]
;== "a, b, c, d, e, f, g, h, i, j, k, l, m and n"

concat [a b c d] " "
;== "a b c d"

concat [a b c d] [[", "] " and "]
;== "a, b, c and d"
]

