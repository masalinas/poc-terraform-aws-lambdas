exports.handler = async (event) => {
    // define json web token
    const ACCESS_TOKEN = "eyJhbGciOiJIUzI1NiJ9.eyJSb2xlIjoiQWRtaW4iLCJJc3N1ZXIiOiJNYW5nbyIsIlVzZXJuYW1lIjoib3duZXIiLCJpYXQiOjE2NDg4MzA3NzJ9.-2fEbjElWdNT4FW6e19HmxuteUALN1dxXEyCF9BuFQg";
    
    // check if the user's token is valid
    let auth = "Deny";
    
    if (event.headers.authorization == ACCESS_TOKEN)
        auth = "Allow";
    else
        auth = "Deny"; 
        

    let authResponse = {
                            "principalId": ACCESS_TOKEN,
                            "policyDocument": {
                                "Version": "2012-10-17",
                                "Statement": [{
                                        "Action": "execute-api:Invoke",
                                        "Effect": auth,
                                        "Resource": event.routeArn
                                }]
                            }
                        };
    
    return authResponse;
};
