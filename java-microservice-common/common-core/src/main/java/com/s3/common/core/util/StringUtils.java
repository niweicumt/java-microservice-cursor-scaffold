package com.s3.common.core.util;

/**
 * 字符串工具（示例占位，可按团队规范扩展或替换为 Apache Commons）。
 */
public final class StringUtils {

    private StringUtils() {
    }

    public static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
