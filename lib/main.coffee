{CompositeDisposable} = require 'atom'
helpers = require('atom-linter')

module.exports =
  config:
    executablePath:
      type: 'string'
      title: 'harbour Executable'
      default: 'harbour' # Let OS's $PATH handle the rest

  _testBin: ->
    title = 'linter-harbour: Unable to determine PHP version'
    message = 'Unable to determine the version of "' + @executablePath +
      '", please verify that this is the right path to harbour.'
    try
      helpers.exec(@executablePath, ['--version']).then (output) =>
        # Harbour 3.2.0dev (r1408271619)
        regex = /Harbour (\d+.*) /g
        if not regex.exec(output)
          atom.notifications.addError(title, {detail: message})
          @executablePath = ''
      .catch (e) ->
        console.log e
        atom.notifications.addError(title, {detail: message})

  activate: ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'linter-harbour.executablePath',
      (executablePath) =>
        @executablePath = executablePath
        @_testBin()

  deactivate: ->
    @subscriptions.dispose()

  provideLinter: ->
    provider =
      name: 'harbour'
      grammarScopes: [ 'source.harbour', 'source.hb' ]
      scope: 'file'
      lintOnFly: false
      lint: (textEditor) =>
        filePath = textEditor.getPath()
        command = @executablePath
        return Promise.resolve([]) unless command?
        parameters = []
        parameters.push('-n', '-s', '-w3', '-es1', '-q0')
        text = textEditor.getText()
        return helpers.exec(command, parameters, {stdin: text}).then (output) ->
          # test.prg(3) Error E0030  Syntax error "syntax error at '?'"
          # test.prg(8) Error E0020  Incomplete statement or unbalanced delimiters
          regex = /([\w\.]+)\((\d+)\) (Error)|Warning) ([\w\d]+) (.+)/g
          messages = []
          console.log(output)
          while((match = regex.exec(output)) isnt null)
            messages.push
              type: match[3]
              filePath: filePath
              range: helpers.rangeFromLineNumber(textEditor, match[1] - 1)
              text: match[4]
          messages
