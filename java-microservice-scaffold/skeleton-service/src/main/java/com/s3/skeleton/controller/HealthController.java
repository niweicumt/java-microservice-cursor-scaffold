package com.s3.skeleton.controller;

import com.s3.common.core.result.Result;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

@Tag(name = "health", description = "健康检查")
@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    @Value("${spring.application.name}")
    private String applicationName;

    @Operation(summary = "服务健康检查")
    @GetMapping
    public Result<Map<String, Object>> health() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("status", "UP");
        data.put("application", applicationName);
        return Result.success(data);
    }
}
