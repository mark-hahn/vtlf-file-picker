
# plugins/file-picker

fs = require 'fs-plus'
_  = require "underscore"

module.exports =
class FilePicker
  
  @type = 'singleton'

  constructor: (pluginMgr, @state, vtlfLibPath, @vtlfEmitter) ->
    @ViewOpener    = require vtlfLibPath + 'view-opener'
    FilePickerView = require './file-picker-view'
    
    atom.workspaceView.command "view-tail-large-files:open", =>
      if (filePickerView = FilePickerView.getViewFromDOM())
        filePickerView.destroy()
        delete @filePickerView
      else
        @filePickerView = new FilePickerView @state, @
        
    pluginMgr.onDidOpenFile (fileView) => @didOpenFile fileView
        
  didOpenFile: (fileView) ->
      recentSel = (@state.recentSel ?= [])
      recentSel = _.reject recentSel, (recentFile) -> recentFile is fileView.filePath
      @state.recentSel.unshift fileView.filePath
        
  fileSelected: (filePath) ->
    atom.workspace.activePane.activateItem new @ViewOpener filePath
      
  destroy: -> @filePickerView?.destroy()
