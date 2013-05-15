# ![logo](https://solsort.com/_logo.png) "Vores fart" (danish for "our speed")

Visualisation of speeding measurements.

## Todo

- √tooltip over bars
- vtekst for måned i dato
- √hover-effect
- √konkurrencepladser i bunden, ved hvilket vejarbejde overholdes hastighedsbegrænsningen bedst?
- √styling - bars/border between text
- IE8 support
- √frame


## Configuration

Url for webservice

    webservice = "/webservice"

Speed limit

    speedLimit = 50

Unit ids

    unitIds =
        37: "Motorring 4"
        101: "Kolding V"
        111: "Vilsundbroen"

Visualisation parameters, telling where on the screen the dynamic elements are placed

    barWidth = 100
    barX = 100
    barY = 7 
    barSpacing = 220
    lineHeight = 16


## Visualisation

`getData` could be replaced with a function that get the data from a webservice, instead of doing an RPC. Ie. via `$.ajax(..)` or similar.

    getData = (callback) -> Meteor.call "getData", callback 

This could just be replaced with `$(...)`.


### Exports

Get the data, and visualise it :)

    this.visSpeed = (obj)->
        $.get obj.webservice, ((result)->
            visualiseBars $(obj.visualisationElem), result if obj.visualisationElem
            visualiseScore $(obj.scoreElem), result if obj.scoreElem
        ), "json"

### Actual visualisation code

    visualiseScore = ($score, data) ->
        offenders = data.offenders
        rank = (key for key of unitIds).sort (a,b)->offenders[a]-offenders[b]
        for id, name of unitIds
            $score.append $ """
            <div class="scoreInfo"> #{1 + rank.indexOf id}.
            <div class="scoreBlock"><div class="scoreTitle"> #{name} </div>
            <div class="scoreBar"><div class="scoreBarOk" style="width: #{100-100*offenders[id]}%">
            <span class="scoreBarText">#{Math.round(10000* (1-offenders[id]))/100}%</span>
            </div></div></div></div>
            """

    visualiseBars = ($visualisation, data) ->
 
Find the label/indexed of the data, sorted descending.

        datehours = {}
        for id of unitIds
            for datahour of data[id]
                datehours[datahour] = true
        datehours = (key for key of datehours).sort().reverse()

Run through the data and unitIds, and draw bars. Keep track of coordinates, and place absolutely.

        y = 0
        for datehour in datehours
            addTitle $visualisation, datehour, 0, y
            x = barX
            for id of unitIds
                addBar $visualisation, data[id][datehour], x, y
                x += barSpacing
            y += lineHeight
        $visualisation.css "height", y

Add popup

        $hover = $ '<div class="hoverInfo">'
        $visualisation.append $hover

Utility for writing the month:

    danishDate = (date) ->
        months = ["Januar", "Februar", "Marts", "April", "Maj", "Juni", "Juli", "August", "September", "Oktober", "November", "December"] 
        date = new Date(date)
        date.getDate() + ". " + months[date.getMonth()]

Create an place label for each set of bars

    addTitle = ($root, title, x, y) ->
        date = new Date(title.slice(0, -3))
        text = title.slice(-2) + ":00"
        text = text + " " + danishDate +date if text is "23:00"
        text = text + " " + danishDate +date if y is 0
        $label = ($ '<div class="label">').text(text)
        $label.css
            left: x
            top: y
        $root.append $label

The bar contains of three parts, a blue box, an orange box, and a line annotating the average.
Create those elements for the and add them to the root element

    addBar = ($root, item, x, y) ->
        $blueBox = $ '<div class="bar ok">'
        $blueBox.css
            left: x + item.offenders * barWidth
            top: y + barY
            width: barWidth * (1-item.offenders)
        $root.append $blueBox

        $orangeBox= $ '<div class="bar offenders">'
        $orangeBox.css
            left: x + barWidth
            top: y + barY
            width: barWidth * item.offenders
        $root.append $orangeBox

        $avgLine = $ '<div class="speedLine">'
        $avgLine.css
            left: x + item.avgSpeed / speedLimit * barWidth
            top: y + barY
        $root.append $avgLine

        addHover $root, item, [$blueBox, $orangeBox, $avgLine]

    hoverDepth = 0;

    currentData = undefined
    $currentElem = undefined

    showHover = (e, item) ->
        $currentElem.off "mousemove", hoverMove if $currentElem 
        $currentElem = $ e.currentTarget
        $currentElem.on "mousemove", hoverMove
        currentData = item
        ($ ".hoverInfo")
            .html("Gennemsnitsfart: #{Math.round(item.avgSpeed)}km/t <br>#{Math.round(100*(1-item.offenders))}% overholdt grænsen")
            .css
                display: "block"
                top: 0
                left: 0
        hoverMove e

    hideHover = (e, item) ->
        $currentElem.off "mousemove", hoverMove if $currentElem 
        $currentElem = undefined
        ($ ".hoverInfo").css "display", "none"

    hoverMove = (e) ->
        $hover = ($ ".hoverInfo")
        $hover.offset
            top: e.clientY - $hover.height() / 2 + ($ "body").scrollTop()
            left: e.clientX - $hover.width() - 10 + ($ "body").scrollLeft()


    addHover = ($root, item, elems) ->
        for $elem in elems
            $elem.on "mouseover", (e) -> showHover(e, item)
            $elem.on "mouseout", (e) -> hideHover(e, item)
