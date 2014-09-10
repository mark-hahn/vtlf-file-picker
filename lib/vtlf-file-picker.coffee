
# plugins/file-picker

fs     = require 'fs-plus'

module.exports =
class FilePicker
  
  @activate = (vtlfLibPath) ->
    # ViewOpener     = require vtlfLibPath + 'view-opener'
    FilePickerView = require './file-picker-view'
    
    atom.workspaceView.command "view-tail-large-files:open", ->
      new FilePickerView
      
  #     filePath = 'c:\\apps\\insteon\\data\\hvac.log'
  #     atom.workspace.activePane.activateItem new ViewOpener filePath, @
  
  # constructor: (filePath, view) ->
  #   view.open()
  

  