path = require 'path'
fs   = require 'fs-plus'
_ = require 'underscore-plus'

getBaseName = (file) ->
  path.basename(file, path.extname(file))

getExtensions = (editor) ->
  scopeName = editor.getGrammar().scopeName
  grammar   = atom.grammars.grammarForScopeName(scopeName)
  grammar.fileTypes ? []

module.exports =
  wordRegex: /[-\w/\.]+/

  activate: (state) ->
    atom.commands.add 'atom-text-editor',
      'open-this:here': => @open()
      'open-this:split-down': => @open('down')
      'open-this:split-right': => @open('right')

  getFiles: (file) ->
    editor = atom.workspace.getActiveTextEditor()
    exts = []

    if extname = path.extname(editor.getURI()) # ext of current file.
      exts.push extname.substr(1)

    exts = exts.concat getExtensions(editor)
    files = ("#{file}.#{ext}" for ext in exts)
    files.push file
    _.uniq files

  # Return first existing filePath in following order.
  #  - File with same extension to current file's
  #  - File with extensions... from current Grammar.fileTypes
  #  - File
  #  - File have same basename
  detectFilePath: (filePath) ->
    # Search existing file from file list.
    file = _.detect @getFiles(filePath), (f) ->
      fs.existsSync(f) and fs.lstatSync(fs.realpathSync(f))?.isFile()
    return file if file?

    # Search file have same basename.
    baseName = getBaseName(filePath)
    _.detect fs.listSync(path.dirname(filePath)), (f) ->
      getBaseName(f) is baseName

  open: (split) ->
    editor = atom.workspace.getActiveTextEditor()
    range = editor.getLastCursor().getCurrentWordBufferRange({@wordRegex})
    return unless fileName = editor.getTextInBufferRange(range)

    dirName = path.dirname(editor.getURI())

    return unless filePath = @detectFilePath(path.resolve(dirName, fileName))

    pane = atom.workspace.getActivePane()
    switch split
      when 'down' then pane.splitDown()
      when 'right' then pane.splitRight()

    atom.workspace.open(filePath, searchAllPanes: false).done ->

  deactivate: ->
