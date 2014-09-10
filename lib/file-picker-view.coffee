{$, View} = require 'atom'

module.exports =
class FilePickerView extends View
  
  @content: ->
    @div class:'vtlf-file-picker overlay from-top', \
         style: 'position:absolute; tabindex: -1; margin:0', =>
  
  initialize: ->
    wsv = atom.workspaceView
    ww     = wsv.width()
    wh     = wsv.height()
    width  = 600
    height = wh - 200
    left   = (ww - width)/2
    top    = 80
    @css {left, top, width, height}
    console.log 'initialize',  {ww, wh, left, top, width, height}
    wsv.append @
    
    @click => @destroy()
      
  destroy: -> @detach()
