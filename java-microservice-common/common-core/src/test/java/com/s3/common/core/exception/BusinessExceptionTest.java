package com.s3.common.core.exception;

import com.s3.common.core.result.ResultCode;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BusinessExceptionTest {

    @Test
    void constructor_withResultCode_usesDefaultMessage() {
        BusinessException ex = new BusinessException(ResultCode.BAD_REQUEST);

        assertEquals(ResultCode.BAD_REQUEST, ex.getResultCode());
        assertEquals(ResultCode.BAD_REQUEST.getDefaultMsg(), ex.getMessage());
    }

    @Test
    void constructor_withResultCodeAndMessage_usesCustomMessage() {
        BusinessException ex = new BusinessException(ResultCode.NOT_FOUND, "用户不存在");

        assertEquals(ResultCode.NOT_FOUND, ex.getResultCode());
        assertEquals("用户不存在", ex.getMessage());
    }
}
