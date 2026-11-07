package dev.learning.ecsapi.service;

import org.springframework.stereotype.Service;

@Service
public class GreetingService {
    public String welcome() {
        return "Welcome to the Spring Boot ECS learning API!";
    }
}
