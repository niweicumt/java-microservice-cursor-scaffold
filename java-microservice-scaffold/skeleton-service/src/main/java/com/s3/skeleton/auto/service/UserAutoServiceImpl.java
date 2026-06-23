package com.s3.skeleton.auto.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.s3.common.core.exception.BusinessException;
import com.s3.common.core.result.ResultCode;
import com.s3.skeleton.auto.dto.PageVO;
import com.s3.skeleton.auto.dto.UserCreateRequest;
import com.s3.skeleton.auto.dto.UserPageQuery;
import com.s3.skeleton.auto.dto.UserUpdateRequest;
import com.s3.skeleton.auto.dto.UserVO;
import com.s3.skeleton.auto.entity.User;
import com.s3.skeleton.auto.repository.UserMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserAutoServiceImpl implements UserAutoService {

    private static final Logger log = LoggerFactory.getLogger(UserAutoServiceImpl.class);

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    @Override
    public Long create(UserCreateRequest request) {
        assertUsernameAvailable(request.getUsername(), null);
        assertEmailAvailable(request.getEmail(), null);

        User user = new User();
        user.setUsername(request.getUsername());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setEmail(request.getEmail());
        user.setPhone(blankToNull(request.getPhone()));
        user.setStatus(request.getStatus() != null ? request.getStatus() : 1);

        userMapper.insert(user);
        log.info("用户已创建, userId={}", user.getId());
        return user.getId();
    }

    @Override
    public UserVO getById(Long id) {
        User user = requireUser(id);
        return toVo(user);
    }

    @Override
    public PageVO<UserVO> page(UserPageQuery query) {
        int page = query.getPage() != null ? query.getPage() : 1;
        int size = query.getSize() != null ? query.getSize() : 10;

        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(query.getUsername())) {
            wrapper.like(User::getUsername, query.getUsername());
        }
        if (query.getStatus() != null) {
            wrapper.eq(User::getStatus, query.getStatus());
        }
        if (StringUtils.hasText(query.getEmail())) {
            wrapper.eq(User::getEmail, query.getEmail());
        }
        if (StringUtils.hasText(query.getPhone())) {
            wrapper.eq(User::getPhone, query.getPhone());
        }
        wrapper.orderByDesc(User::getCreateTime);

        Page<User> mpPage = userMapper.selectPage(new Page<>(page, size), wrapper);
        List<UserVO> records = mpPage.getRecords().stream()
                .map(this::toVo)
                .collect(Collectors.toList());
        return new PageVO<>(records, mpPage.getTotal(), mpPage.getCurrent(), mpPage.getSize());
    }

    @Override
    public UserVO update(Long id, UserUpdateRequest request) {
        User user = requireUser(id);

        if (StringUtils.hasText(request.getUsername())
                && !request.getUsername().equals(user.getUsername())) {
            assertUsernameAvailable(request.getUsername(), id);
            user.setUsername(request.getUsername());
        }
        if (StringUtils.hasText(request.getEmail()) && !request.getEmail().equals(user.getEmail())) {
            assertEmailAvailable(request.getEmail(), id);
            user.setEmail(request.getEmail());
        }
        if (StringUtils.hasText(request.getPassword())) {
            user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        }
        if (request.getPhone() != null) {
            user.setPhone(blankToNull(request.getPhone()));
        }
        if (request.getStatus() != null) {
            user.setStatus(request.getStatus());
        }

        userMapper.updateById(user);
        log.info("用户已更新, userId={}", id);
        return toVo(requireUser(id));
    }

    @Override
    public void delete(Long id) {
        requireUser(id);
        userMapper.deleteById(id);
        log.info("用户已逻辑删除, userId={}", id);
    }

    private User requireUser(Long id) {
        if (id == null || id <= 0) {
            throw new BusinessException(ResultCode.NOT_FOUND, "用户不存在");
        }
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "用户不存在");
        }
        return user;
    }

    private void assertUsernameAvailable(String username, Long excludeId) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<User>()
                .eq(User::getUsername, username);
        if (excludeId != null) {
            wrapper.ne(User::getId, excludeId);
        }
        if (userMapper.selectCount(wrapper) > 0) {
            throw new BusinessException(ResultCode.CONFLICT, "用户名已存在");
        }
    }

    private void assertEmailAvailable(String email, Long excludeId) {
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<User>()
                .eq(User::getEmail, email);
        if (excludeId != null) {
            wrapper.ne(User::getId, excludeId);
        }
        if (userMapper.selectCount(wrapper) > 0) {
            throw new BusinessException(ResultCode.CONFLICT, "邮箱已存在");
        }
    }

    private UserVO toVo(User user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setUsername(user.getUsername());
        vo.setEmail(user.getEmail());
        vo.setPhone(user.getPhone());
        vo.setStatus(user.getStatus());
        vo.setCreateTime(user.getCreateTime());
        vo.setUpdateTime(user.getUpdateTime());
        return vo;
    }

    private static String blankToNull(String value) {
        return StringUtils.hasText(value) ? value : null;
    }
}
