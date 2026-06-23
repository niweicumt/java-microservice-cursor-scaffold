package com.s3.skeleton.kafka;

import com.s3.common.cloud.kafka.KafkaTopicProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "app.kafka", name = "enabled", havingValue = "true")
public class SkeletonEventPublisher {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final KafkaTopicProperties topicProperties;

    public void publish(String payload) {
        kafkaTemplate.send(topicProperties.getSkeletonEventsTopic(), payload);
    }
}
