package com.s3.common.cloud.kafka;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "app.kafka")
public class KafkaTopicProperties {

    private boolean enabled = true;

    private String skeletonEventsTopic = "skeleton.events";

    private int partitions = 3;

    private short replicas = 1;
}
