package com.s3.common.core.autoconfigure;

import com.s3.common.core.exception.GlobalExceptionHandler;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.context.annotation.Import;

@AutoConfiguration
@Import(GlobalExceptionHandler.class)
public class CommonCoreAutoConfiguration {
}
