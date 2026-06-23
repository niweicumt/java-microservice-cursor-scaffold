package com.s3.skeleton.auto.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 分页结果 VO。
 *
 * @param <T> 记录类型
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageVO<T> {

    private List<T> records;
    private long total;
    private long page;
    private long size;
}
