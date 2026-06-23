package com.s3.skeleton.support;

import com.atlassian.oai.validator.OpenApiInteractionValidator;
import com.atlassian.oai.validator.report.LevelResolver;
import com.atlassian.oai.validator.report.ValidationReport;
import io.swagger.v3.parser.core.models.ParseOptions;

/**
 * 构建 MockMvc OpenAPI 校验器（classpath 契约 + allOf/combinator 解析）。
 */
public final class OpenApiContractValidator {

    private static final OpenApiInteractionValidator VALIDATOR = createValidator();

    private OpenApiContractValidator() {
    }

    public static OpenApiInteractionValidator get() {
        return VALIDATOR;
    }

    private static OpenApiInteractionValidator createValidator() {
        ParseOptions parseOptions = new ParseOptions();
        parseOptions.setResolve(true);
        parseOptions.setResolveFully(false);
        parseOptions.setResolveCombinators(true);

        LevelResolver levelResolver = LevelResolver.create()
                .withLevel("validation.schema.additionalProperties", ValidationReport.Level.IGNORE)
                .build();

        return OpenApiInteractionValidator
                .createForSpecificationUrl(OpenApiContractSupport.CONTRACT_YAML)
                .withParseOptions(parseOptions)
                .withLevelResolver(levelResolver)
                .build();
    }
}
