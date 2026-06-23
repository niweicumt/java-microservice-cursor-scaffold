package com.s3.skeleton.auto.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.s3.common.core.exception.GlobalExceptionHandler;
import com.s3.skeleton.auto.dto.PageVO;
import com.s3.skeleton.auto.dto.UserCreateRequest;
import com.s3.skeleton.auto.dto.UserVO;
import com.s3.skeleton.auto.service.UserAutoService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.validation.beanvalidation.LocalValidatorFactoryBean;

import java.util.Collections;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserAutoService userAutoService;

    @InjectMocks
    private UserController userController;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        LocalValidatorFactoryBean validator = new LocalValidatorFactoryBean();
        validator.afterPropertiesSet();
        objectMapper = new ObjectMapper();
        objectMapper.findAndRegisterModules();
        mockMvc = MockMvcBuilders.standaloneSetup(userController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setValidator(validator)
                .setMessageConverters(new MappingJackson2HttpMessageConverter(objectMapper))
                .build();
    }

    @Test
    void create_validRequest_returnsId() throws Exception {
        UserCreateRequest req = new UserCreateRequest();
        req.setUsername("testuser");
        req.setPassword("password1");
        req.setEmail("test@example.com");

        when(userAutoService.create(any())).thenReturn(10L);

        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").value(10));

        verify(userAutoService).create(any());
    }

    @Test
    void create_invalidPassword_returnsBadRequest() throws Exception {
        UserCreateRequest req = new UserCreateRequest();
        req.setUsername("testuser");
        req.setPassword("short");
        req.setEmail("test@example.com");

        mockMvc.perform(post("/api/v1/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    @Test
    void page_returnsResult() throws Exception {
        UserVO vo = new UserVO();
        vo.setId(1L);
        vo.setUsername("u1");
        when(userAutoService.page(any())).thenReturn(new PageVO<>(Collections.singletonList(vo), 1, 1, 10));

        mockMvc.perform(get("/api/v1/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.records[0].username").value("u1"));
    }

    @Test
    void getById_returnsUser() throws Exception {
        UserVO vo = new UserVO();
        vo.setId(1L);
        vo.setUsername("u1");
        when(userAutoService.getById(1L)).thenReturn(vo);

        mockMvc.perform(get("/api/v1/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.username").value("u1"));

        verify(userAutoService).getById(eq(1L));
    }
}
