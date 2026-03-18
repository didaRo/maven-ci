package com.example.demo.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import java.util.stream.Stream;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

@WebMvcTest(GreetingController.class)
class GreetingControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@ParameterizedTest(name = "name={0} -> {1}")
	@MethodSource("greetingRequests")
	void should_return_greeting(String name, String expectedMessage) throws Exception {
		MockHttpServletRequestBuilder request = get("/v1/api/greeting").contextPath("/v1");
		if (name != null) {
			request = request.param("name", name);
		}

		mockMvc.perform(request).andExpect(status().isOk()).andExpect(jsonPath("$.message").value(expectedMessage))
				.andExpect(jsonPath("$.apiVersion").value("v1"));
	}

	@Test
	void should_create_domain_response_when_calling_controller_directly() {
		GreetingController controller = new GreetingController();

		GreetingController.GreetingResponse response = controller.greeting("codex");

		assertThat(response.message()).isEqualTo("Hello codex");
		assertThat(response.apiVersion()).isEqualTo("v1");
	}

	private static Stream<Arguments> greetingRequests() {
		return Stream.of(Arguments.of(null, "Hello world"), Arguments.of("team", "Hello team"));
	}
}
