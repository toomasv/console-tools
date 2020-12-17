Red [
	Description: "Show values of intermediate expressions in console"
	Date: 12-Jun-2020
]

term: gui-console-ctx/terminal

show: function [][
	out2: copy [] out: pos: copy [] 
	found: find/tail term/line "show " 
	loaded: copy reverse load found 
	foreach l loaded [
		either any [all [word? l any-function? get l] all [path? l any-function? get first l]] [ ;Doesn't handle op!s
			insert/only out2 done: do/next compose [(l) (out)] 'pos 
			insert/only out2 l 
			change/part/only out done either tail? pos [tail out][find/reverse tail out pos]
		][insert/only out l]
	] 
	print sync head found out2
]

sync: func [line result /local out i j][
	out: copy "" 
	j: 0 
	found: line
	foreach [token value] result [
		found: find next found form token 
		if j >= i: index? found [
			found: insert/dup found space j - i + 1 
			i: j + 1
		] 
		append/dup out space i - 1 - length? out 
		append out mold value 
		j: (length? out) + 2
	]
	out
]
;Examples
comment {
blk: [a b c 1 + 3]()
show add first back find blk '+ first next find blk '+

blk: [a 2 b 3 c 4]()
show power add first next find blk 'b last blk pick blk first next blk

blk: [a 2 b 3 c 4]()
show power add blk/b blk/c blk/a
}