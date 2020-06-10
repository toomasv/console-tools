# console-tools
Suite of in-console tools

`do %console.red`

Simple figures:
```
circle
ellipse
square
rectangle
box
arrow
```

Also you can add any face with `console add <block of VID>`.

Other tools:
```
notes        ;take quick notes while playing (try `note 'last | note <int>` or enter issue(s) as marker(s) and then `note/to #start #end` )
finder       ;find words and draw on screen, capture into %screenshot.png
live <lit-word or lit-path> ;live editing experiment
reminder     ;experiments with reminder
history      ;quick selection from console's history (with contextual menu) into notes or caret (click)
define       ;adaptation of @rebolek's `what`
helper       ;Cosole hot-keys only so far
styles       ;play wit console styling options
```

There are some default settings that can influence things and which you can change with following:
```
console defaults [some [
  'sources file! ;for `define`
| 'tool-font [
    integer!     ;font-size
    | string!    ;font-name
    | word!      ;font-style
    | block!     ;font-spec
    ]
| 'toolbox integer! ;toolbox's width

;Figure's default attributes
| 'bounding-box ['large | 'small] ;large - transparent face-box is window-size; small - box is 100x100
| 'fill-pen   <color>
| 'pen        <color>
| 'line-width integer!
| 'rotate [pair! integer! | pair! | integer!] ;rotation center and angle
| 'scale [
    integer! integer!  ;separately x and y scale
    | 'x integer!      ;only x
    | 'y integer!      ;only y
    | integer!         ;same scale for both
    ]
| 'skew [
    integer! integer! ;Same as for scale
    | 'x integer!
    | 'y integer! 
    | integer! 
    ]
| 'translate [
    pair!             ;Similar to scale
    | 'x integer!
    | 'y integer!
    | integer!
    ]
]]
```
E.g. `console defaults [bounding-box large fill-pen red]`
