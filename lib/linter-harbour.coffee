{exec, child} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
path = require 'path'
{XRegExp} = require  "#{linterPath}/node_modules/xregexp"
fs = require 'fs'

class LinterHarbour extends Linter

  @syntax: 'source.harbour'

  cmd: 'harbour'

  linterName: 'harbour'

  #test.prg(1) Error E0002  Redefinition of procedure or function 'TEST'
  #test.prg(3) Warning W0005  RETURN statement with no return value in function
  regex: '\\((?<line>\\d+)\\) ((?<error>Error)|(?<warning>Warning)) ((?<message>.+))[\\n\\r]'

  regexFlags: ''

  # current working directory, overridden in linters that need it
  cwd: null

  defaultLevel: 'error'

  executablePath: null

  isNodeExecutable: no

  constructor: (editor) ->
    super(editor)

    atom.config.observe 'linter-harbour.harbourExecutablePath', =>
      @executablePath = atom.config.get 'linter-harbour.harbourExecutablePath'

    atom.config.observe 'linter-harbour.harbourIncludes', =>
      @harbourIncludes = atom.config.get 'linter-harbour.harbourIncludes'

    atom.config.observe 'linter-harbour.harbourOptions', =>
      @harbourOptions = atom.config.get 'linter-harbour.harbourOptions'

  getConfigFile: ->
    config = {}
    try
      localFile = path.join atom.project.path, 'linter-harbour.json'
      configObject = {}
      if fs.existsSync localFile
        configObject = fs.readFileSync localFile, 'UTF8'
        config = JSON.parse configObject
    catch e
      console.log e
    config

  # Private: get command and args for atom.BufferedProcess for execution
  getCmdAndArgs: (filePath) ->
    self = @
    cmd = @cmd

    localFolder = path.dirname( @editor.getPath() )

    config = @getConfigFile()

    # ensure we have an array
    cmd_list = if Array.isArray cmd
      cmd.slice()  # copy since we're going to modify it
    else
      cmd.split ' '

    hb_opt = if Array.isArray @harbourOptions
      @harbourOptions.join( ' ' )
    else
      @harbourOptions.split ' '

    cmd_list = cmd_list.concat hb_opt

    hb_includes_config = []

    if config.include?
      hb_includes_config = config.include if Array.isArray config.include

    if @harbourIncludes?
      hb_includes_temp = if Array.isArray @harbourIncludes
        @harbourIncludes.join( ' ' )
      else
        @harbourIncludes.split ' '

      hb_includes_temp = hb_includes_temp.concat hb_includes_config
      hb_includes = []
      for item in hb_includes_temp
        try
          stats = self._cachedStatSync item
          hb_includes.push "-i#{item}" if stats.isDirectory()
        catch e

      hb_includes.push "-i#{localFolder}"
      hb_includes.push "-i#{localFolder}/inc"
      hb_includes.push "-i#{localFolder}/include"
      cmd_list = cmd_list.concat hb_includes

    cmd_list.push filePath

    if @executablePath
      stats = @_cachedStatSync @executablePath
      if stats.isDirectory()
        cmd_list[0] = path.join @executablePath, cmd_list[0]
      else
        # because of the name exectablePath, people sometimes set it to the
        # full path of the linter executable
        cmd_list[0] = @executablePath

    if @isNodeExecutable
      cmd_list.unshift(@getNodeExecutablePath())

    # if there are "@filename" placeholders, replace them with real file path
    cmd_list = cmd_list.map (cmd_item) ->
      if /@filename/i.test(cmd_item)
        return cmd_item.replace(/@filename/gi, filePath)
      else
        return cmd_item

    {
      command: cmd_list[0],
      args: cmd_list.slice(1)
    }

  verifyRowNumber: (row) ->
    lastRow = @editor.getLastBufferRow()
    row = lastRow if lastRow < row
    row

  processMessage: (message, callback) ->
    messages = []
    regex = XRegExp @regex, @regexFlags
    XRegExp.forEach message, regex, (match, i) =>
      re = /\((\d+)\)/
      m = re.exec(match.message)
      match.line = m[1] if m
      messages.push(@createMessage(match))
    , this
    callback messages

  createMessage: (match) ->
    if match.error
      level = 'error'
    else if match.warning
      level = 'warning'
    else
      level = @defaultLevel
    message = @formatMessage(match)
    return {
      line: @verifyRowNumber( match.line ),
      col: match.col,
      level: level,
      message: message,
      linter: @linterName,
      range: @computeRange match
    }

  lineLengthForRow: (row) ->
    return @editor.lineLengthForBufferRow( @verifyRowNumber row )

  destroy: ->
    atom.config.unobserve 'linter-harbour.harbourExecutablePath'
    atom.config.unobserve 'linter-harbour.harbourOptions'
    atom.config.unobserve 'linter-harbour.harbourIncludes'

  errorStream: 'stderr'

module.exports = LinterHarbour
