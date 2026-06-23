package com.s3.skeleton.auto.controller;

import com.s3.skeleton.auto.dto.UserCreateRequest;
import com.s3.skeleton.auto.dto.UserUpdateRequest;
import com.s3.skeleton.support.AbstractControllerIntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * User Controller 集成测试（H2）+ OpenAPI 契约响应校验。
 */
class UserControllerIntegrationTest extends AbstractControllerIntegrationTest {

    @Test
    void userCrud_withH2_andOpenApiContract() throws Exception {
        UserCreateRequest create = new UserCreateRequest();
        create.setUsername("int_user");
        create.setPassword("password1");
        create.setEmail("int@example.com");
        create.setPhone("13800138001");

        String createBody = mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(create)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").isNumber())
                .andExpect(openApiContract())
                .andReturn()
                .getResponse()
                .getContentAsString();

        long userId = objectMapper.readTree(createBody).path("data").asLong();

        mockMvc.perform(get("/api/v1/users/" + userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username").value("int_user"))
                .andExpect(openApiContract());

        mockMvc.perform(get("/api/v1/users")
                        .param("username", "int")
                        .param("page", "1")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(openApiContract());

        UserUpdateRequest update = new UserUpdateRequest();
        update.setPhone("13900139001");
        update.setStatus(0);

        mockMvc.perform(put("/api/v1/users/" + userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(openApiContract());

        mockMvc.perform(delete("/api/v1/users/" + userId))
                .andExpect(status().isOk())
                .andExpect(openApiContract());

        mockMvc.perform(get("/api/v1/users/" + userId))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(openApiContract());
    }

    @Test
    void create_duplicateUsername_returnsConflict_andMatchesOpenApiContract() throws Exception {
        UserCreateRequest create = new UserCreateRequest();
        create.setUsername("dup_user");
        create.setPassword("password1");
        create.setEmail("dup1@example.com");

        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(create)))
                .andExpect(status().isOk())
                .andExpect(openApiContract());

        create.setEmail("dup2@example.com");
        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(create)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value(409))
                .andExpect(openApiContract());
    }
}
