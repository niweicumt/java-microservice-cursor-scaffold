package com.s3.skeleton.auto.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class UserPageQuery {

    @Min(value = 1, message = "页码须 ≥ 1")
    private Integer page = 1;

    @Min(value = 1, message = "每页条数须 ≥ 1")
    @Max(value = 100, message = "每页条数须 ≤ 100")
    private Integer size = 10;

    private String username;

    @Min(value = 0, message = "状态仅允许 0 或 1")
    @Max(value = 1, message = "状态仅允许 0 或 1")
    private Integer status;

    private String email;

    private String phone;
}
