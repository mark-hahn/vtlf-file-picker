{$, View, EditorView} = require 'atom'

fs    = require 'fs-plus'
path  = require 'path'
_     = require "underscore"
_.mixin require('underscore.string').exports()

rootDrives = null
winDrives  = 'cdefghijklmnopqrstuvwxyz'

filePickerCSS = """
.vtlf-file-picker {position:absolute; margin:0}

  .btn-group.left {width: 50px; margin-left: 5px}
  
    .btn-group .btn.left {width: 80%; tabindex:7}
    
  .btn-group.right {width: 120px; margin-left: 8px}
  
    .btn-group .btn.right {width: 45%}
    
  .vtlf-container {display: -webkit-flex; -webkit-flex-direction: row; }
  
    .vtlf-container .editor-container {position: relative; -webkit-flex: 1}
    
      .vtlf-container .editor {width: 100%}
      
      .vtlf-cover {position:absolute; width:100%; height:100%; background-color:red; opacity:0.2}
      
    .vtlf-container .column-vertical {position:relative; top:-10px; 
        margin-left:3px; margin-right:15px}
        
      .vtlf-container .column {
          background-color:rgba(128, 128, 128, 0.2); position:relative;
          width:180px; overflow:auto}
          
        .vtlf-container .column-inner {width:160px; position:relative}
        
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
                   class: 'inline-block btn left', 'Up'
                     
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
        
        @div class:"column-vertical inline-block", =>
          @span class: 'description', 'Directories  (Ctrl-Up for Parent)'
          @div outlet: 'dirs', class: 'column focusable focused', =>
            @div class: 'column-inner', =>
              @ul outlet: 'dirsUl', class: 'list-group dirs', =>
                # @li class: 'list-item highlight', 'Normal item'       
                         
        @div class:"column-vertical inline-block", =>
          @span class: 'description', 'Files'
          @div outlet: 'files', class: 'column focusable', =>
            @div class: 'column-inner', =>
              @ul outlet: 'filesUl', class: 'list-group files', =>
                  
        @div class:"column-vertical inline-block", =>
          @span class: 'description', 'Recent Files'
          @div outlet: 'recent', class: 'column focusable', =>
            @div class: 'column-inner', =>
              @ul outlet: 'recentUl', class: 'list-group recent', =>
                           
  initialize: (@state, @FilePicker) ->
    wsv   = atom.workspaceView
    ww    = wsv.width();     wh     = wsv.height()
    width = 600;             height = Math.max 200, wh - 170
    left  = (ww - width)/2;  top    = 80
    $col  = @find '.column'
    @css {left, top, width, height}
    $col.height height - 100
    wsv.append @
    
    @$editor     = @find '.editor'
    @$focusable  = @find '.focusable'
    @editorView  = @$editor.view()
    
    @handleEvents()
    @$editor.focus()

    @state.curPath      ?= ''
    @state.prevSelDirs  ?= {}
    @state.prevSelFiles ?= {}
    @state.colFocused   ?= 'dirs'
    
    @focusCol @state.colFocused
    
    if process.platform isnt 'win32'
      rootDrives = ['/']
    else
      if not rootDrives
        rootDrives = []
        for driveLetter in winDrives
          drive = driveLetter + ':\\'
          if fs.isDirectorySync drive
            rootDrives.push drive
      rootDrives[0]  ?= 'c:\\'
      
    # console.log 'init state', state, rootDrives
      
    @editorView.setText @state.curPath
    @setAllFromPath()
      
  setLIs: ($ul, list) ->
    $ul.empty()
    for str in list
      $('<li/>').text(str).appendTo $ul

  setAllFromPath: ->
    # console.log 'setAllFromPath enter @dir',  @dir
    
    oldDir = @dir
    
    @state.curPath = @editorView.getText()
    
    if /^\.+$/.test @state.curPath
      @editorView.setText (@state.curPath = '')

    curPath = _.trim @state.curPath
    if process.platform is 'win32' 
      curPath = curPath.toLowerCase()
      curPath.replace /\//g, '\\'
    else 
      curPath = curPath.replace /\\/g, '/'
      
    @dir  = ''
    @file = ''
    dirs  = []
    files = []
    
    if curPath is '' 
      @dir = @file = ''
      dirs = rootDrives
    else
      if fs.isFileSync curPath then @dir= path.dirname (@file = curPath)
      else if fs.isDirectorySync curPath then @dir = curPath; @file = ''
      else
        lastPath = null
        parentPath = curPath
        while parentPath isnt lastPath and not fs.isDirectorySync parentPath
          lastPath = parentPath
          parentPath = path.normalize parentPath + '/..'
        @dir  = parentPath
        @file = ''
        
    if not (hasPath = /\\|\//.test @dir)
      @dir = @file = ''
      dirs = rootDrives
    else
      for dirOrFile in fs.listSync @dir
        basename = path.basename dirOrFile
        if fs.isDirectorySync dirOrFile then dirs.push basename else files.push basename
        
    if @dir isnt oldDir then @focusCol 'dirs'
    
    $under = @.find '.highlights.underlayer'
    if not ($vtlfCover = $under.next()).hasClass 'vtlf-cover'
      $under.after ($vtlfCover = $ '<div class="vtlf-cover"/>')
        
    if hasPath and (fs.isFileSync(curPath) or fs.isDirectorySync(curPath))
      $vtlfCover.hide()
    else
      $editorText = @.find 'span.text'
      if (dirOrFile = (@file or @dir))
        $editorText.after \
            ($textClone = $editorText.clone().css(visibility:'none').text(dirOrFile))
        dirOrFileWidth = $textClone.width()
        $textClone.remove()
      else 
        dirOrFileWidth = 0
      editWid = (if curPath then $editorText.width() else 0)
      $vtlfCover.css display:'block', left: dirOrFileWidth, width: editWid - dirOrFileWidth
    
    @setLIs @dirsUl,  dirs
    if not((dir = @state.prevSelDirs[@dir.length]) and @setHighlight @dirsUl, dir)
      @setHighlight @dirsUl, @dirsUl.children().eq(0).text()
      
    @setLIs @filesUl, files
    if not((file = @state.prevSelFiles[@dir.length]) and @setHighlight @filesUl, file)
      @setHighlight @filesUl, @filesUl.children().eq(0).text()

    @$editor.focus()
    
  setPath: (path) ->
    # console.log 'setPath', path
    @editorView.setText path
    @setAllFromPath()
    
  goToParent: ->
    @focusCol 'dirs'
    if @dir.length is 0 then return
    if @state.curPath.length <= @dir.length  
      oldDir = @dir
      @dir = path.normalize @dir + '/..'
      if @dir is oldDir then @dir = ''
      # console.log 'goToParent @dir',  @dir
    @setPath @dir
    
  openDir: (dir) -> 
    # console.log 'openDir', dir
    @setPath (if /^[c-z]:\\$/.test dir then dir else path.join @dir, dir)
    @focusCol 'dirs'	 
    
  colClick: (e) ->
    if ($tgt = $(e.target).closest 'li').length is 0 then return
    $ul = $tgt.closest 'ul'
    switch
      when $ul.hasClass 'dirs'  then @openDir  $tgt.text()
      when $ul.hasClass 'files' then @openFile $tgt.text()
      
  liMetrics: ($li) ->
    $inner      = $li.closest '.column-inner'
    $outer      = $inner.parent()
    outerHeight = $outer.height()
    scrollTop   = $outer.scrollTop()
    scrollBot   = scrollTop + outerHeight - 15
    liTop       = $li.position().top
    liBot       = liTop + $li.height()
    {$inner, $outer, outerHeight, liTop, liBot, scrollTop, scrollBot}

  ensureLiVisible: ($li) ->
    {$outer, outerHeight, liTop, liBot, scrollTop, scrollBot} = @liMetrics $li
    $outer.scrollTop scrollTop = switch
      when liTop < scrollTop then liTop	
      when liBot > scrollBot then 2 * liBot - liTop - outerHeight
      else scrollTop
  
  getUl: ->
    switch @state.colFocused
      when 'dirs'   then @dirsUl
      when 'files'  then @filesUl
      when 'recent' then @recentUl
      
  setHighlight: ($ul, name) ->
    $lis = $ul.children()
    if name is '' then return false
    $matchedLi = null
    $lis.each ->
      $li = $ @
      if name is $li.text()
        $matchedLi = $li
        return false
    if $matchedLi
      $lis.removeClass 'highlight'
      $matchedLi.addClass 'highlight'
      @ensureLiVisible $matchedLi
      if $ul.hasClass 'dirs'  then @state.prevSelDirs[ @dir.length] = name
      if $ul.hasClass 'files' then @state.prevSelFiles[@dir.length] = name
	              #  console.log 'set prevsel', {name, @colFocused	      , prevSelDirs: @state.prevSelDirs, prevSelFiles: @state.prevSelFiles, @dir, dirlen: @dir.length}
      return true
    false
    
  moveHighlight: (code) ->
    $ul = @getUl()
    $hilite = $ul.find '.highlight'
    if (hiliteIdx = $hilite.index()) is -1 then code = 'down'
    hiliteIdx += switch code
      when 'up'   then -1
      when 'down' then +1
      when 'pgup' 
        {outerHeight, liTop, liBot} = @liMetrics $hilite
        - Math.floor outerHeight / (liBot - liTop)
      when 'pgdown' 
        {outerHeight, liTop, liBot} = @liMetrics $hilite
        Math.floor outerHeight / (liBot - liTop)
    $lis = $ul.children()
    hiliteIdx = Math.max 0, Math.min hiliteIdx, $lis.length - 1
    @setHighlight $ul, $lis.eq(hiliteIdx).text()
    
  keypress: (fromKeypress = yes) ->
    @lastKeyAction ?= 0
    now = Date.now()
    if @keypressTO then clearTimeout @keypressTO; @keypressTO = null
    if fromKeypress then @keypressTO = setTimeout (=> @keypress no), 310
    else if now > @lastKeyAction + 300 then @setAllFromPath()
    @lastKeyAction = now
    
  focusCol: (col) ->
    @$focusable.removeClass 'focused'   
    switch col
      when 'dirs'   then @dirs.addClass   'focused'
      when 'files'  then @files.addClass  'focused'
      when 'recent' then @recent.addClass 'focused'
    @state.colFocused = col
    
  focusNext: (fwd) -> 
    switch @state.colFocused
      when 'dirs'   then (if fwd then @focusCol('files')  else @focusCol('recent'))
      when 'files'  then (if fwd then @focusCol('recent') else @focusCol('dirs'))
      when 'recent' then (if fwd then @focusCol('dirs')   else @focusCol('files'))
      
  openFile: (text) ->
    if not @dir or not text then return
    @file = path.join @dir, text
    @file = if process.platform is 'win32' then @file.replace /\//g, '\\'  \
                                           else @file.replace /\\/g, '/'
    if not fs.existsSync @file
      atom.confirm
        message: 'View-Tail-Large-Files Error:\n\n'
        detailedMessage: 'File ' + @file + ' doesn\'t exist.'
        buttons: ['Close']
      return
    @destroy()
    console.log 'openFile', @file
    @FilePicker.open @file

  confirm: ->
    $ul = @getUl()
    if ($hi = $ul.find '.highlight').length is 0 then return
    text = $hi.text() 
    switch @state.colFocused
      when 'dirs'  then @openDir  text
      when 'files' then @openFile text
      
  openFromButton: ->              
    if ($tgt = @filesUl.find '.highlight	').length > 0
      @openFile $tgt.text()
    
  handleEvents: ->
    @click                                          => @$editor.focus()
    atom.workspaceView.on 'core:cancel core:close', => @destroy()
    atom.workspaceView.on 'core:confirm',           => @confirm()
    @on 'view-tail-large-files:focus-next',         => @focusNext yes
    @on 'view-tail-large-files:focus-previous',     => @focusNext no
    @on 'view-tail-large-files:up',                 => @moveHighlight 'up'
    @on 'view-tail-large-files:down',               => @moveHighlight 'down'
    @on 'view-tail-large-files:pgup',               => @moveHighlight 'pgup'
    @on 'view-tail-large-files:pgdown',             => @moveHighlight 'pgdown'
    @on 'view-tail-large-files:ctrl-up',            => @goToParent()
    @editorView.on 'keyup',                     (e) => @keypress()
    @cancelButton.on 'click',                       => @destroy()
    @openButton.on   'click',                       => @openFromButton()
    @bsButton.on     'click',                       => @goToParent()
    @on 'click', '.column-vertical',            (e) => @colClick e
          
  destroy: -> @detach()

