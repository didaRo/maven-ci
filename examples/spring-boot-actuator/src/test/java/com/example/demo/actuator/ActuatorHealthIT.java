package com.example.demo.actuator;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.boot.resttestclient.TestRestTemplate;
import org.springframework.boot.resttestclient.autoconfigure.AutoConfigureTestRestTemplate;
import org.springframework.http.HttpStatus;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@AutoConfigureTestRestTemplate
class ActuatorHealthIT {

	@LocalServerPort
	private int port;

	@Autowired
	private TestRestTemplate restTemplate;

	@ParameterizedTest(name = "endpoint {0} should be available")
	@ValueSource(strings = { "/v1/actuator/health", "/v1/actuator/info" })
	void actuator_endpoints_should_be_available(String path) {
		var response = restTemplate.getForEntity(baseUrl() + path, Map.class);

		assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
	}

	@Test
	void health_endpoint_should_be_up() {
		var response = restTemplate.getForEntity(baseUrl() + "/v1/actuator/health", Map.class);

		assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
		assertThat(response.getBody()).containsEntry("status", "UP");
	}

	private String baseUrl() {
		return "http://localhost:" + port;
	}
}
