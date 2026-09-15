package dev.learn.scales;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

// Program.cs: @SpringBootApplication turns on component scanning and auto-configuration for this package and below.
@SpringBootApplication
@ConfigurationPropertiesScan
public class ScalesApplication {

    public static void main(String[] args) {
        SpringApplication.run(ScalesApplication.class, args);
    }
}
