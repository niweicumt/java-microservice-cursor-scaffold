/**
 * Monorepo 微服务 Jenkins 流水线
 *
 * 质量门禁（CI-TOOLCHAIN.md §5）：
 *   [1] SonarQube  → [2] JUnit5 + JaCoCo → [3] Controller 集成
 *   → [4] OpenAPI 契约 → [5] release/* 分支 Testcontainers MySQL
 *   任一失败阻断后续阶段（含镜像推送 / K8s 发布）。
 *
 * 构建顺序：common → 质量门禁 → package → Docker 镜像 → K8s 滚动发布
 *
 * Jenkins 全局工具（Manage Jenkins → Tools）：
 *   - JDK  名称：JDK17
 *
 * Jenkins 凭据（Manage Jenkins → Credentials）：
 *   - docker-registry   ：镜像仓库用户名/密码（Username with password）
 *   - kubeconfig        ：K8s kubeconfig 文件（Secret file）
 *   - maven-settings    ：可选，私服 settings.xml（Secret file）
 *   - sonar-token       ：SonarQube User Token（Secret text）
 *
 * 详见：shared/docs/CI-TOOLCHAIN.md · docs/DEPLOYMENT.md §13
 */
pipeline {
    agent any

    parameters {
        choice(
            name: 'BUILD_TARGET',
            choices: ['all', 'common-only', 'gateway', 'skeleton-service'],
            description: '构建目标（common-only 仅发布公共库到私服）'
        )
        choice(
            name: 'DEPLOY_ENV',
            choices: ['none', 'dev', 'test', 'uat', 'prod'],
            description: '部署环境；none 表示仅构建不发布'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: '',
            description: '镜像标签，留空则使用 BUILD_NUMBER-SNAPSHOT'
        )
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: '跳过全部测试与质量门禁')
        booleanParam(name: 'SKIP_QUALITY_GATES', defaultValue: false, description: '跳过 CI 门禁阶段 1～5（不推荐）')
        booleanParam(name: 'SKIP_SONAR', defaultValue: false, description: '跳过 SonarQube 扫描（不推荐）')
        booleanParam(name: 'PUSH_IMAGE', defaultValue: true, description: '构建并推送 Docker 镜像')
        booleanParam(name: 'DEPLOY_K8S', defaultValue: false, description: '推送后滚动更新 K8s Deployment')
    }

    environment {
        JAVA_HOME = "${tool 'JDK17'}"
        PATH = "${env.JAVA_HOME}/bin:${env.PATH}"

        DOCKER_REGISTRY = 'your-registry.example.com'
        K8S_NAMESPACE = 'microservice'
        IMAGE_TAG_RESOLVED = "${params.IMAGE_TAG ?: "${env.BUILD_NUMBER}-SNAPSHOT"}"

        COMMON_DIR = 'java-microservice-common'
        GATEWAY_DIR = 'java-microservice-gateway'
        SCAFFOLD_DIR = 'java-microservice-scaffold'
        SKELETON_MODULE = 'skeleton-service'

        MAVEN_LOCAL_REPO = "${env.WORKSPACE}/.m2/repository"
        SONAR_HOST_URL = "${env.SONAR_HOST_URL ?: 'http://localhost:9000'}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '30', artifactNumToKeepStr: '10'))
        timeout(time: 90, unit: 'MINUTES')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.RUN_RELEASE_MYSQL = isReleaseBranch() ? 'true' : 'false'
                }
                sh 'java -version && mvn -version'
                echo "Branch=${env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'unknown'}, release-gate=${env.RUN_RELEASE_MYSQL}"
            }
        }

        stage('Build Common') {
            when {
                expression {
                    params.BUILD_TARGET in ['all', 'common-only', 'gateway', 'skeleton-service']
                }
            }
            steps {
                script {
                    def mvnArgs = mavenArgs()
                    dir(COMMON_DIR) {
                        if (params.BUILD_TARGET == 'common-only') {
                            sh "mvn clean deploy ${mvnArgs}"
                        } else {
                            sh "mvn clean install ${mvnArgs} -DskipTests"
                        }
                    }
                }
            }
        }

        stage('Quality Gates') {
            when {
                allOf {
                    expression { params.BUILD_TARGET != 'common-only' }
                    expression { !params.SKIP_TESTS && !params.SKIP_QUALITY_GATES }
                }
            }
            parallel {
                stage('Gateway Quality Gates') {
                    when {
                        expression { params.BUILD_TARGET in ['all', 'gateway'] }
                    }
                    stages {
                        stage('[2] Gateway Unit Tests') {
                            steps {
                                script {
                                    dir(GATEWAY_DIR) {
                                        sh "mvn clean test ${mavenArgs(relative: true)} -DtrimStackTrace=false"
                                    }
                                }
                            }
                            post {
                                always {
                                    junit allowEmptyResults: true,
                                        testResults: 'java-microservice-gateway/target/surefire-reports/*.xml'
                                }
                            }
                        }
                        stage('[1] Gateway SonarQube') {
                            when {
                                expression { !params.SKIP_SONAR }
                            }
                            steps {
                                script {
                                    runSonarScan(GATEWAY_DIR, mavenArgs(relative: true))
                                }
                            }
                        }
                    }
                }

                stage('Skeleton Quality Gates') {
                    when {
                        expression { params.BUILD_TARGET in ['all', 'skeleton-service'] }
                    }
                    stages {
                        stage('[2] Skeleton Unit Tests + JaCoCo') {
                            steps {
                                script {
                                    dir(SCAFFOLD_DIR) {
                                        sh """
                                            mvn clean test ${mavenArgs(relative: true)} \
                                              -Pci-unit-tests \
                                              -pl ${SKELETON_MODULE} -am
                                            mvn jacoco:check ${mavenArgs(relative: true)} \
                                              -pl ${SKELETON_MODULE}
                                        """
                                    }
                                }
                            }
                            post {
                                always {
                                    archiveJacoco(SCAFFOLD_DIR, SKELETON_MODULE)
                                    junit allowEmptyResults: true,
                                        testResults: "java-microservice-scaffold/${SKELETON_MODULE}/target/surefire-reports/*.xml"
                                }
                            }
                        }
                        stage('[1] Skeleton SonarQube') {
                            when {
                                expression { !params.SKIP_SONAR }
                            }
                            steps {
                                script {
                                    // 依赖上一阶段 JaCoCo 报告
                                    runSonarScan(SCAFFOLD_DIR, "${mavenArgs(relative: true)} -pl ${SKELETON_MODULE} -am")
                                }
                            }
                        }
                        stage('[3] Skeleton Integration Tests') {
                            steps {
                                script {
                                    dir(SCAFFOLD_DIR) {
                                        sh """
                                            mvn test ${mavenArgs(relative: true)} \
                                              -Pci-integration-tests \
                                              -pl ${SKELETON_MODULE} -am
                                        """
                                    }
                                }
                            }
                            post {
                                always {
                                    junit allowEmptyResults: true,
                                        testResults: "java-microservice-scaffold/${SKELETON_MODULE}/target/surefire-reports/*.xml"
                                }
                            }
                        }
                        stage('[4] Skeleton Contract Tests') {
                            steps {
                                script {
                                    dir(SCAFFOLD_DIR) {
                                        sh """
                                            mvn test ${mavenArgs(relative: true)} \
                                              -Pcontract-tests \
                                              -pl ${SKELETON_MODULE} -am
                                        """
                                    }
                                }
                            }
                            post {
                                always {
                                    junit allowEmptyResults: true,
                                        testResults: "java-microservice-scaffold/${SKELETON_MODULE}/target/surefire-reports/*.xml"
                                }
                            }
                        }
                        stage('[5] Skeleton Release MySQL (Testcontainers)') {
                            when {
                                expression { env.RUN_RELEASE_MYSQL == 'true' }
                            }
                            steps {
                                script {
                                    dir(SCAFFOLD_DIR) {
                                        sh """
                                            mvn test ${mavenArgs(relative: true)} \
                                              -Prelease-integration \
                                              -pl ${SKELETON_MODULE} -am
                                        """
                                    }
                                }
                            }
                            post {
                                always {
                                    junit allowEmptyResults: true,
                                        testResults: "java-microservice-scaffold/${SKELETON_MODULE}/target/surefire-reports/*.xml"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Package Applications') {
            when {
                expression { params.BUILD_TARGET != 'common-only' }
            }
            parallel {
                stage('Package Gateway') {
                    when {
                        expression { params.BUILD_TARGET in ['all', 'gateway'] }
                    }
                    steps {
                        script {
                            dir(GATEWAY_DIR) {
                                sh "mvn package ${mavenArgs(relative: true)} -DskipTests"
                            }
                        }
                    }
                }
                stage('Package Skeleton') {
                    when {
                        expression { params.BUILD_TARGET in ['all', 'skeleton-service'] }
                    }
                    steps {
                        script {
                            dir(SCAFFOLD_DIR) {
                                sh """
                                    mvn package ${mavenArgs(relative: true)} -DskipTests \
                                      -pl ${SKELETON_MODULE} -am
                                """
                            }
                        }
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            when {
                allOf {
                    expression { params.PUSH_IMAGE }
                    expression { params.BUILD_TARGET != 'common-only' }
                }
            }
            parallel {
                stage('Image: Gateway') {
                    when {
                        expression { params.BUILD_TARGET in ['all', 'gateway'] }
                    }
                    steps {
                        script {
                            def image = "${DOCKER_REGISTRY}/gateway-service:${IMAGE_TAG_RESOLVED}"
                            dir(GATEWAY_DIR) {
                                sh "docker build -t ${image} ."
                                docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry') {
                                    sh "docker push ${image}"
                                }
                            }
                            env.GATEWAY_IMAGE = image
                        }
                    }
                }
                stage('Image: Skeleton') {
                    when {
                        expression { params.BUILD_TARGET in ['all', 'skeleton-service'] }
                    }
                    steps {
                        script {
                            def image = "${DOCKER_REGISTRY}/skeleton-service:${IMAGE_TAG_RESOLVED}"
                            dir("${SCAFFOLD_DIR}/${SKELETON_MODULE}") {
                                sh "docker build -t ${image} ."
                                docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry') {
                                    sh "docker push ${image}"
                                }
                            }
                            env.SKELETON_IMAGE = image
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                allOf {
                    expression { params.DEPLOY_K8S && params.DEPLOY_ENV != 'none' }
                    expression { params.BUILD_TARGET != 'common-only' }
                }
            }
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        if (params.BUILD_TARGET in ['all', 'skeleton-service'] && env.SKELETON_IMAGE) {
                            sh """
                                kubectl rollout status deployment/${SKELETON_MODULE} \
                                  -n ${K8S_NAMESPACE} --timeout=300s || true
                                kubectl set image deployment/${SKELETON_MODULE} \
                                  ${SKELETON_MODULE}=${SKELETON_IMAGE} \
                                  -n ${K8S_NAMESPACE}
                                kubectl rollout status deployment/${SKELETON_MODULE} \
                                  -n ${K8S_NAMESPACE} --timeout=300s
                            """
                        }
                        if (params.BUILD_TARGET in ['all', 'gateway'] && env.GATEWAY_IMAGE) {
                            sh """
                                kubectl set image deployment/gateway-service \
                                  gateway-service=${GATEWAY_IMAGE} \
                                  -n ${K8S_NAMESPACE}
                                kubectl rollout status deployment/gateway-service \
                                  -n ${K8S_NAMESPACE} --timeout=300s
                            """
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded. IMAGE_TAG=${IMAGE_TAG_RESOLVED}, DEPLOY_ENV=${params.DEPLOY_ENV}"
        }
        failure {
            echo 'Pipeline failed. 查看 Quality Gates 各 stage 日志、surefire-reports 与 JaCoCo 附件。'
        }
        always {
            cleanWs(
                deleteDirs: true,
                patterns: [[pattern: '**/target', type: 'INCLUDE']]
            )
        }
    }
}

/** Maven 公共参数（仓库根 .mvn/settings.xml） */
String mavenArgs(Map opts = [:]) {
    def prefix = opts.relative ? '../' : ''
    return "-B -Dmaven.repo.local=${MAVEN_LOCAL_REPO} -s ${prefix}.mvn/settings.xml"
}

/** release/* 分支或 Tag 构建时启用阶段 5 */
boolean isReleaseBranch() {
    def branch = env.BRANCH_NAME ?: env.GIT_BRANCH ?: ''
    branch = branch.replaceFirst(/^origin\//, '')
    if (branch.startsWith('release/')) {
        return true
    }
    if (env.TAG_NAME?.trim()) {
        return true
    }
    return false
}

/** SonarQube 扫描（Quality Gate 等待） */
void runSonarScan(String projectDir, String extraArgs) {
    dir(projectDir) {
        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
            sh """
                mvn sonar:sonar ${extraArgs} \
                  -Dsonar.host.url=${SONAR_HOST_URL} \
                  -Dsonar.token=\${SONAR_TOKEN} \
                  -Dsonar.qualitygate.wait=true
            """
        }
    }
}

/** 归档 JaCoCo 报告供平台留存 */
void archiveJacoco(String scaffoldDir, String module) {
    archiveArtifacts(
        artifacts: "${scaffoldDir}/${module}/target/site/jacoco/jacoco.xml,${scaffoldDir}/${module}/target/site/jacoco/index.html",
        allowEmptyArchive: true,
        fingerprint: true
    )
}
