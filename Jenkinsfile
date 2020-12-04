#!/usr/bin/env groovy

def labels = ""
def imageName = ""
def artifactoryURL = "https://index.docker.io/v1/"
def automation = credentials('automationuser')

node("docker"){

  stage("Initialize"){
    currentBuild.displayName = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
      if (env.CHANGE_ID) {
        //Just a comment
        pullRequest.comment("Starting pipeline for PR validation -> ${env.BRANCH_NAME}-${env.BUILD_NUMBER}")
        pullRequest.labels.each{
        echo "label: $it"
        validateProviderLabel(it)
        labels += "$it,"
      }
        labels = labels.substring(0,labels.length()-1)
        echo "PR labels -> $labels"
     }else {
       currentBuild.result = 'ABORTED'
       throw new Exception("Aborting as this is not a PR job")
     }
 }
  
  stage ("Checkout and Build Images") {
      def scmVars = checkout scm
      branchName = "${scmVars.GIT_BRANCH}"
    imageName = "${automation}/web-ready:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
      withCredentials([usernamePassword(credentialsId: "automation_repo",
      passwordVariable: 'ARTIFACTORY_PASSWORD', usernameVariable: 'ARTIFACTORY_USER')]) {
        sh "docker login -u ${ARTIFACTORY_USER} -p ${ARTIFACTORY_PASSWORD} ${artifactoryURL}"
        sh "docker build --no-cache -t ${imageName} ."
        sh "docker push ${imageName}"
      }
  }

  stage("Setup Cluster and Execute Tests") {
    jobMap = [:]
    jobMap["job"] = "../kubernetes-test-orchestrator/master"
    jobMap["parameters"] = [
                            string(name: 'PROVIDERS', value: labels),
                            string(name: 'WEB_READY_IMAGE_NAME', value: imageName),
                            string(name: 'DOCKER_IMAGE_RESISTRY_URL', value: "${artifactoryURL}")
                        ]
    jobMap["propagate"] = true
    jobMap["quietPeriod"] = 0 
    resultWrapper = build jobMap
    currentBuild.result = resultWrapper.result
 } 
}

def validateProviderLabel(String provider){
    def validProviders = ["integ-all","integ-eks","integ-gke","integ-aks"]
    def failureMessage = "Invalid provider label - ${provider}. valid labels are ${validProviders}"
    if(!validProviders.contains(provider)){
        currentBuild.result = 'FAILURE'
        pullRequest.comment("${failureMessage}")
        throw new Exception("${failureMessage}")
    }
}
