
# plugins/file-picker

fs = require 'fs-plus'
_  = require "underscore"
SubAtom = require 'sub-atom'

module.exports =
class FilePicker

  @type = 'singleton'

  constructor: (pluginMgr, @state, vtlfLibPath) ->
    @subs = new SubAtom

    @Viewer        = require vtlfLibPath + 'viewer'
    FilePickerView = require './file-picker-view'

    @subs.add atom.commands.add 'atom-workspace, atom-text-editor::shadow', 'view-tail-large-files:open', =>
      if (filePickerView = FilePickerView.getViewFromDOM())
        filePickerView.destroy()
        delete @filePickerView
      else
        @filePickerView = new FilePickerView @state, @

    pluginMgr.onDidOpenFile (fileView) => @didOpenFile fileView

  didOpenFile: (fileView) ->
      @state.recentSel ?= []
      @state.recentSel = _.reject @state.recentSel, (recentFile) -> recentFile is fileView.filePath
      @state.recentSel.unshift fileView.filePath

  fileSelected: (filePath) ->
    atom.workspace.activePane.activateItem new @Viewer filePath

  destroy: ->
    @subs.dispose()
    @filePickerView?.destroy()
