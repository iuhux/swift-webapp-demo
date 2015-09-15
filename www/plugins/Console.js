console = {
  log: function (string) {
    window.webkit.messageHandlers.jscallnative.postMessage({className: 'Console', functionName: 'log', data: string});
  }
}
