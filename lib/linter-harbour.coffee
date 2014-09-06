{exec, child} = require 'child_process'
linterPath = atom.packages.getLoadedPackage("linter").path
Linter = require "#{linterPath}/lib/linter"
path = require 'path'

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

  # Private: get command and args for atom.BufferedProcess for execution
  getCmdAndArgs: (filePath) ->
    self = @
    cmd = @cmd

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

    if @harbourIncludes?
      hb_includes_temp = if Array.isArray @harbourIncludes
        @harbourIncludes.join( ' ' )
      else
        @harbourIncludes.split ' '

      hb_includes = hb_includes_temp.map (item) ->
        stats = self._cachedStatSync item
        return "-i#{item}" if stats.isDirectory()

      hb_includes.push "-i./"
      hb_includes.push "-i./inc"
      hb_includes.push "-i./include"

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

  createMessage: (match) ->
    if match.error
      level = 'error'
    else if match.warning
      level = 'warning'
    else
      level = @defaultLevel

    return {
      line: @verifyRowNumber( match.line ),
      col: match.col,
      level: level,
      message: @formatMessage(match),
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
