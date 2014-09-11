
# plugins/file-picker

fs     = require 'fs-plus'

module.exports =
class FilePicker
  
  @activate = (state, vtlfLibPath) ->
    @ViewOpener  = require vtlfLibPath + 'view-opener'
    FilePickerView = require './file-picker-view'
    
    atom.workspaceView.command "view-tail-large-files:open", ->
      if not FilePickerView.remove() 
        new FilePickerView state, FilePicker

  @open = (filePath) ->
    atom.workspace.activePane.activateItem new @ViewOpener filePath, FilePicker
      
  constructor: (@filePath, view, reader, lineMgr, viewOpener) ->
    if viewOpener.getCreatorPlugin() is FilePicker
      view.open @
  