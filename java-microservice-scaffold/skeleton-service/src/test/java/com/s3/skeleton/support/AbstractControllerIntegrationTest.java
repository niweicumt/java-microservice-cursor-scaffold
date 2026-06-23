package com.s3.skeleton.support;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;
import org.springframework.transaction.annotation.Transactional;

import static com.atlassian.oai.validator.mockmvc.OpenApiValidationMatchers.openApi;

/**
 * Controller 集成测试基类：H2 + Flyway + MockMvc + OpenAPI 契约响应校验。
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
public abstract class AbstractControllerIntegrationTest {

    protected static final String OPENAPI_SPEC = OpenApiContractSupport.CONTRACT_YAML;

    @Autowired
    protected MockMvc mockMvc;

    @Autowired
    protected ObjectMapper objectMapper;

    /** 校验 HTTP 请求/响应符合契约 */
    protected ResultMatcher openApiContract() {
        return openApi().isValid(OpenApiContractValidator.get());
    }
}
