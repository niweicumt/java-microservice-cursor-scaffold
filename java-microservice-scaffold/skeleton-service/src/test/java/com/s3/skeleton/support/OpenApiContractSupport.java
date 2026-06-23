package com.s3.skeleton.support;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.PathItem;
import io.swagger.v3.parser.OpenAPIV3Parser;
import io.swagger.v3.parser.core.models.ParseOptions;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.fail;

/**
 * OpenAPI 契约校验工具：基线 operations 须仍存在于运行时 /v3/api-docs。
 */
public final class OpenApiContractSupport {

    /** classpath 契约文件（CI 阶段 4、集成测试响应校验共用） */
    public static final String CONTRACT_YAML = "contracts/skeleton-api.openapi.yaml";

    private OpenApiContractSupport() {
    }

    /**
     * 断言运行时 OpenAPI 文档与基线契约 backward compatible（允许新增 path/operation，禁止删除）。
     *
     * @param liveApiDocsJson springdoc {@code /v3/api-docs} 响应 JSON
     */
    public static void assertBackwardCompatible(String liveApiDocsJson) {
        OpenAPI baseline = loadBaselineContract();
        JsonNode livePaths;
        try {
            livePaths = new ObjectMapper().readTree(liveApiDocsJson).path("paths");
        } catch (Exception e) {
            throw new IllegalStateException("无法解析运行时 OpenAPI JSON", e);
        }

        List<String> missing = new ArrayList<>();
        baseline.getPaths().forEach((path, pathItem) -> {
            if (!livePaths.has(path)) {
                missing.add("path " + path);
                return;
            }
            for (Map.Entry<PathItem.HttpMethod, io.swagger.v3.oas.models.Operation> entry
                    : pathItem.readOperationsMap().entrySet()) {
                String method = entry.getKey().name().toLowerCase();
                if (!livePaths.path(path).has(method)) {
                    missing.add(method.toUpperCase() + " " + path);
                }
            }
        });

        if (!missing.isEmpty()) {
            fail("OpenAPI 契约回归：以下基线 operation 缺失于运行时文档 — "
                    + String.join(", ", missing)
                    + "。若为破坏性变更，请 bump API 版本并更新 "
                    + CONTRACT_YAML);
        }
    }

    public static OpenAPI loadBaselineContract() {
        ParseOptions options = new ParseOptions();
        options.setResolve(true);
        try (InputStream in = OpenApiContractSupport.class.getClassLoader().getResourceAsStream(CONTRACT_YAML)) {
            if (in == null) {
                throw new IllegalStateException("未找到契约文件: " + CONTRACT_YAML);
            }
            String yaml = new String(in.readAllBytes(), StandardCharsets.UTF_8);
            OpenAPI openAPI = new OpenAPIV3Parser().readContents(yaml, null, options).getOpenAPI();
            if (openAPI == null || openAPI.getPaths() == null) {
                throw new IllegalStateException("契约文件解析失败: " + CONTRACT_YAML);
            }
            return openAPI;
        } catch (Exception e) {
            throw new IllegalStateException("加载契约失败: " + CONTRACT_YAML, e);
        }
    }

    /**
     * 断言基线包含指定 path（供 smoke 测试）。
     */
    public static void assertBaselineContainsPaths(String... paths) {
        OpenAPI baseline = loadBaselineContract();
        Set<String> baselinePaths = baseline.getPaths().keySet();
        for (String path : paths) {
            assertTrue(baselinePaths.contains(path), "契约缺少 path: " + path);
        }
    }
}
