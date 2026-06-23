package com.s3.skeleton.auto.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户响应 VO（不含密码）。
 */
@Data
public class UserVO {

    private Long id;
    private String username;
    private String email;
    private String phone;
    private Integer status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
