// let d = new Date();
// alert("Today's date is " + d);

let response_data = '';

let apigClient = apigClientFactory.newClient();

let params = {
    //This is where any header, path, or querystring request params go. The key
    //is the parameter named as defined in the API
};
let body = {
    //This is where you define the body of the request
};
let additionalParams = {
    //If there are any unmodeled query parameters or headers that need to be
    //sent with the request you can add them here
};

apigClient.visitorCounterGet(params, body, additionalParams)
    .then(function(result){
        //This is where you would put a success callback
        console.log(result.data)
        response_data = result.data.num_visitors;
        document.getElementById('output').innerHTML = `Visitor Counter: ${response_data}`;
    }).catch( function(result){
        //This is where you would put an error callback
        console.error(result)
    });
