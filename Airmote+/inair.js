function PubSub() {
  this._subs = {};

  this.on = function(event, fn) {
    this._subs[event] = this._subs[event] || []; //create array for event
    this._subs[event].push(fn);
  };

  this.emit = function(event) {
    var args = [].slice.call(arguments, 1); //pop off event argument
    if (this._subs[event]) {
      this._subs[event].forEach(function(sub) {
        sub.apply(void 0, args); //call each method listening on the event
      });  
    };
  };

  this.send = function(params) {
    // JavaScript to send an action to your Objective-C code
    var appName = 'inair';
    var actionType = 'send';

    // (separating the actionType from parameters makes it easier to parse in ObjC.)
    var jsonString = (JSON.stringify(params));
    var escapedJsonParameters = escape(jsonString);
    var url = appName + '://' + actionType + "#" + escapedJsonParameters;
    document.location.href = url;
  }
}

var InAir = new PubSub();