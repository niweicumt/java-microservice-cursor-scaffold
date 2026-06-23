package com.s3.skeleton.kafka;

import com.s3.common.cloud.kafka.KafkaTopicProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "app.kafka", name = "enabled", havingValue = "true")
public class SkeletonEventListener {

    private final KafkaTopicProperties topicProperties;

    @KafkaListener(topics = "${app.kafka.skeleton-events-topic:skeleton.events}")
    public void onMessage(String payload) {
        log.info("Received skeleton event from topic {}: {}", topicProperties.getSkeletonEventsTopic(), payload);
    }
}
