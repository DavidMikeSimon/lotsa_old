'use strict'

### Sevices ###

angular.module('app.services', [])

.factory 'MyData', ($rootScope, $http, $location) ->
    protoBuilder = null
    Chunk = null
    dataStream = null
    collection = []
    
    $http.get('proto/werld.proto')
    .then (result) =>
        protoBuilder = dcodeIO.ProtoBuf.loadProto(result.data)
        Proto = protoBuilder.build("WerldProto")
        dataStream = new WebSocket("ws://#{$location.host()}:3000/websocket")
        dataStream.binaryType = "arraybuffer"

        dataStream.onmessage = (message) -> $rootScope.$apply ->
            if message.data instanceof ArrayBuffer
                collection.push JSON.stringify(Proto.Chunk.decode(message.data))
            else
                collection.push message.data
            
        dataStream.onopen = -> $rootScope.$apply ->
            dataStream.send("Foo")

    return {collection: collection}

         
