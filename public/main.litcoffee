# ![logo](https://solsort.com/_logo.png) "Vores fart" (danish for "our speed")

Visualisation of speeding measurements.

## Todo

- find ud af de præcise detaljer hvilket gennemsnit etc. der skal bruges, ie. er der outliers der skal prunes, eller lignende?
- tooltip over bars
- tekst for måned i dato
- hover-effect
- konkurrencepladser i bunden, ved hvilket vejarbejde overholdes hastighedsbegrænsningen bedst?
- styling
- flytte backenden over i php, - send mail med spec til arni
- typen der sendes med til webserviceUrl'en skal sikres at være den rigtige. Forøjeblikket sendes typen 0.
- ie. support
- extract such that it is easy to integrate


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

## Utility

Utility function formatting a date in danish, this is used for making the data url

    danishDate = (date) ->
        "#{date.getDate()}/#{date.getMonth()+1}-#{date.getFullYear()}"

Constant for readability of code

    millisecondsPerHour = 60*60*1000
    millisecondsPerDay = 24*millisecondsPerHour

Utility for finding the average

    avg = (list) -> list.reduce(((a,b)->a+b), 0) / list.length

## Visualisation

### Meteor code

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
        undefined 

    visualiseBars = ($visualisation, data) ->
 
Find the label/indexed of the data, sorted descending.

        datehours = {}
        for id of unitIds
            for datahour of data[id]
                datehours[datahour] = true
        datehours = (key for key of datehours).sort().reverse()
        console.log data, datehours

Run through the data and unitIds, and draw bars. Keep track of coordinates, and place absolutely.

        y = 0
        for datehour in datehours
            addTitle $visualisation, datehour, 0, y
            x = barX
            for id of unitIds
                console.log data[id][datehour]
                addBar $visualisation, data[id][datehour], x, y
                x += barSpacing
            y += lineHeight

Create an place label for each set of bars

    addTitle = ($root, title, x, y) ->
        text = title.slice(-2) + ":00"
        date = " " + title.slice(5, -3)
        text = text + date if y is 0
        text = text + date if text is "23:00"
        $label = ($ '<div class="label">').text(text)
        $label.css
            left: x
            top: y
        $root.append $label

The bar contains of three parts, a blue box, an orange box, and a line annotating the average.
Create those elements for the and add them to the root element

    addBar = ($root, item, x, y) ->
        console.log item

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
    showHover = (item) ->
        console.log "showhover"
    hideHover = (item) ->
        console.log "hidehover"

    addHover = ($root, item, elems) ->
        for $elem in elems
            $elem.on "mouseover", -> showHover(item)
            $elem.on "mouseout", -> hideHover(item)



