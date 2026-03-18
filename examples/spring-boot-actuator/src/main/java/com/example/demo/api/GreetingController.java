package com.example.demo.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Simple HTTP API used by the sample project to exercise regression and actuator checks.
 */
@RestController
@RequestMapping("/api")
public class GreetingController {

	/**
	 * Public constructor kept explicit so generated Javadocs stay clean in release builds.
	 */
	public GreetingController() {
	}

	/**
	 * Returns a greeting payload for the requested caller name.
	 *
	 * @param name caller name to greet
	 * @return immutable greeting payload exposed by the API
	 */
	@GetMapping("/greeting")
	public GreetingResponse greeting(@RequestParam(defaultValue = "world") String name) {
		return new GreetingResponse("Hello " + name, "v1");
	}

	/**
	 * Immutable response returned by the greeting endpoint.
	 *
	 * @param message    rendered greeting message
	 * @param apiVersion API version exposed by the sample endpoint
	 */
	public record GreetingResponse(String message, String apiVersion) {
	}
}
