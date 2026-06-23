package com.s3.common.core.result;

import lombok.Getter;

@Getter
public enum ResultCode {

    SUCCESS(200, "success"),
    BAD_REQUEST(400, "参数校验失败"),
    NOT_FOUND(404, "资源不存在"),
    CONFLICT(409, "数据冲突"),
    INTERNAL_ERROR(500, "系统内部错误");

    private final int code;
    private final String defaultMsg;

    ResultCode(int code, String defaultMsg) {
        this.code = code;
        this.defaultMsg = defaultMsg;
    }
}
