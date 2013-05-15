// Generated by CoffeeScript 1.6.1
(function() {
  var $currentElem, addBar, addHover, addTitle, barSpacing, barWidth, barX, barY, currentData, danishDate, getData, hideHover, hoverDepth, hoverMove, lineHeight, showHover, speedLimit, unitIds, visualiseBars, visualiseScore, webservice;

  webservice = "/webservice";

  speedLimit = 50;

  unitIds = {
    37: "Motorring 4",
    101: "Kolding V",
    111: "Vilsundbroen"
  };

  barWidth = 100;

  barX = 100;

  barY = 7;

  barSpacing = 220;

  lineHeight = 16;

  getData = function(callback) {
    return Meteor.call("getData", callback);
  };

  this.visSpeed = function(obj) {
    return $.get(obj.webservice, (function(result) {
      if (obj.visualisationElem) {
        visualiseBars($(obj.visualisationElem), result);
      }
      if (obj.scoreElem) {
        return visualiseScore($(obj.scoreElem), result);
      }
    }), "json");
  };

  visualiseScore = function($score, data) {
    var id, key, name, offenders, rank, _results;
    offenders = data.offenders;
    rank = ((function() {
      var _results;
      _results = [];
      for (key in unitIds) {
        _results.push(key);
      }
      return _results;
    })()).sort(function(a, b) {
      return offenders[a] - offenders[b];
    });
    _results = [];
    for (id in unitIds) {
      name = unitIds[id];
      _results.push($score.append($("<div class=\"scoreInfo\"> " + (1 + rank.indexOf(id)) + ".\n<div class=\"scoreBlock\"><div class=\"scoreTitle\"> " + name + " </div>\n<div class=\"scoreBar\"><div class=\"scoreBarOk\" style=\"width: " + (100 - 100 * offenders[id]) + "%\">\n<span class=\"scoreBarText\">" + (Math.round(10000 * (1 - offenders[id])) / 100) + "%</span>\n</div></div></div></div>")));
    }
    return _results;
  };

  visualiseBars = function($visualisation, data) {
    var $hover, datahour, datehour, datehours, id, key, x, y, _i, _len;
    datehours = {};
    for (id in unitIds) {
      for (datahour in data[id]) {
        datehours[datahour] = true;
      }
    }
    datehours = ((function() {
      var _results;
      _results = [];
      for (key in datehours) {
        _results.push(key);
      }
      return _results;
    })()).sort().reverse();
    y = 0;
    for (_i = 0, _len = datehours.length; _i < _len; _i++) {
      datehour = datehours[_i];
      addTitle($visualisation, datehour, 0, y);
      x = barX;
      for (id in unitIds) {
        addBar($visualisation, data[id][datehour], x, y);
        x += barSpacing;
      }
      y += lineHeight;
    }
    $visualisation.css("height", y);
    $hover = $('<div class="hoverInfo">');
    return $visualisation.append($hover);
  };

  danishDate = function(date) {
    var months;
    months = ["Januar", "Februar", "Marts", "April", "Maj", "Juni", "Juli", "August", "September", "Oktober", "November", "December"];
    date = new Date(date);
    return date.getDate() + ". " + months[date.getMonth()];
  };

  addTitle = function($root, title, x, y) {
    var $label, date, text;
    date = new Date(title.slice(0, -3));
    text = title.slice(-2) + ":00";
    if (text === "23:00") {
      text = text + " " + danishDate(+date);
    }
    if (y === 0) {
      text = text + " " + danishDate(+date);
    }
    $label = ($('<div class="label">')).text(text);
    $label.css({
      left: x,
      top: y
    });
    return $root.append($label);
  };

  addBar = function($root, item, x, y) {
    var $avgLine, $blueBox, $orangeBox;
    $blueBox = $('<div class="bar ok">');
    $blueBox.css({
      left: x + item.offenders * barWidth,
      top: y + barY,
      width: barWidth * (1 - item.offenders)
    });
    $root.append($blueBox);
    $orangeBox = $('<div class="bar offenders">');
    $orangeBox.css({
      left: x + barWidth,
      top: y + barY,
      width: barWidth * item.offenders
    });
    $root.append($orangeBox);
    $avgLine = $('<div class="speedLine">');
    $avgLine.css({
      left: x + item.avgSpeed / speedLimit * barWidth,
      top: y + barY
    });
    $root.append($avgLine);
    return addHover($root, item, [$blueBox, $orangeBox, $avgLine]);
  };

  hoverDepth = 0;

  currentData = void 0;

  $currentElem = void 0;

  showHover = function(e, item) {
    if ($currentElem) {
      $currentElem.off("mousemove", hoverMove);
    }
    $currentElem = $(e.currentTarget);
    $currentElem.on("mousemove", hoverMove);
    currentData = item;
    ($(".hoverInfo")).html("Gennemsnitsfart: " + (Math.round(item.avgSpeed)) + "km/t <br>" + (Math.round(100 * (1 - item.offenders))) + "% overholdt grænsen").css({
      display: "block",
      top: 0,
      left: 0
    });
    return hoverMove(e);
  };

  hideHover = function(e, item) {
    if ($currentElem) {
      $currentElem.off("mousemove", hoverMove);
    }
    $currentElem = void 0;
    return ($(".hoverInfo")).css("display", "none");
  };

  hoverMove = function(e) {
    var $hover;
    $hover = $(".hoverInfo");
    return $hover.offset({
      top: e.clientY - $hover.height() / 2 + ($("body")).scrollTop(),
      left: e.clientX - $hover.width() - 10 + ($("body")).scrollLeft()
    });
  };

  addHover = function($root, item, elems) {
    var $elem, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = elems.length; _i < _len; _i++) {
      $elem = elems[_i];
      $elem.on("mouseover", function(e) {
        return showHover(e, item);
      });
      _results.push($elem.on("mouseout", function(e) {
        return hideHover(e, item);
      }));
    }
    return _results;
  };

}).call(this);
