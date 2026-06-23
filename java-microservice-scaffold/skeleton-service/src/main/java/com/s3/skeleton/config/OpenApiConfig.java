package com.s3.skeleton.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Value("${spring.application.name}")
    private String applicationName;

    @Bean
    public OpenAPI skeletonOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title(applicationName + " API")
                        .description("团队 Java 服务骨架；统一返回 Result(code, msg, data)")
                        .version("1.0.0")
                        .contact(new Contact().name("team").email("team@example.com")));
    }
}
