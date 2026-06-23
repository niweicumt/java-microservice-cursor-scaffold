package com.s3.skeleton.auto.service;

import com.s3.skeleton.auto.dto.PageVO;
import com.s3.skeleton.auto.dto.UserCreateRequest;
import com.s3.skeleton.auto.dto.UserPageQuery;
import com.s3.skeleton.auto.dto.UserUpdateRequest;
import com.s3.skeleton.auto.dto.UserVO;

/**
 * 用户基础 CRUD（auto 包，单表读写）。
 */
public interface UserAutoService {

    /**
     * 创建用户。
     *
     * @param request 创建参数（含明文密码，内部 BCrypt 编码）
     * @return 新用户 ID
     * @throws com.s3.common.core.exception.BusinessException 用户名或邮箱冲突时 {@code CONFLICT}
     */
    Long create(UserCreateRequest request);

    /**
     * 按 ID 查询用户。
     *
     * @param id 用户 ID
     * @return 用户 VO
     * @throws com.s3.common.core.exception.BusinessException 不存在时 {@code NOT_FOUND}
     */
    UserVO getById(Long id);

    /**
     * 分页条件查询。
     *
     * @param query 分页与筛选条件
     * @return 分页结果
     */
    PageVO<UserVO> page(UserPageQuery query);

    /**
     * 更新用户（部分字段）。
     *
     * @param id      用户 ID
     * @param request 更新字段
     * @return 更新后 VO
     * @throws com.s3.common.core.exception.BusinessException 不存在 {@code NOT_FOUND}；冲突 {@code CONFLICT}
     */
    UserVO update(Long id, UserUpdateRequest request);

    /**
     * 逻辑删除用户。
     *
     * @param id 用户 ID
     * @throws com.s3.common.core.exception.BusinessException 不存在 {@code NOT_FOUND}
     */
    void delete(Long id);
}
