package com.s3.common.cloud.autoconfigure;

import com.s3.common.cloud.kafka.KafkaTopicProperties;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;
import org.springframework.cloud.openfeign.EnableFeignClients;

@AutoConfiguration
@EnableDiscoveryClient
@EnableFeignClients(basePackages = "com.s3")
@EnableConfigurationProperties(KafkaTopicProperties.class)
public class CommonCloudAutoConfiguration {
}
