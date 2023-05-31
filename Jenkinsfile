#!/usr/bin/env groovy

appName = 'local-office-search-api'

dockerRegistryDomain = '979633842206.dkr.ecr.eu-west-1.amazonaws.com'
dockerRegistryUrl = "https://${dockerRegistryDomain}"
ecrCredentialId = 'ecr:eu-west-1:cita-devops'
BUILD_STAGE = 'Build'

deployBranches = ['develop','qa']
isRelease = deployBranches.contains(env.BRANCH_NAME)
def tagPrefix = isRelease ? '' : 'dev_'
dockerTag = "${tagPrefix}${env.BUILD_TAG}"

node('docker && awsaccess') {
  cleanWs()
  checkout scm
  dockerTag += "_${getSha()}"
  currentBuild.displayName = "${env.BUILD_NUMBER}: ${dockerTag}"

  withDockerRegistry(registry: [credentialsId: 'docker_hub']) {
    withEnv([
      "SEARCH_API_VERSION_TAG=:${dockerTag}",
      "SEARCH_API_PR_TAG=:${env.BRANCH_NAME}"
    ]) {
      dockerBuild(context: pwd(), tag: dockerImageId())
    }
  }
}

@NonCPS
def dockerImageId() {
  "local-office-search-api:${dockerTag}"
}

def dockerBuild(Map config) {
  try {
    def image = null
    stage("Build ${config.tag}") {
      BUILD_STAGE = "Build ${config.tag}"
      dir(config.context) {
        writeBuildStatus {
          file = 'public/.buildInfo'
        }
        image = docker.build(config.tag)
      }
    }
    stage("Lint ${config.tag}") {
      BUILD_STAGE = "Lint ${config.tag}"
      def lintScript = 'bin/jenkins/lint'

      if (fileExists("${config.context}/${lintScript}")) {
        sh "${lintScript}"
      } else {
        echo 'Nothing to lint'
      }
    }
    stage("Test ${config.tag}") {
      BUILD_STAGE = "Test ${config.tag}"

      // make sure rails boots ok
      sh "docker run --rm  ${config.tag} timeout --preserve-status -s 1 15 rails s"

      def testScript = 'bin/jenkins/test'

      if (fileExists("${config.context}/${testScript}")) {
        sh "${testScript}"
        publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: './coverage',
                reportFiles: 'index.html',
                reportName: 'Test Report'
              ])
      } else {
        echo 'No tests'
      }
    }
    stage("Push ${config.tag}") {
      BUILD_STAGE = "Push ${config.tag}"
      docker.withRegistry(dockerRegistryUrl, ecrCredentialId) {
        image.push()
        if (!deployBranches.contains(env.BRANCH_NAME)) {
          // add PR number as tag
          image.push(env.BRANCH_NAME)
        }
        else {
          deployBranches.each { branch ->
            if (env.BRANCH_NAME == branch) {
              // push latest tag
              image.push(branch)
              // deploy latest tag on environment
              build(job:"../public-website-config/${branch}", wait: false)
            }
            if (env.BRANCH_NAME == 'develop') {
              // We tag as latest here, because any tests failures will prevent pushing the image anyway.
              image.push('latest')
            }
          }
        }
      }
    }
  } catch (all) {
    // Set result manually as Jenkins does not update this (or currentResult) until after
    // the finally block is executed.
    currentBuild.result = 'FAILURE'
    throw all
  } finally {
    sh 'bin/jenkins/down || true'

    if (deployBranches.contains(env.BRANCH_NAME)) {
      withCredentials([string(credentialsId: 'slack-plugin', variable: 'SLACK_TOKEN')]) {
        def message = "${env.BUILD_TAG}\n"
        message += "STAGE: ${BUILD_STAGE}\n"
        message += "${sh(returnStdout: true, script: "git log -1 --pretty=format':%h %s (%an, %ar)'")}\n"
        message += currentBuild.result == 'FAILURE' ?
                      "FAILURE ${buildLink()}console" :
                      'GREAT SUCCESS'

        slackSend(
          token: SLACK_TOKEN,
          channel: '#content-platform_builds',
          color: currentBuild.result == 'FAILURE' ? 'danger' : 'good',
          message: message
        )
      }
    }
  }
}
