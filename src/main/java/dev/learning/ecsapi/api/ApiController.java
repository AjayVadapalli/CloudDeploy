package dev.learning.ecsapi.api;

import dev.learning.ecsapi.service.GreetingService;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.actuate.health.HealthEndpoint;
import org.springframework.boot.actuate.health.Status;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ApiController {
    private static final Logger log = LoggerFactory.getLogger(ApiController.class);
    private final GreetingService greetingService;
    private final HealthEndpoint healthEndpoint;

    public ApiController(GreetingService greetingService, HealthEndpoint healthEndpoint) {
        this.greetingService = greetingService;
        this.healthEndpoint = healthEndpoint;
    }

    @GetMapping("/")
    public Map<String, String> welcome() {
        log.info("Welcome endpoint requested");
        return Map.of("message", greetingService.welcome());
    }

    @GetMapping("/api/hello")
    public Map<String, String> hello() {
        return Map.of("message", "Hello from Spring Boot running on AWS ECS!");
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> health() {
        Status status = healthEndpoint.health().getStatus();
        HttpStatus httpStatus = Status.UP.equals(status) ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE;
        return ResponseEntity.status(httpStatus).body(Map.of("status", status.getCode()));
    }

    @GetMapping("/api/info")
    public Map<String, String> info() {
        return Map.of("name", "ecs-spring-api", "framework", "Spring Boot", "java", "21");
    }
}
