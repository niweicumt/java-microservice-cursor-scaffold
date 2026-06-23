package com.s3.skeleton.auto.service;

import com.baomidou.mybatisplus.core.metadata.TableInfoHelper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.s3.common.core.exception.BusinessException;
import com.s3.common.core.result.ResultCode;
import com.s3.skeleton.auto.dto.UserCreateRequest;
import com.s3.skeleton.auto.dto.UserPageQuery;
import com.s3.skeleton.auto.dto.UserUpdateRequest;
import com.s3.skeleton.auto.entity.User;
import com.s3.skeleton.auto.repository.UserMapper;
import org.apache.ibatis.builder.MapperBuilderAssistant;
import org.apache.ibatis.session.Configuration;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserAutoServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserAutoServiceImpl userAutoService;

    @BeforeAll
    static void initMybatisPlusTableInfo() {
        TableInfoHelper.initTableInfo(
                new MapperBuilderAssistant(new Configuration(), ""), User.class);
    }

    @Test
    void create_success() {
        UserCreateRequest req = new UserCreateRequest();
        req.setUsername("demo_user");
        req.setPassword("password1");
        req.setEmail("demo@example.com");

        when(userMapper.selectCount(any())).thenReturn(0L);
        when(passwordEncoder.encode("password1")).thenReturn("encoded");
        when(userMapper.insert(any(User.class))).thenAnswer(inv -> {
            User u = inv.getArgument(0);
            u.setId(1L);
            return 1;
        });

        Long id = userAutoService.create(req);

        assertEquals(1L, id);
        ArgumentCaptor<User> captor = ArgumentCaptor.forClass(User.class);
        verify(userMapper).insert(captor.capture());
        assertEquals("encoded", captor.getValue().getPasswordHash());
        assertEquals(1, captor.getValue().getStatus());
    }

    @Test
    void create_duplicateUsername_throwsConflict() {
        UserCreateRequest req = new UserCreateRequest();
        req.setUsername("dup_user");
        req.setPassword("password1");
        req.setEmail("a@example.com");

        when(userMapper.selectCount(any())).thenReturn(1L);

        BusinessException ex = assertThrows(BusinessException.class, () -> userAutoService.create(req));
        assertEquals(ResultCode.CONFLICT, ex.getResultCode());
        verify(userMapper, never()).insert(any(User.class));
    }

    @Test
    void getById_notFound() {
        when(userMapper.selectById(99L)).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class, () -> userAutoService.getById(99L));
        assertEquals(ResultCode.NOT_FOUND, ex.getResultCode());
    }

    @Test
    void getById_nullId_notFound() {
        BusinessException ex = assertThrows(BusinessException.class, () -> userAutoService.getById(null));
        assertEquals(ResultCode.NOT_FOUND, ex.getResultCode());
    }

    @Test
    void page_returnsEmpty() {
        UserPageQuery query = new UserPageQuery();
        query.setPage(1);
        query.setSize(10);

        Page<User> empty = new Page<>(1, 10);
        empty.setRecords(Collections.emptyList());
        empty.setTotal(0);
        when(userMapper.selectPage(any(), any())).thenReturn(empty);

        assertEquals(0, userAutoService.page(query).getTotal());
    }

    @Test
    void delete_notFound() {
        when(userMapper.selectById(1L)).thenReturn(null);

        assertThrows(BusinessException.class, () -> userAutoService.delete(1L));
    }

    @Test
    void update_notFound() {
        when(userMapper.selectById(1L)).thenReturn(null);

        UserUpdateRequest req = new UserUpdateRequest();
        req.setEmail("new@example.com");

        assertThrows(BusinessException.class, () -> userAutoService.update(1L, req));
    }
}
