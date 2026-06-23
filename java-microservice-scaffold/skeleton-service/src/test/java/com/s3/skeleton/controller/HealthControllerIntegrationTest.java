package com.s3.skeleton.controller;

import com.s3.skeleton.support.AbstractControllerIntegrationTest;
import org.junit.jupiter.api.Test;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Health Controller 集成测试 + OpenAPI 契约响应校验。
 */
class HealthControllerIntegrationTest extends AbstractControllerIntegrationTest {

    @Test
    void health_returnsUp_andMatchesOpenApiContract() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.status").value("UP"))
                .andExpect(openApiContract());
    }
}
