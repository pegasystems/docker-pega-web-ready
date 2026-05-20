var url = arguments[0];
var client = java.net.http.HttpClient.newHttpClient();
var request = java.net.http.HttpRequest.newBuilder().uri(java.net.URI.create(url)).GET().build();
var response = client.send(request, java.net.http.HttpResponse.BodyHandlers.ofString());
var statusCode = response.statusCode();
println(statusCode);
