package com.s3.skeleton.auto.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.s3.skeleton.auto.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper extends BaseMapper<User> {
}
