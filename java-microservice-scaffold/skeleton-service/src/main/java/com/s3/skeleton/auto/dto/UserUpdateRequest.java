package com.s3.skeleton.auto.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UserUpdateRequest {

    @Size(min = 4, max = 64, message = "用户名长度须为 4～64")
    @Pattern(regexp = "^[A-Za-z0-9_]+$", message = "用户名仅允许字母、数字、下划线")
    private String username;

    @Size(min = 8, max = 32, message = "密码长度须为 8～32")
    private String password;

    @Email(message = "邮箱格式不正确")
    @Size(max = 128, message = "邮箱长度不能超过 128")
    private String email;

    @Pattern(regexp = "^$|^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;

    @Min(value = 0, message = "状态仅允许 0 或 1")
    @Max(value = 1, message = "状态仅允许 0 或 1")
    private Integer status;
}
