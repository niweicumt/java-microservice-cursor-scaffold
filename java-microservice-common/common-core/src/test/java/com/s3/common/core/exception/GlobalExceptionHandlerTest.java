package com.s3.common.core.exception;

import com.s3.common.core.result.Result;
import com.s3.common.core.result.ResultCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BeanPropertyBindingResult;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.constraints.NotBlank;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
    }

    @Test
    void handleBusiness_badRequest_returns400() {
        ResponseEntity<Result<Void>> response = handler.handleBusiness(
                new BusinessException(ResultCode.BAD_REQUEST, "参数错误"));

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(ResultCode.BAD_REQUEST.getCode(), response.getBody().getCode());
    }

    @Test
    void handleBusiness_conflict_returns409() {
        ResponseEntity<Result<Void>> response = handler.handleBusiness(
                new BusinessException(ResultCode.CONFLICT, "版本冲突"));

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertEquals(ResultCode.CONFLICT.getCode(), response.getBody().getCode());
    }

    @Test
    void handleBusiness_internalError_returns500() {
        ResponseEntity<Result<Void>> response = handler.handleBusiness(
                new BusinessException(ResultCode.INTERNAL_ERROR));

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals(ResultCode.INTERNAL_ERROR.getCode(), response.getBody().getCode());
    }

    @Test
    void handleBusiness_notFound_returns404() {
        ResponseEntity<Result<Void>> response = handler.handleBusiness(
                new BusinessException(ResultCode.NOT_FOUND, "资源不存在"));

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertEquals(ResultCode.NOT_FOUND.getCode(), response.getBody().getCode());
    }

    @Test
    void handleDuplicateKey_returns409() {
        ResponseEntity<Result<Void>> response = handler.handleDuplicateKey(
                new DuplicateKeyException("duplicate"));

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertEquals(ResultCode.CONFLICT.getCode(), response.getBody().getCode());
    }

    @Test
    void handleException_returns500() {
        ResponseEntity<Result<Void>> response = handler.handleException(new RuntimeException("boom"));

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertEquals(ResultCode.INTERNAL_ERROR.getCode(), response.getBody().getCode());
    }

    @Test
    void handleMethodArgumentNotValid_returns400WithFieldErrors() {
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "target");
        bindingResult.addError(new FieldError("target", "username", "用户名不能为空"));
        MethodArgumentNotValidException ex = new MethodArgumentNotValidException(null, bindingResult);

        ResponseEntity<Result<Map<String, String>>> response = handler.handleMethodArgumentNotValid(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody().getData().get("username"));
    }

    @Test
    void handleMethodArgumentNotValid_nullDefaultMessage_usesInvalidFallback() {
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "target");
        bindingResult.addError(new FieldError("target", "email", null));
        MethodArgumentNotValidException ex = new MethodArgumentNotValidException(null, bindingResult);

        ResponseEntity<Result<Map<String, String>>> response = handler.handleMethodArgumentNotValid(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("invalid", response.getBody().getData().get("email"));
    }

    @Test
    void handleBind_returns400WithFieldErrors() {
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "target");
        bindingResult.addError(new FieldError("target", "password", "密码不能为空"));
        BindException ex = new BindException(bindingResult);

        ResponseEntity<Result<Map<String, String>>> response = handler.handleBind(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("密码不能为空", response.getBody().getData().get("password"));
    }

    @Test
    void handleBind_nullDefaultMessage_usesInvalidFallback() {
        BeanPropertyBindingResult bindingResult = new BeanPropertyBindingResult(new Object(), "target");
        bindingResult.addError(new FieldError("target", "password", null));
        BindException ex = new BindException(bindingResult);

        ResponseEntity<Result<Map<String, String>>> response = handler.handleBind(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals("invalid", response.getBody().getData().get("password"));
    }

    @Test
    void handleConstraintViolation_returns400() {
        Validator validator = Validation.buildDefaultValidatorFactory().getValidator();
        Set<ConstraintViolation<SampleBean>> violations = validator.validate(new SampleBean());
        ConstraintViolationException ex = new ConstraintViolationException(violations);

        ResponseEntity<Result<Map<String, String>>> response = handler.handleConstraintViolation(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(ResultCode.BAD_REQUEST.getCode(), response.getBody().getCode());
    }

    private static class SampleBean {
        @NotBlank(message = "name required")
        private String name;
    }
}
