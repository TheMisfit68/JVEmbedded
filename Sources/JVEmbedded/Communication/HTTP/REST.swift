//
//  REST.swift
//  JVEmbedded
//
//  Created by Jan Verrept on 20/06/2025.
//


public class RESTClient: HTTPClient {
	
	public func get(path: String) throws(HTTPError) {
		let fullURL = baseURL + path
		let result = fullURL.withCString { urlCStr in
			esp_http_client_set_url(clientHandle, urlCStr)
			return esp_http_client_perform(clientHandle)
		}
		try HTTPError.check(result, "GET request failed for \(fullURL)")
	}
	
}
