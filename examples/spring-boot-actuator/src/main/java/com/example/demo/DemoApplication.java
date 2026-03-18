package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Entry point for the Spring Boot actuator sample application.
 */
@SpringBootApplication
public class DemoApplication {

	/**
	 * Utility constructor kept private because this class only exposes the main entry point.
	 */
	private DemoApplication() {
	}

	/**
	 * Starts the sample Spring Boot application.
	 *
	 * @param args startup arguments forwarded to Spring Boot
	 */
	public static void main(String[] args) {
		SpringApplication.run(DemoApplication.class, args);
	}
}
