package com.s3.skeleton.auto.controller;

import com.s3.common.core.result.Result;
import com.s3.skeleton.auto.dto.PageVO;
import com.s3.skeleton.auto.dto.UserCreateRequest;
import com.s3.skeleton.auto.dto.UserPageQuery;
import com.s3.skeleton.auto.dto.UserUpdateRequest;
import com.s3.skeleton.auto.dto.UserVO;
import com.s3.skeleton.auto.service.UserAutoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "users", description = "用户管理")
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Validated
public class UserController {

    private final UserAutoService userAutoService;

    @Operation(summary = "创建用户")
    @PostMapping
    public Result<Long> create(@Valid @RequestBody UserCreateRequest request) {
        return Result.success(userAutoService.create(request));
    }

    @Operation(summary = "分页条件查询用户")
    @GetMapping
    public Result<PageVO<UserVO>> page(@Valid UserPageQuery query) {
        return Result.success(userAutoService.page(query));
    }

    @Operation(summary = "按 ID 查询用户")
    @GetMapping("/{id}")
    public Result<UserVO> getById(@PathVariable Long id) {
        return Result.success(userAutoService.getById(id));
    }

    @Operation(summary = "更新用户")
    @PutMapping("/{id}")
    public Result<UserVO> update(@PathVariable Long id,
                               @Valid @RequestBody UserUpdateRequest request) {
        return Result.success(userAutoService.update(id, request));
    }

    @Operation(summary = "逻辑删除用户")
    @DeleteMapping("/{id}")
    public Result<Void> delete(@PathVariable Long id) {
        userAutoService.delete(id);
        return Result.success();
    }
}
