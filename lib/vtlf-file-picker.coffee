
# plugins/file-picker

fs = require 'fs-plus'
_  = require "underscore"

module.exports =
class FilePicker

  constructor: (@state, vtlfLibPath, @pluginMgr) ->
    @ViewOpener  = require vtlfLibPath + 'view-opener'
    FilePickerView = require './file-picker-view'
    
    atom.workspaceView.command "view-tail-large-files:open", =>
      if (filePickerView = FilePickerView.getViewFromDOM())
        filePickerView.destroy()
      else
        @filePickerView = new FilePickerView @state, @

  openFile: (filePath) ->
    atom.workspace.activePane.activateItem new @ViewOpener filePath, @
      
  postFileOpen: (fileView, filePath) -> 
    @state.recentSel = 
      _.reject @state.recentSel, (recentFile) -> recentFile is filePath
    @state.recentSel.unshift filePath
    
  @destroy: -> 
    @singletonInstance?.filePickerView?.destroy()
    