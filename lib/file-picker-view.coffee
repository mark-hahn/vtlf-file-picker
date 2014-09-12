{$, View, EditorView} = require 'atom'
fs = require 'fs-plus'

filePickerCSS = """
.vtlf-file-picker {position:absolute; margin:0}
  .btn-group.left {width: 50px; margin-left: 5px}
    .btn-group .btn.left {width: 80%; tabindex:7}
  .btn-group.right {width: 120px; margin-left: 8px}
    .btn-group .btn.right {width: 45%}
  .vtlf-container {display: -webkit-flex; -webkit-flex-direction: row; }
    .vtlf-container .editor-container {position: relative; -webkit-flex: 1}
      .vtlf-container .editor {width: 100%}
    .vtlf-container .file-picker-side {position:relative; top:-10px; 
        margin-left:3px; margin-right:15px}
      .vtlf-container .column {
          background-color:rgba(128, 128, 128, 0.2);
          width:180px; overflow:auto}
        .vtlf-container .column-inner {width:178px}
        .vtlf-container .column-inner .list-group {
          font-size:14px; margin-left:8px}
  .focused {border:1px solid gray}
"""

module.exports =
class FilePickerView extends View
  
	@remove = -> 
    if ($picker = atom.workspaceView.find '.vtlf-file-picker').length > 0
      $picker.view().destroy()
      true
      
  @content: ->
    @div class:'vtlf-file-picker vtlf-form overlay from-top', tabindex:"-1", =>
           
      @style filePickerCSS
           
      @div class: 'block', =>
        @span class: 'description', 'View-Tail-Large-Files: Open Any File'

      @div class: "file-path vtlf-container block", =>
        
        @div class: 'btn-group-vtlf btn-group left', =>
          @button outlet: 'bsButton', \
                   class: 'inline-block btn left', '^ BS'
                     
        @div class: "editor-container", =>
          @subview "filePath focusable", new EditorView
            mini: true
            placeholderText: "Absolute path to file"

        @div class: 'btn-group-vtlf btn-group right', =>
          @button outlet: 'openButton', \
                   class: 'inline-block btn right', 'Open'
          @button outlet: 'cancelButton', \
                   class: 'inline-block btn right', 'Cancel'
                     
      @div class:"file-picker-bottom vtlf-container block", =>
        
        @div class:"file-picker-side inline-block", =>
          @span class: 'description', 'Directories  (Backspace For Parent)'
          @div outlet: 'dirs', class: 'column focusable focused', =>
            @div class: 'column-inner', =>
              @ul class: 'list-group dirs', =>
                # @li class: 'list-item highlight', 'Normal item'       
                         
        @div class:"file-picker-side inline-block", =>
          @span class: 'description', 'Files In Directory'
          @div outlet: 'files', class: 'column focusable', =>
            @div class: 'column-inner', =>
              @ul class: 'list-group files', =>
                  
        @div class:"file-picker-side inline-block", =>
          @span class: 'description', 'Recent Files'
          @div outlet: 'recent', class: 'column focusable', =>
            @div class: 'column-inner', =>
              @ul class: 'list-group recent', =>
                           
  initialize: (@state, @FilePicker) ->
    wsv    = atom.workspaceView
    ww     = wsv.width();     wh     = wsv.height()
    width  = 600;             height = Math.max 200, wh - 170
    left   = (ww - width)/2;  top    = 80
    @css {left, top, width, height}
    @find('.column').height height - 100
    wsv.append @
    
    @$editor     = @find '.editor'
    @$focusable  = @find '.focusable'
    @editorView  = @$editor.view()
    
    @handleEvents()
    @$editor.focus()
    @colFocused = 'dirs'
    
    if @state.colFocused then @focusCol @state.colFocused 
    
  focusCol: (col) ->
    @$focusable.removeClass 'focused'
    switch col
      when 'dirs'   then @dirs.addClass   'focused'
      when 'files'  then @files.addClass  'focused'
      when 'recent' then @recent.addClass 'focused'
    @state.colFocused = @colFocused = col
    
  focusNext: (fwd) -> 
    switch @colFocused
      when 'dirs'   then (if fwd then @focusCol('files')  else @focusCol('recent'))
      when 'files'  then (if fwd then @focusCol('recent') else @focusCol('dirs'))
      when 'recent' then (if fwd then @focusCol('dirs')   else @focusCol('files'))
    
  handleEvents: ->
    atom.workspaceView.on 'core:cancel core:close', => @destroy()
    atom.workspaceView.on 'core:confirm',           => @open()
    @on 'view-tail-large-files:focus-next',         => @focusNext yes
    @on 'view-tail-large-files:focus-previous',     => @focusNext no
    
    @cancelButton.on 'click', => @destroy()
    @openButton.on   'click', => @open()
      
  open: ->
    filePath = @editorView.getText()
    filePath = 'c:\\apps\\insteon\\data\\hvac.log'   # debug
    
    if not fs.existsSync filePath
      atom.confirm
        message: 'View-Tail-Large-Files Error:\n\n'
        detailedMessage: 'File ' + filePath + ' doesn\'t exist.'
        buttons: ['Close']
      return

    @destroy()
    @FilePicker.open filePath
    
  destroy: -> @detach()

    
