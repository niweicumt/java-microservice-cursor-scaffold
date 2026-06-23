package com.s3.skeleton.contract;

import com.s3.skeleton.support.OpenApiContractSupport;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * OpenAPI 契约兼容性（CI 阶段 4）：基线 {@code skeleton-api.openapi.yaml} 中的 path/operation
 * 须仍存在于运行时 {@code /v3/api-docs}（允许新增，禁止删除）。
 */
@SpringBootTest
@AutoConfigureMockMvc
class OpenApiContractTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void baselineContract_isLoadable() {
        OpenApiContractSupport.assertBaselineContainsPaths(
                "/api/v1/health",
                "/api/v1/users",
                "/api/v1/users/{id}");
    }

    @Test
    void runtimeApiDocs_isBackwardCompatibleWithBaseline() throws Exception {
        String liveDocs = mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andReturn()
                .getResponse()
                .getContentAsString();

        OpenApiContractSupport.assertBackwardCompatible(liveDocs);
    }
}
