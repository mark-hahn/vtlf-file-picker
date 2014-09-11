{$, View, EditorView} = require 'atom'

module.exports =
class FilePickerView extends View
  
  @content: ->
    @div class:'vtlf-file-picker overlay from-top', \
         style: 'position:absolute; margin:0', tabindex:"-1", =>
           
      @div class: "file-path vtlf-container block", =>
        @div class: "editor-container", =>
          @subview "filePath", new EditorView
            tabindex:"1"
            mini: true
            placeholderText: "Absolute path to file."

        @div class: 'btn-group-vtlf btn-group', =>
          @button outlet: 'cancelButton', tabindex:"2", class: 'btn', 'Cancel'
          @button outlet: 'openButton',   tabindex:"3", class: 'btn', 'Open'
            
  initialize: (@FilePicker) ->
    @handleEvents()
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
    
  handleEvents: ->
    atom.workspaceView.on 'core:cancel core:close', => @destroy()
    @cancelButton.on 'click', => @destroy()
    @openButton.on 'click',   => @open()
      
  open: ->
    @destroy()
    @FilePicker.open 'c:\\apps\\insteon\\data\\hvac.log'   # debug

  destroy: -> @detach()

    
